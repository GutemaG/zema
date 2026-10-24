package com.zemaapp.zema

import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine

// AudioServiceActivity keeps one Flutter engine shared with the playback
// service, so music continues when the activity closes.
class MainActivity : AudioServiceActivity() {
    private var library: LibraryChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        library = LibraryChannel(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        library?.dispose()
        library = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
