package com.zemaapp.zema

import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import com.ryanheise.audioservice.AudioServiceActivity
import com.ryanheise.audioservice.AudioServicePlugin
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import java.util.WeakHashMap

// AudioServiceActivity keeps one Flutter engine shared with the playback
// service, so music continues when the activity closes. A share from another
// app can open a second activity on that engine, so the channels belong to the
// engine, not to an activity: made once, and disposed when it is destroyed.
class MainActivity : AudioServiceActivity() {
    private var share: ShareChannel? = null
    private var launch: LaunchChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        OverlayEngine.stop()
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val channels = channelsOf(flutterEngine)
        share = channels.share.also { it.handle(intent) }
        launch = channels.launch.also { it.handle(intent) }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        share?.handle(intent)
        launch?.handle(intent)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        share = null
        launch = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    private fun channelsOf(engine: FlutterEngine): Channels =
        channels.getOrPut(engine) {
            OverlayEngine.stop()
            val messenger = engine.dartExecutor.binaryMessenger
            val made = Channels(
                LibraryChannel(applicationContext, messenger),
                ShareChannel(applicationContext, messenger),
                AudioDecodeChannel(applicationContext, messenger),
                LaunchChannel(messenger),
                WidgetChannel(applicationContext, messenger),
                DetectionChannel(applicationContext, messenger),
                OverlayChannel(applicationContext, messenger),
            )
            engine.addEngineLifecycleListener(object : FlutterEngine.EngineLifecycleListener {
                override fun onPreEngineRestart() {}

                override fun onEngineWillDestroy() {
                    made.library.dispose()
                    made.share.dispose()
                    made.audio.dispose()
                    made.launch.dispose()
                    made.widget.dispose()
                    made.detection.dispose()
                    made.overlay.dispose()
                    channels.remove(engine)
                    Handler(Looper.getMainLooper()).post { OverlayEngine.check() }
                }
            })
            made
        }

    private class Channels(
        val library: LibraryChannel,
        val share: ShareChannel,
        val audio: AudioDecodeChannel,
        val launch: LaunchChannel,
        val widget: WidgetChannel,
        val detection: DetectionChannel,
        val overlay: OverlayChannel,
    )

    companion object {
        private val channels = WeakHashMap<FlutterEngine, Channels>()

        fun appRunning(): Boolean = channels.isNotEmpty() ||
            FlutterEngineCache.getInstance().contains(AudioServicePlugin.getFlutterEngineId())
    }
}
