package com.zemaapp.zema

import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import android.util.Log
import androidx.core.content.FileProvider
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.CancellationException
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Makes lyrics clip videos for the Dart `AndroidClipEncoder`, one at a time.
 *
 * Methods:
 * - `encode` {id, audioUri?, startMs, endMs, background, frames: [{path, atMs, scroll}],
 *   outPath, fps, transitionMs, window: {top, bottom, fade},
 *   motion (scroll, fade, rise, zoom, outIn), centerX, center}
 *   → {path, width, height, millis, codec}; see [ClipEncoder]. Errors:
 *   `cancelled`, `encode_failed`, `bad_args`
 * - `cancel` {id}: stops that encode; its file is deleted
 * - `saveToGallery` {path, name} → the new video's content URI (Movies/Zema).
 *   Android 10 and later; `unsupported` before that
 * - `share` {path, text}: the share menu with the video (a file under the
 *   cache's `clips` folder) and the text
 *
 * Calls to Dart:
 * - `progress` {id, fraction} about once a second of video
 */
class ClipChannel(private val context: Context, messenger: BinaryMessenger) :
    MethodChannel.MethodCallHandler {

    private val channel = MethodChannel(messenger, NAME)
    private val executor = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    private val jobs = ConcurrentHashMap<String, AtomicBoolean>()

    init {
        channel.setMethodCallHandler(this)
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        jobs.values.forEach { it.set(true) }
        executor.shutdown()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "encode" -> encode(call, result)
            "cancel" -> {
                call.argument<String>("id")?.let { jobs[it]?.set(true) }
                result.success(null)
            }
            "saveToGallery" -> {
                val path = call.argument<String>("path")
                val name = call.argument<String>("name")
                if (path == null || name == null) {
                    result.error("bad_args", "saveToGallery needs a path and a name", null)
                } else if (Build.VERSION.SDK_INT < 29) {
                    result.error("unsupported", "Saving needs Android 10", null)
                } else {
                    executor.execute {
                        try {
                            val uri = save(File(path), name)
                            main.post { result.success(uri.toString()) }
                        } catch (e: Exception) {
                            Log.w(TAG, "Saving a clip failed", e)
                            main.post { result.error("save_failed", e.message, null) }
                        }
                    }
                }
            }
            "share" -> {
                val path = call.argument<String>("path")
                if (path == null) {
                    result.error("bad_args", "share needs a path", null)
                    return
                }
                try {
                    share(File(path), call.argument<String>("text"))
                    result.success(null)
                } catch (e: Exception) {
                    Log.w(TAG, "Sharing a clip failed", e)
                    result.error("share_failed", e.message, null)
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun share(file: File, text: String?) {
        val uri = FileProvider.getUriForFile(context, "${context.packageName}.clips", file)
        val send = Intent(Intent.ACTION_SEND).apply {
            type = "video/mp4"
            putExtra(Intent.EXTRA_STREAM, uri)
            if (text != null) putExtra(Intent.EXTRA_TEXT, text)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        context.startActivity(
            Intent.createChooser(send, null)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_GRANT_READ_URI_PERMISSION),
        )
    }

    private fun encode(call: MethodCall, result: MethodChannel.Result) {
        val id = call.argument<String>("id")
        val out = call.argument<String>("outPath")
        val start = call.argument<Number>("startMs")?.toLong()
        val end = call.argument<Number>("endMs")?.toLong()
        val frames = call.argument<List<Map<String, Any?>>>("frames")?.mapNotNull { f ->
            val path = f["path"] as? String
            val at = (f["atMs"] as? Number)?.toLong()
            val scroll = (f["scroll"] as? Number)?.toFloat() ?: 0f
            if (path == null || at == null) null else ClipEncoder.Frame(path, at * 1000, scroll)
        }
        val background = call.argument<String>("background")
        val window = call.argument<Map<String, Any?>>("window")
        if (id == null || out == null || start == null || end == null || background == null ||
            frames.isNullOrEmpty()
        ) {
            result.error("bad_args", "encode needs an id, a range, a background, frames and an outPath", null)
            return
        }
        val request = ClipEncoder.Request(
            audio = call.argument<String>("audioUri")?.let { Uri.parse(it) },
            startUs = start * 1000,
            endUs = end * 1000,
            background = background,
            frames = frames,
            out = File(out),
            fps = call.argument<Number>("fps")?.toInt() ?: 30,
            transitionUs = (call.argument<Number>("transitionMs")?.toLong() ?: 250) * 1000,
            windowTop = (window?.get("top") as? Number)?.toFloat() ?: 0f,
            windowBottom = (window?.get("bottom") as? Number)?.toFloat() ?: 1f,
            windowFade = (window?.get("fade") as? Number)?.toFloat() ?: 0f,
            motion = when (call.argument<String>("motion")) {
                "fade" -> ClipEncoder.Motion.FADE
                "rise" -> ClipEncoder.Motion.RISE
                "zoom" -> ClipEncoder.Motion.ZOOM
                "outIn" -> ClipEncoder.Motion.OUT_IN
                else -> ClipEncoder.Motion.SCROLL
            },
            centerX = (call.argument<Number>("centerX"))?.toFloat() ?: 0.5f,
            center = (call.argument<Number>("center"))?.toFloat() ?: 0.5f,
        )
        val stop = AtomicBoolean(false)
        jobs[id] = stop
        executor.execute {
            try {
                val started = System.nanoTime()
                val made = ClipEncoder(context, request, stop::get) { fraction ->
                    main.post { channel.invokeMethod("progress", mapOf("id" to id, "fraction" to fraction)) }
                }.run()
                val millis = (System.nanoTime() - started) / 1_000_000
                main.post {
                    result.success(
                        mapOf(
                            "path" to out,
                            "width" to made.width,
                            "height" to made.height,
                            "millis" to millis,
                            "codec" to made.codec,
                        ),
                    )
                }
            } catch (e: CancellationException) {
                main.post { result.error("cancelled", null, null) }
            } catch (e: Throwable) {
                Log.w(TAG, "Making a clip failed", e)
                main.post { result.error("encode_failed", e.message, null) }
            } finally {
                jobs.remove(id)
            }
        }
    }

    private fun save(file: File, name: String): Uri {
        val resolver = context.contentResolver
        val values = ContentValues().apply {
            put(MediaStore.Video.Media.DISPLAY_NAME, name)
            put(MediaStore.Video.Media.MIME_TYPE, "video/mp4")
            put(MediaStore.Video.Media.RELATIVE_PATH, "${Environment.DIRECTORY_MOVIES}/Zema")
            put(MediaStore.Video.Media.IS_PENDING, 1)
        }
        val collection = MediaStore.Video.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        val uri = resolver.insert(collection, values) ?: throw IllegalStateException("No gallery entry")
        try {
            resolver.openOutputStream(uri).use { output ->
                requireNotNull(output) { "No stream for $uri" }
                file.inputStream().use { it.copyTo(output) }
            }
            resolver.update(uri, ContentValues().apply { put(MediaStore.Video.Media.IS_PENDING, 0) }, null, null)
            return uri
        } catch (e: Exception) {
            resolver.delete(uri, null, null)
            throw e
        }
    }

    companion object {
        private const val NAME = "zema/clip"
        private const val TAG = "ZemaClip"
    }
}
