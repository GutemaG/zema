package com.zemaapp.zema

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.Settings
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class OverlayChannel(private val context: Context, messenger: BinaryMessenger) {
    private val methods = MethodChannel(messenger, NAME)
    private val events = EventChannel(messenger, "$NAME/events")
    private var stopListening: (() -> Unit)? = null

    init {
        methods.setMethodCallHandler { call, result ->
            when (call.method) {
                "canShow" -> result.success(LyricsOverlay.canShow(context))
                "openSettings" -> {
                    openSettings()
                    result.success(null)
                }
                "show" -> {
                    val args = call.arguments as? Map<*, *>
                    val sheet = args?.let { LyricsSheet.of(it) }
                    if (sheet == null) {
                        result.error("bad_arguments", "A key, a source and lines are needed", null)
                    } else {
                        result.success(LyricsOverlay.show(context, sheet, modeOf(args["mode"])))
                    }
                }
                "appearance" -> result.success(LyricsOverlay.appearance(context))
                "setAppearance" -> {
                    val args = call.arguments as? Map<*, *> ?: emptyMap<Any, Any>()
                    LyricsOverlay.setAppearance(
                        context,
                        (args["textSp"] as? Number)?.toFloat(),
                        (args["opacity"] as? Number)?.toFloat(),
                        modeOf(args["start"]),
                    )
                    result.success(null)
                }
                "hide" -> {
                    LyricsOverlay.hide()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        events.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, sink: EventChannel.EventSink) {
                stopListening?.invoke()
                stopListening = LyricsOverlay.listen { sink.success(it) }
            }

            override fun onCancel(arguments: Any?) {
                stopListening?.invoke()
                stopListening = null
            }
        })
    }

    fun dispose() {
        methods.setMethodCallHandler(null)
        events.setStreamHandler(null)
        stopListening?.invoke()
        stopListening = null
    }

    private fun modeOf(value: Any?) = when (value) {
        "bubble" -> LyricsOverlay.Mode.BUBBLE
        "bar" -> LyricsOverlay.Mode.BAR
        "panel" -> LyricsOverlay.Mode.PANEL
        else -> null
    }

    private fun openSettings() {
        val intent = Intent(
            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
            Uri.parse("package:${context.packageName}"),
        ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        runCatching { context.startActivity(intent) }
    }

    companion object {
        private const val NAME = "zema/overlay"
    }
}
