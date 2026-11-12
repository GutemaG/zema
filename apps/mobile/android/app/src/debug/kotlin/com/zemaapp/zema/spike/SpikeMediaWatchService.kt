package com.zemaapp.zema.spike

import android.content.ComponentName
import android.content.Context
import android.media.MediaMetadata
import android.media.session.MediaController
import android.media.session.MediaSessionManager
import android.media.session.PlaybackState
import android.os.Handler
import android.os.Looper
import android.os.Process
import android.os.SystemClock
import android.service.notification.NotificationListenerService
import android.util.Log
import org.json.JSONObject
import java.io.File

class SpikeMediaWatchService : NotificationListenerService() {
    private val main = Handler(Looper.getMainLooper())
    private val callbacks = mutableMapOf<MediaController, MediaController.Callback>()
    private var sessions: MediaSessionManager? = null
    private val overlay by lazy { SpikeOverlay(this) }

    private val changed = MediaSessionManager.OnActiveSessionsChangedListener { list ->
        attach(list ?: emptyList())
    }

    override fun onCreate() {
        super.onCreate()
        val sinceStart = SystemClock.elapsedRealtime() - Process.getStartElapsedRealtime()
        record(JSONObject().put("event", "serviceCreated").put("pid", Process.myPid()).put("msSinceProcessStart", sinceStart))
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        val manager = getSystemService(Context.MEDIA_SESSION_SERVICE) as MediaSessionManager
        sessions = manager
        val me = ComponentName(this, SpikeMediaWatchService::class.java)
        manager.addOnActiveSessionsChangedListener(changed, me, main)
        record(JSONObject().put("event", "listenerConnected"))
        attach(manager.getActiveSessions(me))
    }

    override fun onListenerDisconnected() {
        record(JSONObject().put("event", "listenerDisconnected"))
        sessions?.removeOnActiveSessionsChangedListener(changed)
        detachAll()
        requestRebind(ComponentName(this, SpikeMediaWatchService::class.java))
        super.onListenerDisconnected()
    }

    override fun onDestroy() {
        detachAll()
        overlay.hide()
        super.onDestroy()
    }

    private fun attach(controllers: List<MediaController>) {
        detachAll()
        for (controller in controllers) {
            if (controller.packageName == packageName) continue
            val callback = object : MediaController.Callback() {
                override fun onMetadataChanged(metadata: MediaMetadata?) = emit(controller)
                override fun onPlaybackStateChanged(state: PlaybackState?) = emit(controller)
            }
            controller.registerCallback(callback, main)
            callbacks[controller] = callback
            emit(controller)
        }
    }

    private fun detachAll() {
        for ((controller, callback) in callbacks) controller.unregisterCallback(callback)
        callbacks.clear()
    }

    private fun emit(controller: MediaController) {
        val metadata = controller.metadata
        val state = controller.playbackState
        val event = JSONObject()
            .put("sourcePackage", controller.packageName)
            .put("title", metadata?.getString(MediaMetadata.METADATA_KEY_TITLE))
            .put("artist", metadata?.getString(MediaMetadata.METADATA_KEY_ARTIST))
            .put("displaySubtitle", metadata?.getString(MediaMetadata.METADATA_KEY_DISPLAY_SUBTITLE))
            .put("album", metadata?.getString(MediaMetadata.METADATA_KEY_ALBUM))
            .put("mediaId", metadata?.getString(MediaMetadata.METADATA_KEY_MEDIA_ID))
            .put("mediaUri", metadata?.getString(MediaMetadata.METADATA_KEY_MEDIA_URI))
            .put("durationMs", metadata?.getLong(MediaMetadata.METADATA_KEY_DURATION))
            .put("positionMs", state?.position)
            .put("speed", state?.playbackSpeed?.toDouble())
            .put("positionUpdatedAtElapsed", state?.lastPositionUpdateTime)
            .put("positionUpdatedAt", state?.let {
                System.currentTimeMillis() - (SystemClock.elapsedRealtime() - it.lastPositionUpdateTime)
            })
            .put("playbackState", when (state?.state) {
                PlaybackState.STATE_PLAYING -> "playing"
                PlaybackState.STATE_PAUSED -> "paused"
                PlaybackState.STATE_BUFFERING -> "buffering"
                PlaybackState.STATE_STOPPED -> "stopped"
                null -> null
                else -> "other(${state.state})"
            })
        record(event)
        overlay.show(event, state)
    }

    private fun record(event: JSONObject) {
        event.put("at", System.currentTimeMillis())
        Log.i(TAG, event.toString())
        runCatching { File(filesDir, "spike_events.jsonl").appendText(event.toString() + "\n") }
    }

    companion object {
        const val TAG = "ZemaSpike"
    }
}
