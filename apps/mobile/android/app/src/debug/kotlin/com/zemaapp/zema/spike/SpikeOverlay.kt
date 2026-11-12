package com.zemaapp.zema.spike

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.PixelFormat
import android.graphics.drawable.GradientDrawable
import android.media.session.PlaybackState
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.provider.Settings
import android.util.Log
import android.view.Gravity
import android.view.MotionEvent
import android.view.WindowManager
import android.widget.TextView
import org.json.JSONObject

class SpikeOverlay(private val context: Context) {
    private val windows = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
    private val main = Handler(Looper.getMainLooper())
    private var view: TextView? = null
    private var params: WindowManager.LayoutParams? = null
    private var title = ""
    private var state: PlaybackState? = null

    private val tick = object : Runnable {
        override fun run() {
            render()
            main.postDelayed(this, 250)
        }
    }

    fun show(event: JSONObject, playback: PlaybackState?) {
        if (!Settings.canDrawOverlays(context)) {
            Log.w(SpikeMediaWatchService.TAG, "{\"event\":\"noOverlayPermission\"}")
            return
        }
        title = "${event.optString("title")} · ${event.optString("artist")}\n${event.optString("sourcePackage")}"
        state = playback
        if (view == null) add()
        render()
    }

    fun hide() {
        main.removeCallbacks(tick)
        view?.let { runCatching { windows.removeView(it) } }
        view = null
    }

    @SuppressLint("ClickableViewAccessibility")
    private fun add() {
        val started = SystemClock.elapsedRealtime()
        val text = TextView(context).apply {
            setTextColor(0xFFF3EBDD.toInt())
            textSize = 14f
            setPadding(36, 24, 36, 24)
            background = GradientDrawable().apply {
                cornerRadius = 36f
                setColor(0xE61E1814.toInt())
            }
        }
        val layout = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT,
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = 40
            y = 300
        }
        var downX = 0f
        var downY = 0f
        var startX = 0
        var startY = 0
        text.setOnTouchListener { _, e ->
            when (e.action) {
                MotionEvent.ACTION_DOWN -> {
                    downX = e.rawX; downY = e.rawY; startX = layout.x; startY = layout.y
                }
                MotionEvent.ACTION_MOVE -> {
                    layout.x = startX + (e.rawX - downX).toInt()
                    layout.y = startY + (e.rawY - downY).toInt()
                    windows.updateViewLayout(text, layout)
                }
            }
            true
        }
        windows.addView(text, layout)
        view = text
        params = layout
        main.post(tick)
        Log.i(
            SpikeMediaWatchService.TAG,
            "{\"event\":\"overlayShown\",\"msToAdd\":${SystemClock.elapsedRealtime() - started}}",
        )
    }

    private fun render() {
        val s = state
        val position = when {
            s == null -> 0L
            s.state == PlaybackState.STATE_PLAYING ->
                s.position + ((SystemClock.elapsedRealtime() - s.lastPositionUpdateTime) * s.playbackSpeed).toLong()
            else -> s.position
        }
        val seconds = position / 1000
        val label = when (s?.state) {
            PlaybackState.STATE_PLAYING -> "▶"
            PlaybackState.STATE_PAUSED -> "❚❚"
            else -> "•"
        }
        view?.text = "$title\n$label ${seconds / 60}:${"%02d".format(seconds % 60)}"
    }
}
