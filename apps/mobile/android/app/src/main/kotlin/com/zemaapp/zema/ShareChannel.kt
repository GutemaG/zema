package com.zemaapp.zema

import android.content.Context
import android.content.Intent
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.OpenableColumns
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors

/**
 * Receives audio files shared to Zema (from Telegram or any app) for the Dart
 * `AndroidShareReceiver`. Each file is copied into `files/shared_audio`, so it
 * stays readable after the sharing app's permission ends.
 *
 * One per Flutter engine (see [MainActivity]): the engine outlives activities, since
 * it keeps playing music, and a share from another app may open a new activity on it.
 *
 * Methods:
 * - `takeShared` → the file shared before Dart first asked, once ({path, name,
 *   durationMs}), or null; waits for its copy to finish
 *
 * Calls to Dart:
 * - `shared` {path, name, durationMs} for files shared after that
 */
class ShareChannel(private val context: Context, messenger: BinaryMessenger) :
    MethodChannel.MethodCallHandler {

    private val channel = MethodChannel(messenger, NAME)
    private val executor = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    // Whether Dart has asked for the initial share; later shares are sent to it.
    private var asked = false

    // The share that started the app: copying, then ready to hand over once.
    private var initialCopying = false
    private var initial: Map<String, Any?>? = null
    private var waiting: MethodChannel.Result? = null

    init {
        channel.setMethodCallHandler(this)
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        executor.shutdown()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "takeShared" -> {
                asked = true
                if (initialCopying) {
                    waiting = result
                } else {
                    result.success(initial)
                    initial = null
                }
            }
            else -> result.notImplemented()
        }
    }

    /**
     * Copies the audio file [intent] shares, if any: kept for `takeShared` until Dart has
     * asked for it, sent to Dart after that, whichever activity [intent] came to.
     */
    fun handle(intent: Intent?) {
        if (intent?.action != Intent.ACTION_SEND) return
        if (intent.type?.startsWith("audio/") != true) return
        val uri = streamOf(intent) ?: return
        val started = !asked
        if (started) initialCopying = true
        executor.execute {
            val copied = try {
                copy(uri)
            } catch (e: Exception) {
                Log.w(TAG, "Copying a shared file failed", e)
                null
            }
            main.post {
                if (started) {
                    initialCopying = false
                    val result = waiting
                    if (result != null) {
                        waiting = null
                        result.success(copied)
                    } else {
                        initial = copied
                    }
                } else if (copied != null) {
                    channel.invokeMethod("shared", copied)
                }
            }
        }
    }

    @Suppress("DEPRECATION")
    private fun streamOf(intent: Intent): Uri? =
        if (Build.VERSION.SDK_INT >= 33) {
            intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
        } else {
            intent.getParcelableExtra(Intent.EXTRA_STREAM) as? Uri
        }

    private fun copy(uri: Uri): Map<String, Any?> {
        val name = displayName(uri) ?: "audio"
        val folder = File(context.filesDir, "shared_audio").apply { mkdirs() }
        val safe = name.replace(Regex("[^\\p{L}\\p{N}._ -]"), "_").take(120)
        val target = File(folder, "${System.currentTimeMillis()}-$safe")
        context.contentResolver.openInputStream(uri).use { input ->
            requireNotNull(input) { "No stream for $uri" }
            target.outputStream().use { input.copyTo(it) }
        }
        return mapOf(
            "path" to target.absolutePath,
            "name" to name,
            "durationMs" to durationMs(target),
        )
    }

    private fun displayName(uri: Uri): String? =
        context.contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
            ?.use { cursor -> if (cursor.moveToFirst()) cursor.getString(0) else null }

    private fun durationMs(file: File): Int? {
        val retriever = MediaMetadataRetriever()
        return try {
            retriever.setDataSource(file.absolutePath)
            retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)?.toIntOrNull()
        } catch (e: Exception) {
            null
        } finally {
            retriever.release()
        }
    }

    companion object {
        const val NAME = "zema/share"
        private const val TAG = "ZemaShare"
    }
}
