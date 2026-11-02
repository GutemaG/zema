package com.zemaapp.zema

import android.content.Intent
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine

// AudioServiceActivity keeps one Flutter engine shared with the playback
// service, so music continues when the activity closes.
class MainActivity : AudioServiceActivity() {
    private var library: LibraryChannel? = null
    private var share: ShareChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        library = LibraryChannel(applicationContext, messenger)
        share = ShareChannel(applicationContext, messenger).also {
            it.handle(intent, started = true)
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        share?.handle(intent, started = false)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        library?.dispose()
        library = null
        share?.dispose()
        share = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
