package com.zemaapp.zema

import android.content.ComponentName
import android.content.Context
import android.media.MediaMetadata
import android.media.session.MediaController
import android.media.session.MediaSessionManager
import android.media.session.PlaybackState
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.service.notification.NotificationListenerService

class MediaWatchService : NotificationListenerService() {
    private val main = Handler(Looper.getMainLooper())
    private val callbacks = mutableMapOf<MediaController, MediaController.Callback>()
    private var sessions: MediaSessionManager? = null

    private val changed = MediaSessionManager.OnActiveSessionsChangedListener { list ->
        attach(list ?: emptyList())
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        val manager = getSystemService(Context.MEDIA_SESSION_SERVICE) as MediaSessionManager
        sessions = manager
        manager.addOnActiveSessionsChangedListener(changed, component(this), main)
        PlaybackHub.onSourcesChanged = { refresh() }
        OverlayEngine.watch(this)
        refresh()
    }

    override fun onListenerDisconnected() {
        stop()
        requestRebind(component(this))
        super.onListenerDisconnected()
    }

    override fun onDestroy() {
        stop()
        super.onDestroy()
    }

    private fun stop() {
        sessions?.removeOnActiveSessionsChangedListener(changed)
        sessions = null
        PlaybackHub.onSourcesChanged = null
        OverlayEngine.unwatch()
        detachAll()
        for (source in PlaybackHub.active()) PlaybackHub.gone(source)
    }

    private fun refresh() {
        val manager = sessions ?: return
        attach(runCatching { manager.getActiveSessions(component(this)) }.getOrDefault(emptyList()))
    }

    private fun attach(controllers: List<MediaController>) {
        detachAll()
        val sources = PlaybackHub.watched(this)
        val seen = mutableSetOf<String>()
        for (controller in controllers) {
            val source = controller.packageName
            if (source !in sources || !seen.add(source)) continue
            val callback = object : MediaController.Callback() {
                override fun onMetadataChanged(metadata: MediaMetadata?) = emit(controller)
                override fun onPlaybackStateChanged(state: PlaybackState?) = emit(controller)
                override fun onSessionDestroyed() = PlaybackHub.gone(source)
            }
            controller.registerCallback(callback, main)
            callbacks[controller] = callback
            emit(controller)
        }
        for (source in PlaybackHub.active() - seen) PlaybackHub.gone(source)
    }

    private fun detachAll() {
        for ((controller, callback) in callbacks) controller.unregisterCallback(callback)
        callbacks.clear()
    }

    private fun emit(controller: MediaController) {
        PlaybackHub.publish(eventOf(controller.packageName, controller.metadata, controller.playbackState))
    }

    companion object {
        fun component(context: Context) = ComponentName(context, MediaWatchService::class.java)

        fun eventOf(source: String, metadata: MediaMetadata?, state: PlaybackState?): Map<String, Any?> {
            val duration = metadata?.getLong(MediaMetadata.METADATA_KEY_DURATION) ?: 0
            return mapOf(
                "sourcePackage" to source,
                "title" to metadata?.getString(MediaMetadata.METADATA_KEY_TITLE),
                "artist" to (metadata?.getString(MediaMetadata.METADATA_KEY_ARTIST)
                    ?: metadata?.getString(MediaMetadata.METADATA_KEY_DISPLAY_SUBTITLE)),
                "mediaId" to metadata?.getString(MediaMetadata.METADATA_KEY_MEDIA_ID)?.ifEmpty { null },
                "durationMs" to duration.takeIf { it > 0 },
                "positionMs" to state?.position?.takeIf { it >= 0 },
                "positionUpdatedAt" to state?.let {
                    System.currentTimeMillis() - (SystemClock.elapsedRealtime() - it.lastPositionUpdateTime)
                },
                "speed" to state?.playbackSpeed?.toDouble(),
                "playbackState" to when (state?.state) {
                    PlaybackState.STATE_PLAYING -> "playing"
                    PlaybackState.STATE_PAUSED -> "paused"
                    PlaybackState.STATE_BUFFERING,
                    PlaybackState.STATE_CONNECTING,
                    PlaybackState.STATE_FAST_FORWARDING,
                    PlaybackState.STATE_REWINDING,
                    PlaybackState.STATE_SKIPPING_TO_NEXT,
                    PlaybackState.STATE_SKIPPING_TO_PREVIOUS,
                    PlaybackState.STATE_SKIPPING_TO_QUEUE_ITEM -> "buffering"
                    else -> "stopped"
                },
            )
        }
    }
}
