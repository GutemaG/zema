package com.zemaapp.zema

import android.content.Context
import android.content.Intent
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class LaunchChannel(messenger: BinaryMessenger) : MethodChannel.MethodCallHandler {
    private val channel = MethodChannel(messenger, NAME)
    private var asked = false
    private var initial: Map<String, Any?>? = null

    init {
        channel.setMethodCallHandler(this)
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "takeLaunch" -> {
                asked = true
                result.success(initial)
                initial = null
            }
            else -> result.notImplemented()
        }
    }

    fun handle(intent: Intent?) {
        val request = requestOf(intent) ?: return
        if (asked) {
            channel.invokeMethod("launch", request)
        } else {
            initial = request
        }
    }

    private fun requestOf(intent: Intent?): Map<String, Any?>? = when (intent?.action) {
        ACTION_HISTORY -> mapOf("open" to "history")
        ACTION_DETECTED -> mapOf(
            "open" to "detected",
            "key" to intent.getStringExtra("key"),
            "ask" to intent.getStringExtra("ask"),
        )
        ACTION_KEEP_LISTENING -> mapOf("open" to "keepListening")
        ACTION_SONG -> mapOf("open" to "song", "songId" to intent.getStringExtra("songId"))
        ACTION_MATCH -> mapOf(
            "open" to "match",
            "trackId" to intent.getLongExtra("trackId", -1),
            "positionMs" to intent.getLongExtra("positionMs", 0),
            "startedAtMs" to intent.getLongExtra("startedAtMs", 0),
            "speed" to intent.getDoubleExtra("speed", 1.0),
            "score" to intent.getLongExtra("score", 0),
            "sure" to intent.getBooleanExtra("sure", true),
        )
        else -> null
    }

    companion object {
        private const val NAME = "zema/launch"
        const val ACTION_HISTORY = "com.zemaapp.zema.OPEN_LISTEN_HISTORY"
        const val ACTION_MATCH = "com.zemaapp.zema.OPEN_LISTEN_MATCH"
        const val ACTION_SONG = "com.zemaapp.zema.OPEN_SONG"
        const val ACTION_DETECTED = "com.zemaapp.zema.OPEN_DETECTED"
        const val ACTION_KEEP_LISTENING = "com.zemaapp.zema.OPEN_KEEP_LISTENING"

        fun keepListeningIntent(context: Context): Intent =
            Intent(context, MainActivity::class.java)
                .setAction(ACTION_KEEP_LISTENING)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)

        fun historyIntent(context: Context): Intent =
            Intent(context, MainActivity::class.java)
                .setAction(ACTION_HISTORY)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)

        fun detectedIntent(context: Context, key: String, ask: String): Intent =
            Intent(context, MainActivity::class.java)
                .setAction(ACTION_DETECTED)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                .putExtra("key", key)
                .putExtra("ask", ask)

        fun songIntent(context: Context, songId: String?): Intent =
            Intent(context, MainActivity::class.java)
                .setAction(if (songId == null) Intent.ACTION_MAIN else ACTION_SONG)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                .apply { if (songId != null) putExtra("songId", songId) }

        fun matchIntent(context: Context, args: Map<*, *>): Intent =
            Intent(context, MainActivity::class.java)
                .setAction(ACTION_MATCH)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                .putExtra("trackId", (args["trackId"] as? Number)?.toLong() ?: -1)
                .putExtra("positionMs", (args["positionMs"] as? Number)?.toLong() ?: 0)
                .putExtra("startedAtMs", (args["startedAtMs"] as? Number)?.toLong() ?: 0)
                .putExtra("speed", (args["speed"] as? Number)?.toDouble() ?: 1.0)
                .putExtra("score", (args["score"] as? Number)?.toLong() ?: 0)
                .putExtra("sure", args["sure"] as? Boolean ?: true)
    }
}
