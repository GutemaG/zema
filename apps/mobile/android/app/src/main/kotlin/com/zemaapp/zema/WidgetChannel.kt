package com.zemaapp.zema

import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

class WidgetChannel(private val context: Context, messenger: BinaryMessenger) {
    private val channel = MethodChannel(messenger, NAME)

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "setLast" -> {
                    val args = call.arguments as? Map<*, *>
                    ListenWidgetProvider.setLast(
                        context,
                        args?.get("title") as? String,
                        args?.get("artist") as? String,
                    )
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
    }

    companion object {
        private const val NAME = "zema/widget"
    }
}
