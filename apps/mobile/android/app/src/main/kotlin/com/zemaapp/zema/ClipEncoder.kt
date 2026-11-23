package com.zemaapp.zema

import android.content.Context
import android.graphics.BitmapFactory
import android.media.AudioFormat
import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaCodecList
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMuxer
import android.net.Uri
import android.opengl.EGL14
import android.opengl.EGLConfig
import android.opengl.EGLContext
import android.opengl.EGLDisplay
import android.opengl.EGLExt
import android.opengl.EGLSurface
import android.opengl.GLES20
import android.opengl.GLUtils
import android.view.Surface
import java.io.File
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.FloatBuffer
import java.util.concurrent.CancellationException

/**
 * Makes a portrait MP4 (H.264 + AAC) from part of an audio file, a still
 * background and a few lyric layers (transparent pictures). Each layer shows
 * from its time until the next one's; on a change the old layer gives way to
 * the new one by [Request.motion], eased over [Request.transitionUs] centred
 * on that time.
 * Layers fade out towards the edges of [Request.windowTop]..[Request.windowBottom].
 *
 * The audio from [Request.startUs] to [Request.endUs] is decoded, faded in
 * and out, and encoded to AAC first, in memory; then the pictures are drawn
 * through GL onto the video encoder's surface at [Request.fps] with exact
 * presentation times, and both tracks are muxed. No [Request.audio] gives a
 * silent track. Picks 1080×1920, or 720×1280 where the phone can't encode
 * that. Every codec, extractor, muxer and GL object is released on every path.
 */
