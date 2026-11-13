package com.zemaapp.zema

import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class DetectionChannel(private val context: Context, messenger: BinaryMessenger) {
    private val methods = MethodChannel(messenger, NAME)
    private val events = EventChannel(messenger, "$NAME/events")
    private var stopListening: (() -> Unit)? = null

    init {
        methods.setMethodCallHandler { call, result ->
            when (call.method) {
                "hasAccess" -> result.success(hasAccess())
                "openAccessSettings" -> {
                    openAccessSettings()
                    result.success(null)
                }
                "enabled" -> result.success(PlaybackHub.enabled(context))
                "setEnabled" -> {
                    PlaybackHub.setEnabled(context, call.arguments == true)
                    result.success(null)
                }
                "sources" -> result.success(PlaybackHub.sources(context).toList())
                "setSources" -> {
                    val sources = (call.arguments as? List<*>)?.filterIsInstance<String>()?.toSet()
                    if (sources == null) {
                        result.error("bad_arguments", "A list of package names is needed", null)
                    } else {
                        PlaybackHub.setSources(context, sources)
                        result.success(null)
                    }
                }
                else -> result.notImplemented()
            }
        }
        events.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, sink: EventChannel.EventSink) {
                stopListening?.invoke()
                stopListening = PlaybackHub.listen { sink.success(it) }
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

    private fun hasAccess(): Boolean {
        val enabled = Settings.Secure.getString(context.contentResolver, "enabled_notification_listeners")
            ?: return false
        val me = MediaWatchService.component(context)
        return enabled.split(':').any { it == me.flattenToString() || it == me.flattenToShortString() }
    }

    private fun openAccessSettings() {
        val detail = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            Intent(Settings.ACTION_NOTIFICATION_LISTENER_DETAIL_SETTINGS).putExtra(
                Settings.EXTRA_NOTIFICATION_LISTENER_COMPONENT_NAME,
                MediaWatchService.component(context).flattenToString(),
            )
        } else {
            null
        }
        val all = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
        for (intent in listOfNotNull(detail, all)) {
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            if (runCatching { context.startActivity(intent) }.isSuccess) return
        }
    }

    companion object {
        private const val NAME = "zema/detection"
    }
}
