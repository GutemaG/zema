package com.zemaapp.zema

import android.content.Intent
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import java.util.WeakHashMap

// AudioServiceActivity keeps one Flutter engine shared with the playback
// service, so music continues when the activity closes. A share from another
// app can open a second activity on that engine, so the channels belong to the
// engine, not to an activity: made once, and disposed when it is destroyed.
class MainActivity : AudioServiceActivity() {
    private var share: ShareChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        share = channelsOf(flutterEngine).share.also { it.handle(intent) }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        share?.handle(intent)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        share = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    private fun channelsOf(engine: FlutterEngine): Channels =
        channels.getOrPut(engine) {
            val messenger = engine.dartExecutor.binaryMessenger
            val made = Channels(
                LibraryChannel(applicationContext, messenger),
                ShareChannel(applicationContext, messenger),
                AudioDecodeChannel(applicationContext, messenger),
            )
            engine.addEngineLifecycleListener(object : FlutterEngine.EngineLifecycleListener {
                override fun onPreEngineRestart() {}

                override fun onEngineWillDestroy() {
                    made.library.dispose()
                    made.share.dispose()
                    made.audio.dispose()
                    channels.remove(engine)
                }
            })
            made
        }

    private class Channels(
        val library: LibraryChannel,
        val share: ShareChannel,
        val audio: AudioDecodeChannel,
    )

    companion object {
        private val channels = WeakHashMap<FlutterEngine, Channels>()
    }
}
