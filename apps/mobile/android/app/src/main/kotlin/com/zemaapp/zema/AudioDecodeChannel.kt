package com.zemaapp.zema

import android.content.Context
import android.media.AudioFormat
import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.util.concurrent.Executors

/**
 * Decodes audio files for the Dart fingerprinter.
 *
 * Methods:
 * - `decode` {uri, maxSeconds} → {pcm, codec, millis}: 16-bit little-endian
 *   mono PCM at [RATE] Hz, at most the first `maxSeconds` (default 15
 *   minutes, so a long recording can't exhaust memory); the codec that
 *   decoded it and how long that took, for the details on the Listen screen
 * - `device` → {cores, powerSave}: CPU cores and whether battery saver is on
 *
 * Channels are averaged to mono, then each output sample averages the input
 * samples it covers (the same as zema_core's `resampleMono`). Errors:
 * `decode_failed`. Up to [WORKERS] files decode at once, each on its own
 * thread: a software audio codec uses one core, and phones have several.
 */
class AudioDecodeChannel(private val context: Context, messenger: BinaryMessenger) :
    MethodChannel.MethodCallHandler {

    private val channel = MethodChannel(messenger, NAME)
    private val executor = Executors.newFixedThreadPool(WORKERS)
    private val main = Handler(Looper.getMainLooper())

    init {
        channel.setMethodCallHandler(this)
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        executor.shutdown()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "decode" -> {
                val uri = call.argument<String>("uri")
                if (uri == null) {
                    result.error("bad_args", "decode needs a uri", null)
                    return
                }
                val maxSeconds = call.argument<Number>("maxSeconds")?.toInt() ?: 900
                executor.execute {
                    try {
                        val started = System.nanoTime()
                        val (pcm, codec) = decode(Uri.parse(uri), maxSeconds.toLong() * RATE)
                        val millis = (System.nanoTime() - started) / 1_000_000
                        main.post {
                            result.success(mapOf("pcm" to pcm, "codec" to codec, "millis" to millis))
                        }
                    } catch (e: Exception) {
                        Log.w(TAG, "Decode failed for $uri", e)
                        main.post { result.error("decode_failed", e.message, null) }
                    }
                }
            }
            "device" -> {
                val power = context.getSystemService(Context.POWER_SERVICE) as PowerManager
                result.success(
                    mapOf(
                        "cores" to Runtime.getRuntime().availableProcessors(),
                        "powerSave" to power.isPowerSaveMode,
                    ),
                )
            }
            else -> result.notImplemented()
        }
    }

    /**
     * Every codec and extractor is released on every path, failures included:
     * a leaked codec stays alive in the system's media service, and enough of
     * them slow every later decode and can bring the system down.
     */
    private fun decode(uri: Uri, maxSamples: Long): Pair<ByteArray, String> {
        val extractor = MediaExtractor()
        try {
            extractor.setDataSource(context, uri, null)
            val track = (0 until extractor.trackCount).firstOrNull {
                extractor.getTrackFormat(it).getString(MediaFormat.KEY_MIME)?.startsWith("audio/") == true
            } ?: throw IllegalArgumentException("No audio track")
            extractor.selectTrack(track)
            val format = extractor.getTrackFormat(track)
            val codec = MediaCodec.createDecoderByType(format.getString(MediaFormat.KEY_MIME)!!)
            try {
                codec.configure(format, null, null, 0)
                codec.start()
                return run(extractor, codec, format, maxSamples) to codec.name
            } finally {
                // stop() throws when the codec failed; release() must still run.
                runCatching { codec.stop() }
                codec.release()
            }
        } finally {
            extractor.release()
        }
    }

    private fun run(
        extractor: MediaExtractor,
        codec: MediaCodec,
        format: MediaFormat,
        maxSamples: Long,
    ): ByteArray {
        val out = Resampler(maxSamples)
        var channels = format.getInteger(MediaFormat.KEY_CHANNEL_COUNT)
        var rate = format.getInteger(MediaFormat.KEY_SAMPLE_RATE)
        var float = false
        val info = MediaCodec.BufferInfo()
        var inputDone = false
        var shorts = ShortArray(0)
        var floats = FloatArray(0)
        var lastProgress = System.nanoTime()
        decoding@ while (!out.full) {
            if (System.nanoTime() - lastProgress > STALL_NANOS) {
                throw IllegalStateException("Codec stopped responding")
            }
            // Feed every free input buffer without waiting, then take every
            // ready output. Waiting only when neither moved keeps a codec
            // that answers late (most hardware ones) from stalling each frame.
            var fed = false
            while (!inputDone) {
                val i = codec.dequeueInputBuffer(0)
                if (i < 0) break
                val size = extractor.readSampleData(codec.getInputBuffer(i)!!, 0)
                if (size < 0) {
                    codec.queueInputBuffer(i, 0, 0, 0, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
                    inputDone = true
                } else {
                    codec.queueInputBuffer(i, 0, size, extractor.sampleTime, 0)
                    extractor.advance()
                }
                fed = true
                lastProgress = System.nanoTime()
            }
            var drained = false
            while (true) {
                val o = codec.dequeueOutputBuffer(info, if (fed || drained) 0 else 5_000)
                if (o == MediaCodec.INFO_TRY_AGAIN_LATER) break
                if (o == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED) {
                    val f = codec.outputFormat
                    channels = f.getInteger(MediaFormat.KEY_CHANNEL_COUNT)
                    rate = f.getInteger(MediaFormat.KEY_SAMPLE_RATE)
                    float = f.containsKey(MediaFormat.KEY_PCM_ENCODING) &&
                        f.getInteger(MediaFormat.KEY_PCM_ENCODING) == AudioFormat.ENCODING_PCM_FLOAT
                    continue
                }
                if (o < 0) continue
                drained = true
                lastProgress = System.nanoTime()
                val buffer = codec.getOutputBuffer(o)!!.order(ByteOrder.LITTLE_ENDIAN)
                buffer.position(info.offset)
                buffer.limit(info.offset + info.size)
                if (float) {
                    val samples = buffer.asFloatBuffer()
                    val n = samples.remaining()
                    if (floats.size < n) floats = FloatArray(n)
                    samples.get(floats, 0, n)
                    out.addFloats(floats, n, channels, rate)
                } else {
                    val samples = buffer.asShortBuffer()
                    val n = samples.remaining()
                    if (shorts.size < n) shorts = ShortArray(n)
                    samples.get(shorts, 0, n)
                    out.addShorts(shorts, n, channels, rate)
                }
                codec.releaseOutputBuffer(o, false)
                if (info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) break@decoding
                if (out.full) break@decoding
            }
        }
        return out.bytes()
    }

    /**
     * Averages mono input into [RATE] Hz output, like `resampleMono`: input
     * sample k belongs to output i when floor(i * ratio) <= k < floor((i + 1) * ratio).
     */
    private class Resampler(private val maxSamples: Long) {
        private var output = ShortArray(RATE * 60)
        private var length = 0
        private var inputIndex = 0L
        private var boundary = -1L
        private var ratio = 0.0
        private var sum = 0.0
        private var count = 0

        val full: Boolean get() = length >= maxSamples

        fun addShorts(samples: ShortArray, n: Int, channels: Int, rate: Int) {
            var i = 0
            while (i + channels <= n) {
                var s = 0
                for (c in 0 until channels) s += samples[i + c]
                add(s / (32768.0 * channels), rate)
                i += channels
            }
        }

        fun addFloats(samples: FloatArray, n: Int, channels: Int, rate: Int) {
            var i = 0
            while (i + channels <= n) {
                var s = 0.0
                for (c in 0 until channels) s += samples[i + c]
                add(s / channels, rate)
                i += channels
            }
        }

        private fun add(sample: Double, rate: Int) {
            val r = rate.toDouble() / RATE
            if (r != ratio) {
                ratio = r
                boundary = Math.floor((length + 1) * ratio).toLong()
            }
            if (inputIndex >= boundary && count > 0) {
                emit()
                boundary = Math.floor((length + 1) * ratio).toLong()
            }
            sum += sample
            count++
            inputIndex++
        }

        private fun emit() {
            if (length == output.size) output = output.copyOf(output.size * 2)
            output[length++] = (sum / count * 32767).toInt().coerceIn(-32768, 32767).toShort()
            sum = 0.0
            count = 0
        }

        fun bytes(): ByteArray {
            if (count > 0) emit()
            val n = minOf(length.toLong(), maxSamples).toInt()
            val bytes = ByteBuffer.allocate(n * 2).order(ByteOrder.LITTLE_ENDIAN)
            bytes.asShortBuffer().put(output, 0, n)
            return bytes.array()
        }
    }

    companion object {
        private const val NAME = "zema/audio_decode"
        private const val TAG = "ZemaAudioDecode"
        private const val RATE = 11025

        /** Files decoded at the same time; Dart sends no more than this. */
        const val WORKERS = 3

        /** A codec that neither takes input nor gives output this long is abandoned. */
        private const val STALL_NANOS = 10_000_000_000L
    }
}
