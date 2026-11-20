package com.zemaapp.zema

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.os.PowerManager

/**
 * Keep listening (intent 010 FR-1): holds the microphone with the screen off
 * while Dart records in bursts. It only shows the notification and keeps the
 * CPU awake; it never restarts by itself.
 */
class KeepListeningService : Service() {
    private var wakeLock: PowerManager.WakeLock? = null
    private var stopLabel = ""

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> start(intent)
            ACTION_SHOW -> notify(intent)
            ACTION_STOP_TAPPED -> {
                onStopTapped?.invoke()
                finish()
            }
            else -> finish()
        }
        return START_NOT_STICKY
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        onStopTapped?.invoke()
        finish()
    }

    override fun onDestroy() {
        releaseWakeLock()
        running = false
        super.onDestroy()
    }

    private fun start(intent: Intent) {
        stopLabel = intent.getStringExtra(EXTRA_STOP) ?: ""
        createChannel(this)
        val notification = notification(intent)
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                startForeground(ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE)
            } else {
                startForeground(ID, notification)
            }
        } catch (_: RuntimeException) {
            onStopTapped?.invoke()
            finish()
            return
        }
        running = true
        val length = intent.getLongExtra(EXTRA_LENGTH_MS, 0)
        releaseWakeLock()
        wakeLock = (getSystemService(Context.POWER_SERVICE) as PowerManager)
            .newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "zema:keep-listening")
            .apply { acquire(length + 60_000) }
    }

    private fun notify(intent: Intent) {
        if (!running) return
        manager(this).notify(ID, notification(intent))
    }

    private fun notification(intent: Intent): Notification {
        val open = PendingIntent.getActivity(
            this, 0, LaunchChannel.keepListeningIntent(this),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val stop = PendingIntent.getService(
            this, 1,
            Intent(this, KeepListeningService::class.java).setAction(ACTION_STOP_TAPPED),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        return builder(this)
            .setSmallIcon(R.drawable.ic_listen_mic)
            .setContentTitle(intent.getStringExtra(EXTRA_TITLE))
            .setContentText(intent.getStringExtra(EXTRA_TEXT))
            .setContentIntent(open)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setShowWhen(false)
            .setCategory(Notification.CATEGORY_SERVICE)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .addAction(Notification.Action.Builder(null, stopLabel, stop).build())
            .build()
    }

    private fun finish() {
        running = false
        releaseWakeLock()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        stopSelf()
    }

    private fun releaseWakeLock() {
        wakeLock?.let { if (it.isHeld) it.release() }
        wakeLock = null
    }

    companion object {
        private const val ID = 4107
        private const val ENDED_ID = 4108
        private const val CHANNEL = "keep_listening"
        private const val ACTION_START = "com.zemaapp.zema.KEEP_LISTENING_START"
        private const val ACTION_SHOW = "com.zemaapp.zema.KEEP_LISTENING_SHOW"
        private const val ACTION_STOP_TAPPED = "com.zemaapp.zema.KEEP_LISTENING_STOP"
        private const val EXTRA_TITLE = "title"
        private const val EXTRA_TEXT = "text"
        private const val EXTRA_STOP = "stop"
        private const val EXTRA_LENGTH_MS = "lengthMs"

        @Volatile
        private var running = false

        /** Stop tapped, or the app closed from Recents: Dart ends Keep listening. */
        var onStopTapped: (() -> Unit)? = null

        fun start(context: Context, title: String?, text: String?, stop: String?, lengthMs: Long) {
            manager(context).cancel(ENDED_ID)
            val intent = Intent(context, KeepListeningService::class.java)
                .setAction(ACTION_START)
                .putExtra(EXTRA_TITLE, title)
                .putExtra(EXTRA_TEXT, text)
                .putExtra(EXTRA_STOP, stop)
                .putExtra(EXTRA_LENGTH_MS, lengthMs)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun show(context: Context, title: String?, text: String?) {
            if (!running) return
            context.startService(
                Intent(context, KeepListeningService::class.java)
                    .setAction(ACTION_SHOW)
                    .putExtra(EXTRA_TITLE, title)
                    .putExtra(EXTRA_TEXT, text),
            )
        }

        /** Stops the service; [why], when given, stays as a plain notification. */
        fun stop(context: Context, why: String?) {
            context.stopService(Intent(context, KeepListeningService::class.java))
            if (why == null) return
            createChannel(context)
            val open = PendingIntent.getActivity(
                context, 2, LaunchChannel.keepListeningIntent(context),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            manager(context).notify(
                ENDED_ID,
                builder(context)
                    .setSmallIcon(R.drawable.ic_listen_mic)
                    .setContentTitle(why)
                    .setContentIntent(open)
                    .setAutoCancel(true)
                    .build(),
            )
        }

        private fun manager(context: Context) =
            context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        private fun createChannel(context: Context) {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
            manager(context).createNotificationChannel(
                NotificationChannel(
                    CHANNEL,
                    context.getString(R.string.keep_listening_channel),
                    NotificationManager.IMPORTANCE_LOW,
                ),
            )
        }

        private fun builder(context: Context): Notification.Builder =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                Notification.Builder(context, CHANNEL)
            } else {
                @Suppress("DEPRECATION")
                Notification.Builder(context)
            }
    }
}
