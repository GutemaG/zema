package com.zemaapp.zema

import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

class KeepListeningChannel(private val context: Context, messenger: BinaryMessenger) {
    private val channel = MethodChannel(messenger, "zema/keep_listening")
    private val main = Handler(Looper.getMainLooper())

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> {
                    KeepListeningService.start(
                        context,
                        call.argument<String>("title"),
                        call.argument<String>("text"),
                        call.argument<String>("stop"),
                        call.argument<Number>("lengthMs")?.toLong() ?: 0,
                    )
                    result.success(null)
                }
                "show" -> {
                    KeepListeningService.show(
                        context,
                        call.argument<String>("title"),
                        call.argument<String>("text"),
                    )
                    result.success(null)
                }
                "stop" -> {
                    KeepListeningService.stop(context, call.argument<String>("why"))
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        KeepListeningService.onStopTapped = {
            main.post { channel.invokeMethod("stopTapped", null) }
        }
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        KeepListeningService.onStopTapped = null
        KeepListeningService.stop(context, null)
    }
}