class ClipEncoder(
    private val context: Context,
    private val request: Request,
    private val cancelled: () -> Boolean,
    private val progress: (Double) -> Unit,
) {
    /** A lyric layer from [atUs]; [scroll] is how far, as a part of the height, its content sits above the previous layer's. */
    class Frame(val path: String, val atUs: Long, val scroll: Float = 0f)

    /** How a new layer replaces the old one. */
    enum class Motion {
        /** The old layer scrolls up by the new one's [Frame.scroll] while the new one slides in and fades over it. */
        SCROLL,

        /** A cross fade. */
        FADE,

        /** The old layer rises out as the new one rises in from a little below. */
        RISE,

        /** The old layer grows away as the new one grows in, around [Request.center]. */
        ZOOM,

        /** The old layer fades out, then the new one fades in. */
        OUT_IN,
    }

    class Request(
        val audio: Uri?,
        val startUs: Long,
        val endUs: Long,
        val background: String,
        val frames: List<Frame>,
        val out: File,
        val fps: Int,
        val transitionUs: Long,
        val windowTop: Float = 0f,
        val windowBottom: Float = 1f,
        val windowFade: Float = 0f,
        val motion: Motion = Motion.SCROLL,
        /** Where the sung line sits, as a part of the height: the centre of [Motion.ZOOM]. */
        val center: Float = 0.5f,
    ) {
        val durationUs: Long get() = endUs - startUs
    }

    class Result(val width: Int, val height: Int, val codec: String)

    private class Sample(val data: ByteArray, val ptsUs: Long, val flags: Int)

    private class Pcm(val samples: ShortArray, val rate: Int, val channels: Int)

    fun run(): Result {
        require(request.frames.isNotEmpty()) { "No frames" }
        require(request.durationUs > 0) { "Empty clip" }
        try {
            val pcm = request.audio?.let { decode(it) } ?: silence()
            fade(pcm)
            val (audioFormat, audio) = encodeAudio(pcm)
            progress(AUDIO_SHARE)
            return encodeVideo(audioFormat, audio)
        } catch (e: Throwable) {
            request.out.delete()
            throw e
        }
    }

    private fun stopIfCancelled() {
        if (cancelled()) throw CancellationException()
    }

    private fun silence(): Pcm {
        val rate = 44_100
        return Pcm(ShortArray((request.durationUs * rate / 1_000_000).toInt() * 2), rate, 2)
    }

    /** The clip's part of [uri] as 16-bit PCM, at most two channels, padded to its length. */
    private fun decode(uri: Uri): Pcm {
        val extractor = MediaExtractor()
        try {
            extractor.setDataSource(context, uri, null)
            val track = (0 until extractor.trackCount).firstOrNull {
                extractor.getTrackFormat(it).getString(MediaFormat.KEY_MIME)?.startsWith("audio/") == true
            } ?: throw IllegalArgumentException("No audio track")
            extractor.selectTrack(track)
            extractor.seekTo(request.startUs, MediaExtractor.SEEK_TO_PREVIOUS_SYNC)
            val format = extractor.getTrackFormat(track)
            val codec = MediaCodec.createDecoderByType(format.getString(MediaFormat.KEY_MIME)!!)
            try {
                codec.configure(format, null, null, 0)
                codec.start()
                return decodeRun(extractor, codec, format)
            } finally {
                runCatching { codec.stop() }
                codec.release()
            }
        } finally {
            extractor.release()
        }
    }

    private fun decodeRun(extractor: MediaExtractor, codec: MediaCodec, format: MediaFormat): Pcm {
        var rate = format.getInteger(MediaFormat.KEY_SAMPLE_RATE)
        var channels = format.getInteger(MediaFormat.KEY_CHANNEL_COUNT)
        var float = false
        var out = ShortArray(0)
        var length = 0
        val info = MediaCodec.BufferInfo()
        var inputDone = false
        var lastProgress = System.nanoTime()
        decoding@ while (true) {
            stopIfCancelled()
            if (System.nanoTime() - lastProgress > STALL_NANOS) throw IllegalStateException("Decoder stopped")
            var fed = false
            while (!inputDone) {
                val i = codec.dequeueInputBuffer(0)
                if (i < 0) break
                val size = extractor.readSampleData(codec.getInputBuffer(i)!!, 0)
                if (size < 0 || extractor.sampleTime > request.endUs) {
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
                    rate = f.getInteger(MediaFormat.KEY_SAMPLE_RATE)
                    channels = f.getInteger(MediaFormat.KEY_CHANNEL_COUNT)
                    float = f.containsKey(MediaFormat.KEY_PCM_ENCODING) &&
                        f.getInteger(MediaFormat.KEY_PCM_ENCODING) == AudioFormat.ENCODING_PCM_FLOAT
                    continue
                }
                if (o < 0) continue
                drained = true
                lastProgress = System.nanoTime()
                val keep = minOf(channels, 2)
                val total = (request.durationUs * rate / 1_000_000).toInt() * keep
                if (out.size != total) {
                    out = out.copyOf(total)
                    length = minOf(length, total)
                }
                val buffer = codec.getOutputBuffer(o)!!.order(ByteOrder.LITTLE_ENDIAN)
                val width = if (float) 4 else 2
                val frames = info.size / (width * channels)
                for (k in 0 until frames) {
                    val t = info.presentationTimeUs + k * 1_000_000L / rate
                    if (t < request.startUs) continue
                    if (t >= request.endUs || length >= total) break
                    for (c in 0 until keep) {
                        val at = info.offset + (k * channels + c) * width
                        out[length++] = if (float) {
                            (buffer.getFloat(at) * 32767).toInt().coerceIn(-32768, 32767).toShort()
                        } else {
                            buffer.getShort(at)
                        }
                    }
                }
                codec.releaseOutputBuffer(o, false)
                if (info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) break@decoding
                if (info.presentationTimeUs >= request.endUs) break@decoding
            }
        }
        val keep = minOf(channels, 2)
        val total = (request.durationUs * rate / 1_000_000).toInt() * keep
        return Pcm(out.copyOf(total), rate, keep)
    }

    private fun fade(pcm: Pcm) {
        val frames = pcm.samples.size / pcm.channels
        val fadeIn = (pcm.rate * FADE_IN_MS / 1000).coerceAtMost(frames / 2)
        val fadeOut = (pcm.rate * FADE_OUT_MS / 1000).coerceAtMost(frames / 2)
        for (f in 0 until frames) {
            val gain = when {
                f < fadeIn -> f.toDouble() / fadeIn
                f >= frames - fadeOut -> (frames - 1 - f).toDouble() / fadeOut
                else -> continue
            }
            for (c in 0 until pcm.channels) {
                val i = f * pcm.channels + c
                pcm.samples[i] = (pcm.samples[i] * gain).toInt().toShort()
            }
        }
    }

    private fun encodeAudio(pcm: Pcm): Pair<MediaFormat, List<Sample>> {
        val format = MediaFormat.createAudioFormat(MediaFormat.MIMETYPE_AUDIO_AAC, pcm.rate, pcm.channels)
        format.setInteger(MediaFormat.KEY_AAC_PROFILE, MediaCodecInfo.CodecProfileLevel.AACObjectLC)
        format.setInteger(MediaFormat.KEY_BIT_RATE, AUDIO_BIT_RATE)
        val codec = MediaCodec.createEncoderByType(MediaFormat.MIMETYPE_AUDIO_AAC)
        try {
            codec.configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
            codec.start()
            val samples = mutableListOf<Sample>()
            var outFormat: MediaFormat? = null
            val info = MediaCodec.BufferInfo()
            val bytes = ByteBuffer.allocate(pcm.samples.size * 2).order(ByteOrder.LITTLE_ENDIAN)
            bytes.asShortBuffer().put(pcm.samples)
            val frameBytes = 2 * pcm.channels
            var offset = 0
            var inputDone = false
            var lastProgress = System.nanoTime()
            while (true) {
                stopIfCancelled()
                if (System.nanoTime() - lastProgress > STALL_NANOS) throw IllegalStateException("AAC encoder stopped")
                if (!inputDone) {
                    val i = codec.dequeueInputBuffer(1_000)
                    if (i >= 0) {
                        val input = codec.getInputBuffer(i)!!
                        val n = minOf(input.remaining() / frameBytes * frameBytes, bytes.capacity() - offset)
                        val ptsUs = offset.toLong() / frameBytes * 1_000_000 / pcm.rate
                        if (n <= 0) {
                            codec.queueInputBuffer(i, 0, 0, ptsUs, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
                            inputDone = true
                        } else {
                            input.put(bytes.array(), offset, n)
                            codec.queueInputBuffer(i, 0, n, ptsUs, 0)
                            offset += n
                        }
                        lastProgress = System.nanoTime()
                    }
                }
                val o = codec.dequeueOutputBuffer(info, 1_000)
                if (o == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED) {
                    outFormat = codec.outputFormat
                } else if (o >= 0) {
                    lastProgress = System.nanoTime()
                    if (info.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG == 0 && info.size > 0) {
                        val buffer = codec.getOutputBuffer(o)!!
                        buffer.position(info.offset)
                        buffer.limit(info.offset + info.size)
                        val data = ByteArray(info.size).also { buffer.get(it) }
                        samples += Sample(data, info.presentationTimeUs, info.flags)
                    }
                    codec.releaseOutputBuffer(o, false)
                    if (info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) break
                }
            }
            return (outFormat ?: codec.outputFormat) to samples
        } finally {
            runCatching { codec.stop() }
            codec.release()
        }
    }

    private fun videoFormat(width: Int, height: Int): MediaFormat =
        MediaFormat.createVideoFormat(MediaFormat.MIMETYPE_VIDEO_AVC, width, height).apply {
            setInteger(MediaFormat.KEY_COLOR_FORMAT, MediaCodecInfo.CodecCapabilities.COLOR_FormatSurface)
            setInteger(MediaFormat.KEY_BIT_RATE, if (width >= 1080) 6_000_000 else 3_500_000)
            setInteger(MediaFormat.KEY_FRAME_RATE, request.fps)
            setInteger(MediaFormat.KEY_I_FRAME_INTERVAL, 1)
        }

    /** A configured H.264 encoder at the largest size this phone can do. */
    private fun videoCodec(): Pair<MediaCodec, MediaFormat> {
        val list = MediaCodecList(MediaCodecList.REGULAR_CODECS)
        var last: Exception? = null
        for ((width, height) in SIZES) {
            val format = videoFormat(width, height)
            val name = list.findEncoderForFormat(format) ?: continue
            val codec = MediaCodec.createByCodecName(name)
            try {
                codec.configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
                return codec to format
            } catch (e: Exception) {
                codec.release()
                last = e
            }
        }
        throw IllegalStateException("No H.264 encoder for a portrait clip", last)
    }

    private fun encodeVideo(audioFormat: MediaFormat, audio: List<Sample>): Result {
        val (codec, format) = videoCodec()
        val width = format.getInteger(MediaFormat.KEY_WIDTH)
        val height = format.getInteger(MediaFormat.KEY_HEIGHT)
        var surface: Surface? = null
        var gl: Gl? = null
        var muxer: MediaMuxer? = null
        var started = false
        try {
            surface = codec.createInputSurface()
            codec.start()
            gl = Gl(
                surface, width, height,
                floatArrayOf(request.windowTop, request.windowBottom, request.windowFade),
                request.center,
            )
            gl.loadBackground(request.background)
            muxer = MediaMuxer(request.out.absolutePath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
            val mux = muxer
            var videoTrack = -1
            val info = MediaCodec.BufferInfo()

            fun drain(end: Boolean) {
                var lastProgress = System.nanoTime()
                while (true) {
                    val o = codec.dequeueOutputBuffer(info, if (end) 10_000 else 0)
                    if (o == MediaCodec.INFO_TRY_AGAIN_LATER) {
                        if (!end) return
                        stopIfCancelled()
                        if (System.nanoTime() - lastProgress > STALL_NANOS) {
                            throw IllegalStateException("Video encoder stopped")
                        }
                        continue
                    }
                    if (o == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED) {
                        videoTrack = mux.addTrack(codec.outputFormat)
                        val audioTrack = mux.addTrack(audioFormat)
                        mux.start()
                        started = true
                        val buffer = MediaCodec.BufferInfo()
                        for (s in audio) {
                            buffer.set(0, s.data.size, s.ptsUs, s.flags)
                            mux.writeSampleData(audioTrack, ByteBuffer.wrap(s.data), buffer)
                        }
                        continue
                    }
                    if (o < 0) continue
                    lastProgress = System.nanoTime()
                    if (info.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG == 0 && info.size > 0) {
                        check(started) { "Video data before its format" }
                        val buffer = codec.getOutputBuffer(o)!!
                        buffer.position(info.offset)
                        buffer.limit(info.offset + info.size)
                        mux.writeSampleData(videoTrack, buffer, info)
                    }
                    codec.releaseOutputBuffer(o, false)
                    if (info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) return
                }
            }

            val count = ((request.durationUs * request.fps + 999_999) / 1_000_000).toInt()
            val half = request.transitionUs / 2
            var shown = -1
            var fadeStartUs = 0L
            for (n in 0 until count) {
                stopIfCancelled()
                val tUs = n * 1_000_000L / request.fps
                val frame = frameAt(tUs + half)
                if (frame != shown) {
                    gl.load(request.frames[frame].path, keepPrevious = shown >= 0)
                    fadeStartUs = if (shown < 0) Long.MIN_VALUE else request.frames[frame].atUs - half
                    shown = frame
                }
                val linear = if (request.transitionUs <= 0 || fadeStartUs == Long.MIN_VALUE) {
                    1f
                } else {
                    ((tUs - fadeStartUs).toFloat() / request.transitionUs).coerceIn(0f, 1f)
                }
                val (from, to) = moves(linear, request.frames[shown].scroll)
                gl.draw(tUs * 1000, from, to)
                drain(false)
                if (n % request.fps == 0) progress(AUDIO_SHARE + (1 - AUDIO_SHARE) * n / count)
            }
            codec.signalEndOfInputStream()
            drain(true)
            return Result(width, height, codec.name)
        } finally {
            gl?.release()
            runCatching { codec.stop() }
            codec.release()
            surface?.release()
            if (muxer != null) {
                if (started) runCatching { muxer.stop() }
                muxer.release()
            }
        }
    }

    /**
     * The old and new layers' alpha, upward shift and scale at [linear]
     * through a change, for [Request.motion].
     */
    private fun moves(linear: Float, scroll: Float): Pair<FloatArray, FloatArray> {
        fun ease(x: Float) = x * x * (3 - 2 * x)
        val m = ease(linear)
        return when (request.motion) {
            Motion.SCROLL -> floatArrayOf(1 - m, m * scroll, 1f) to floatArrayOf(m, -(1 - m) * scroll, 1f)
            Motion.FADE -> floatArrayOf(1 - m, 0f, 1f) to floatArrayOf(m, 0f, 1f)
            Motion.RISE -> floatArrayOf(1 - m, m * RISE, 1f) to floatArrayOf(m, -(1 - m) * RISE, 1f)
            Motion.ZOOM -> floatArrayOf(1 - m, 0f, 1 + 0.12f * m) to floatArrayOf(m, 0f, 0.85f + 0.15f * m)
            Motion.OUT_IN -> {
                val out = ease((2 * linear).coerceAtMost(1f))
                val back = ease((2 * linear - 1).coerceAtLeast(0f))
                floatArrayOf(1 - out, out * RISE / 2, 1f) to floatArrayOf(back, -(1 - back) * RISE / 2, 1f)
            }
        }
    }

    /** The last frame that starts at or before [tUs]; the first one before any starts. */
    private fun frameAt(tUs: Long): Int {
        var found = 0
        for ((i, f) in request.frames.withIndex()) {
            if (f.atUs <= tUs) found = i else break
        }
        return found
    }

    /**
     * Draws the background and the lyric layers onto the encoder's surface
     * with EGL: the previous layer blended into the current one while they
     * change, each shifted by its scroll and faded at the window's edges.
     */
    private class Gl(
        surface: Surface,
        private val width: Int,
        private val height: Int,
        private val band: FloatArray,
        private val center: Float,
    ) {
        private val display: EGLDisplay = EGL14.eglGetDisplay(EGL14.EGL_DEFAULT_DISPLAY)
        private val context: EGLContext
        private val window: EGLSurface
        private val program: Int
        private val textures = IntArray(3)
        private var current = 0
        private val quad: FloatBuffer = ByteBuffer.allocateDirect(QUAD.size * 4)
            .order(ByteOrder.nativeOrder()).asFloatBuffer().apply { put(QUAD).position(0) }

        init {
            val version = IntArray(2)
            check(EGL14.eglInitialize(display, version, 0, version, 1)) { "No EGL" }
            val configs = arrayOfNulls<EGLConfig>(1)
            val count = IntArray(1)
            val attributes = intArrayOf(
                EGL14.EGL_RED_SIZE, 8, EGL14.EGL_GREEN_SIZE, 8, EGL14.EGL_BLUE_SIZE, 8,
                EGL14.EGL_RENDERABLE_TYPE, EGL14.EGL_OPENGL_ES2_BIT,
                EGL_RECORDABLE_ANDROID, 1, EGL14.EGL_NONE,
            )
            check(EGL14.eglChooseConfig(display, attributes, 0, configs, 0, 1, count, 0) && count[0] > 0) {
                "No recordable EGL config"
            }
            context = EGL14.eglCreateContext(
                display, configs[0], EGL14.EGL_NO_CONTEXT,
                intArrayOf(EGL14.EGL_CONTEXT_CLIENT_VERSION, 2, EGL14.EGL_NONE), 0,
            )
            window = EGL14.eglCreateWindowSurface(display, configs[0], surface, intArrayOf(EGL14.EGL_NONE), 0)
            check(EGL14.eglMakeCurrent(display, window, window, context)) { "EGL makeCurrent failed" }
            program = link(VERTEX, FRAGMENT)
            GLES20.glGenTextures(3, textures, 0)
            for (texture in textures) {
                GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, texture)
                GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_LINEAR)
                GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_LINEAR)
                GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_S, GLES20.GL_CLAMP_TO_EDGE)
                GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_T, GLES20.GL_CLAMP_TO_EDGE)
            }
        }

        fun loadBackground(path: String) {
            val bitmap = BitmapFactory.decodeFile(path) ?: throw IllegalArgumentException("Bad background $path")
            try {
                GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, textures[2])
                GLUtils.texImage2D(GLES20.GL_TEXTURE_2D, 0, bitmap, 0)
            } finally {
                bitmap.recycle()
            }
        }

        /**
         * Makes [path] the current picture; the old one stays as the previous
         * picture when [keepPrevious], else both show [path].
         */
        fun load(path: String, keepPrevious: Boolean) {
            val bitmap = BitmapFactory.decodeFile(path) ?: throw IllegalArgumentException("Bad frame $path")
            try {
                current = 1 - current
                GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, textures[current])
                GLUtils.texImage2D(GLES20.GL_TEXTURE_2D, 0, bitmap, 0)
                if (!keepPrevious) {
                    GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, textures[1 - current])
                    GLUtils.texImage2D(GLES20.GL_TEXTURE_2D, 0, bitmap, 0)
                }
            } finally {
                bitmap.recycle()
            }
        }

        /**
         * Draws the previous layer by [from] and the current one by [to]: each
         * its alpha, its upward shift as a part of the height, and its scale.
         */
        fun draw(ptsNs: Long, from: FloatArray, to: FloatArray) {
            GLES20.glViewport(0, 0, width, height)
            GLES20.glClearColor(0f, 0f, 0f, 1f)
            GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT)
            GLES20.glUseProgram(program)
            val position = GLES20.glGetAttribLocation(program, "aPosition")
            val coord = GLES20.glGetAttribLocation(program, "aCoord")
            quad.position(0)
            GLES20.glVertexAttribPointer(position, 2, GLES20.GL_FLOAT, false, 16, quad)
            GLES20.glEnableVertexAttribArray(position)
            quad.position(2)
            GLES20.glVertexAttribPointer(coord, 2, GLES20.GL_FLOAT, false, 16, quad)
            GLES20.glEnableVertexAttribArray(coord)
            GLES20.glActiveTexture(GLES20.GL_TEXTURE0)
            GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, textures[1 - current])
            GLES20.glUniform1i(GLES20.glGetUniformLocation(program, "uFrom"), 0)
            GLES20.glActiveTexture(GLES20.GL_TEXTURE1)
            GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, textures[current])
            GLES20.glUniform1i(GLES20.glGetUniformLocation(program, "uTo"), 1)
            GLES20.glActiveTexture(GLES20.GL_TEXTURE2)
            GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, textures[2])
            GLES20.glUniform1i(GLES20.glGetUniformLocation(program, "uBack"), 2)
            GLES20.glUniform3f(GLES20.glGetUniformLocation(program, "uFromMove"), from[0], from[1], from[2])
            GLES20.glUniform3f(GLES20.glGetUniformLocation(program, "uToMove"), to[0], to[1], to[2])
            GLES20.glUniform1f(GLES20.glGetUniformLocation(program, "uCenter"), center)
            GLES20.glUniform3f(
                GLES20.glGetUniformLocation(program, "uWindow"),
                band[0], band[1], band[2],
            )
            GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4)
            EGLExt.eglPresentationTimeANDROID(display, window, ptsNs)
            check(EGL14.eglSwapBuffers(display, window)) { "EGL swap failed" }
        }

        fun release() {
            GLES20.glDeleteTextures(3, textures, 0)
            GLES20.glDeleteProgram(program)
            EGL14.eglMakeCurrent(display, EGL14.EGL_NO_SURFACE, EGL14.EGL_NO_SURFACE, EGL14.EGL_NO_CONTEXT)
            EGL14.eglDestroySurface(display, window)
            EGL14.eglDestroyContext(display, context)
            EGL14.eglReleaseThread()
            EGL14.eglTerminate(display)
        }

        private fun link(vertex: String, fragment: String): Int {
            val p = GLES20.glCreateProgram()
            GLES20.glAttachShader(p, shader(GLES20.GL_VERTEX_SHADER, vertex))
            GLES20.glAttachShader(p, shader(GLES20.GL_FRAGMENT_SHADER, fragment))
            GLES20.glLinkProgram(p)
            val ok = IntArray(1)
            GLES20.glGetProgramiv(p, GLES20.GL_LINK_STATUS, ok, 0)
            check(ok[0] != 0) { "GL link failed: ${GLES20.glGetProgramInfoLog(p)}" }
            return p
        }

        private fun shader(type: Int, source: String): Int {
            val s = GLES20.glCreateShader(type)
            GLES20.glShaderSource(s, source)
            GLES20.glCompileShader(s)
            val ok = IntArray(1)
            GLES20.glGetShaderiv(s, GLES20.GL_COMPILE_STATUS, ok, 0)
            check(ok[0] != 0) { "GL shader failed: ${GLES20.glGetShaderInfoLog(s)}" }
            return s
        }

        companion object {
            private const val EGL_RECORDABLE_ANDROID = 0x3142

            /** x, y, s, t per corner; t is flipped, as bitmaps load top row first. */
            private val QUAD = floatArrayOf(
                -1f, -1f, 0f, 1f,
                1f, -1f, 1f, 1f,
                -1f, 1f, 0f, 0f,
                1f, 1f, 1f, 0f,
            )

            private const val VERTEX = """
                attribute vec4 aPosition;
                attribute vec2 aCoord;
                varying vec2 vCoord;
                void main() { gl_Position = aPosition; vCoord = aCoord; }
            """

            private const val FRAGMENT = """
                precision highp float;
                varying vec2 vCoord;
                uniform sampler2D uBack;
                uniform sampler2D uFrom;
                uniform sampler2D uTo;
                uniform vec3 uFromMove;
                uniform vec3 uToMove;
                uniform float uCenter;
                uniform vec3 uWindow;
                vec4 layer(sampler2D s, vec3 move) {
                    vec2 pivot = vec2(0.5, uCenter);
                    vec2 c = (vCoord - pivot) / move.z + pivot;
                    c.y += move.y;
                    if (c.x < 0.0 || c.x > 1.0 || c.y < 0.0 || c.y > 1.0) return vec4(0.0);
                    return texture2D(s, c) * move.x;
                }
                void main() {
                    vec4 back = texture2D(uBack, vCoord);
                    vec4 lyrics = min(layer(uFrom, uFromMove) + layer(uTo, uToMove), vec4(1.0));
                    float fade = max(uWindow.z, 0.0001);
                    lyrics *= smoothstep(uWindow.x, uWindow.x + fade, vCoord.y)
                        * (1.0 - smoothstep(uWindow.y - fade, uWindow.y, vCoord.y));
                    gl_FragColor = vec4(lyrics.rgb + back.rgb * (1.0 - lyrics.a), 1.0);
                }
            """
        }
    }

    companion object {
        /** Portrait sizes tried in order. */
        private val SIZES = listOf(1080 to 1920, 720 to 1280)
        private const val AUDIO_BIT_RATE = 128_000
        private const val FADE_IN_MS = 50
        private const val FADE_OUT_MS = 500

        /** The part of the progress bar the audio takes. */
        private const val AUDIO_SHARE = 0.15

        private const val STALL_NANOS = 10_000_000_000L

        /** How far, as a part of the height, a line rises in and out. */
        private const val RISE = 0.04f
    }
}
