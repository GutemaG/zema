package com.zemaapp.zema

import android.content.Context
import android.os.Handler
import android.os.Looper
import com.github.dart_lang.jni.JniPlugin
import com.github.dart_lang.jni_flutter.JniFlutterPlugin
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.embedding.engine.plugins.FlutterPlugin

object OverlayEngine {
    private const val IDLE_MS = 120_000L
    private const val ENTRYPOINT = "overlayMain"

    private val main = Handler(Looper.getMainLooper())
    private var app: Context? = null
    private var engine: FlutterEngine? = null
    private var detection: DetectionChannel? = null
    private var overlay: OverlayChannel? = null
    private var stopWatching: (() -> Unit)? = null

    private val idle = Runnable {
        stop()
        LyricsOverlay.hide()
    }

    fun watch(context: Context) {
        if (stopWatching != null) return
        app = context.applicationContext
        stopWatching = PlaybackHub.listen { check() }
    }

    fun unwatch() {
        stopWatching?.invoke()
        stopWatching = null
        stop()
    }

    fun check() {
        val context = app ?: return
        if (MainActivity.appRunning()) {
            stop()
            return
        }
        if (PlaybackHub.anyPlaying()) {
            main.removeCallbacks(idle)
            if (engine == null && LyricsOverlay.canShow(context)) start(context)
        } else if (engine != null) {
            main.removeCallbacks(idle)
            main.postDelayed(idle, IDLE_MS)
        }
    }

    fun stop() {
        main.removeCallbacks(idle)
        detection?.dispose()
        overlay?.dispose()
        detection = null
        overlay = null
        engine?.destroy()
        engine = null
    }

    private fun plugins(): List<FlutterPlugin> = listOf(JniPlugin(), JniFlutterPlugin())

    private fun start(context: Context) {
        val loader = FlutterInjector.instance().flutterLoader()
        loader.startInitialization(context)
        loader.ensureInitializationComplete(context, null)
        val made = FlutterEngine(context, null, false)
        for (plugin in plugins()) runCatching { made.plugins.add(plugin) }
        val messenger = made.dartExecutor.binaryMessenger
        detection = DetectionChannel(context, messenger)
        overlay = OverlayChannel(context, messenger)
        made.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint(loader.findAppBundlePath(), ENTRYPOINT),
        )
        engine = made
    }
}
