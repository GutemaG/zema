package com.zemaapp.zema

import android.annotation.SuppressLint
import android.content.Context
import android.content.SharedPreferences
import android.content.res.ColorStateList
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.graphics.drawable.RippleDrawable
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.provider.Settings
import android.text.TextUtils
import android.util.TypedValue
import android.view.ContextThemeWrapper
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.ViewConfiguration
import android.view.ViewGroup
import android.view.WindowManager
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.SeekBar
import android.widget.TextView
import java.util.Locale
import kotlin.math.hypot
import kotlin.math.roundToInt

@SuppressLint("StaticFieldLeak", "ClickableViewAccessibility")
object LyricsOverlay {
    enum class Mode { BUBBLE, BAR, PANEL }

    private const val PREFS = "zema_overlay"
    private val STARTS = setOf("bubble", "bar", "tap")
    private const val SURFACE = 0xFF1C1613.toInt()
    private const val LINE = 0xFF2F2622.toInt()
    private const val TEXT = 0xFFF2E8D7.toInt()
    private const val MUTED = 0xFFA39586.toInt()
    private const val PRIMARY = 0xFFE3AE4A.toInt()
    private const val TOUCH_THROUGH_ALPHA = 0.8f
    private const val SYNC_STEP_MS = 500L
    private const val FOLLOW_AFTER_SCROLL_MS = 3000L

    private val main = Handler(Looper.getMainLooper())
    private val listeners = LinkedHashSet<(Map<String, Any?>) -> Unit>()
    private lateinit var app: Context
    private lateinit var themed: Context
    private lateinit var windows: WindowManager
    private lateinit var prefs: SharedPreferences

    private var sheet: LyricsSheet? = null
    private var clock: PlaybackClock? = null
    private val givenClocks = mutableMapOf<String, PlaybackClock>()
    private var mode = Mode.BUBBLE
    private var locked = false
    private var suspended = false
    private var root: FrameLayout? = null
    private var params: WindowManager.LayoutParams? = null
    private var handle: View? = null
    private var stopWatching: (() -> Unit)? = null
    private var shownLine = Int.MIN_VALUE
    private var userScrolledAt = 0L

    private var barNow: TextView? = null
    private var barNext: TextView? = null
    private var barLock: ImageView? = null
    private var barButtons: List<View> = emptyList()
    private var panelScroll: ScrollView? = null
    private var panelLines: List<TextView> = emptyList()
    private var syncLabel: TextView? = null

    private val tick = object : Runnable {
        override fun run() {
            render()
            if (clock?.playing == true) main.postDelayed(this, 120)
        }
    }

    fun canShow(context: Context) = Settings.canDrawOverlays(context)

    fun listen(listener: (Map<String, Any?>) -> Unit): () -> Unit {
        listeners.add(listener)
        return { listeners.remove(listener) }
    }

    fun show(context: Context, next: LyricsSheet, start: Mode?): Boolean {
        if (!canShow(context)) return false
        attach(context)
        val previous = sheet
        sheet = next
        if (previous?.source != next.source || stopWatching == null) watch(next.source)
        val wanted = if (next.question && start == Mode.PANEL) Mode.BAR else start
        when {
            previous?.key != next.key || (root == null && !suspended) -> {
                removeHandle()
                locked = false
                mode = wanted ?: startMode()
                build()
            }
            wanted != null && wanted != mode -> switchTo(wanted)
            previous.question != next.question || previous.failed != next.failed ||
                previous.lines != next.lines || previous.title != next.title ||
                previous.artist != next.artist || previous.songId != next.songId -> build()
            else -> {
                showSync()
                shownLine = Int.MIN_VALUE
                render()
            }
        }
        return true
    }

    fun hide() {
        main.removeCallbacks(tick)
        stopWatching?.invoke()
        stopWatching = null
        removeHandle()
        root?.let { runCatching { windows.removeView(it) } }
        root = null
        params = null
        sheet = null
        clock = null
        locked = false
        forgetViews()
    }

    /** The clock of [source] when Android doesn't report it (Zema's own player). */
    fun setClock(source: String, event: Map<String, Any?>) {
        val given = PlaybackClock.of(event) ?: return
        givenClocks[source] = given
        if (sheet?.source != source) return
        clock = given
        main.removeCallbacks(tick)
        tick.run()
    }

    fun setAppInFront(front: Boolean) {
        if (front == suspended) return
        suspended = front
        if (front) {
            main.removeCallbacks(tick)
            removeHandle()
            root?.let { runCatching { windows.removeView(it) } }
            root = null
            locked = false
            forgetViews()
        } else if (sheet != null) {
            build()
        }
    }

    private fun attach(context: Context) {
        if (::app.isInitialized) return
        app = context.applicationContext
        themed = ContextThemeWrapper(app, android.R.style.Theme_DeviceDefault)
        windows = app.getSystemService(Context.WINDOW_SERVICE) as WindowManager
        prefs = app.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
    }

    private fun watch(source: String) {
        stopWatching?.invoke()
        clock = givenClocks[source]
        stopWatching = PlaybackHub.listen { event ->
            if (event["sourcePackage"] != source || sheet?.source != source) return@listen
            if (event["playbackState"] == "gone") {
                hide()
                return@listen
            }
            clock = PlaybackClock.of(event)
            main.removeCallbacks(tick)
            tick.run()
        }
    }

    private fun emit(event: Map<String, Any?>) {
        for (listener in listeners.toList()) listener(event)
    }

    private fun build() {
        if (suspended) return
        val current = sheet ?: return
        forgetViews()
        if (current.question && mode == Mode.PANEL) mode = Mode.BAR
        val content = when {
            mode == Mode.BUBBLE -> bubbleView()
            current.question -> questionView(current)
            mode == Mode.BAR -> barView()
            else -> panelView(current)
        }
        val layout = params ?: WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            0,
            PixelFormat.TRANSLUCENT,
        ).apply { gravity = Gravity.TOP or Gravity.START }
        place(layout)
        val frame = root
        if (frame == null) {
            val made = FrameLayout(themed)
            made.addView(content)
            windows.addView(made, layout)
            root = made
            params = layout
        } else {
            frame.removeAllViews()
            frame.addView(content)
            windows.updateViewLayout(frame, layout)
        }
        shownLine = Int.MIN_VALUE
        main.removeCallbacks(tick)
        tick.run()
    }

    private fun switchTo(next: Mode) {
        removeHandle()
        locked = false
        mode = next
        build()
    }

    private fun close() {
        val key = sheet?.key
        hide()
        emit(mapOf("type" to "closed", "key" to key))
    }

    private fun openApp() {
        val current = sheet ?: return
        runCatching { app.startActivity(LaunchChannel.songIntent(app, current.songId)) }
        emit(mapOf("type" to "open", "key" to current.key, "songId" to current.songId))
    }

    private fun sync(delta: Long) {
        val current = sheet ?: return
        val next = current.copy(offsetMs = current.offsetMs + delta)
        sheet = next
        showSync()
        shownLine = Int.MIN_VALUE
        render()
        emit(mapOf("type" to "offset", "key" to next.key, "offsetMs" to next.offsetMs))
    }

    private fun render() {
        val current = sheet ?: return
        val now = clock
        val position = (now?.positionAt(System.currentTimeMillis()) ?: 0L) + current.offsetMs
        val index = current.lineAt(position)
        val dim = if (now == null || now.playing) 1f else 0.6f
        barNow?.alpha = dim
        barNext?.alpha = dim
        if (index == shownLine) return
        shownLine = index
        val first = barNow
        val second = barNext
        if (first != null && second != null) {
            val (top, bottom) = when {
                current.failed -> current.title to app.getString(R.string.overlay_failed)
                current.lines.isEmpty() -> current.title to app.getString(R.string.overlay_no_lyrics)
                !current.timed -> current.title to app.getString(R.string.overlay_not_synced)
                index < 0 -> "♪ ${current.title}" to current.lines.first().text
                else -> current.lines[index].text to (current.lines.getOrNull(index + 1)?.text ?: "")
            }
            first.text = top
            second.text = bottom
        }
        if (panelLines.isEmpty()) return
        for ((i, view) in panelLines.withIndex()) {
            view.setTextColor(
                when {
                    i == index -> PRIMARY
                    i < index -> MUTED
                    else -> TEXT
                },
            )
            view.setTypeface(null, if (i == index) Typeface.BOLD else Typeface.NORMAL)
        }
        val scroll = panelScroll ?: return
        val target = panelLines.getOrNull(index) ?: return
        if (SystemClock.uptimeMillis() - userScrolledAt < FOLLOW_AFTER_SCROLL_MS) return
        scroll.post {
            scroll.smoothScrollTo(0, (target.top - (scroll.height - target.height) / 2).coerceAtLeast(0))
        }
    }

    private fun place(p: WindowManager.LayoutParams) {
        val screen = app.resources.displayMetrics
        val w = screen.widthPixels
        val h = screen.heightPixels
        when (mode) {
            Mode.BUBBLE -> {
                p.width = WindowManager.LayoutParams.WRAP_CONTENT
                p.height = WindowManager.LayoutParams.WRAP_CONTENT
                p.x = prefs.getInt("bubble_x", w - dp(72))
                p.y = prefs.getInt("bubble_y", h / 3)
            }
            Mode.BAR -> {
                p.width = minOf(w - dp(24), dp(520))
                p.height = WindowManager.LayoutParams.WRAP_CONTENT
                p.x = prefs.getInt("bar_x", (w - p.width) / 2)
                p.y = prefs.getInt("bar_y", h - dp(240))
            }
            Mode.PANEL -> {
                p.width = prefs.getInt("panel_w", minOf(w - dp(24), dp(420))).coerceIn(dp(240), w)
                p.height = prefs.getInt("panel_h", h / 2).coerceIn(dp(220), h)
                p.x = prefs.getInt("panel_x", (w - p.width) / 2)
                p.y = prefs.getInt("panel_y", h / 4)
            }
        }
        applyTouch(p)
        clamp(
            p,
            width = if (p.width > 0) p.width else dp(56),
            height = if (p.height > 0) p.height else if (mode == Mode.BAR) dp(96) else dp(56),
        )
    }

    private fun applyTouch(p: WindowManager.LayoutParams) {
        p.flags = WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
            WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS or
            (if (locked) WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE else 0)
        p.alpha = if (locked) minOf(opacity(), TOUCH_THROUGH_ALPHA) else opacity()
    }

    private fun clamp(
        p: WindowManager.LayoutParams,
        width: Int = root?.width ?: 0,
        height: Int = root?.height ?: 0,
    ) {
        val screen = app.resources.displayMetrics
        p.x = p.x.coerceIn(0, maxOf(0, screen.widthPixels - width))
        p.y = p.y.coerceIn(0, maxOf(0, screen.heightPixels - height))
    }

    private fun setLocked(on: Boolean) {
        val p = params ?: return
        val frame = root ?: return
        locked = on
        for (button in barButtons) button.visibility = if (on) View.GONE else View.VISIBLE
        barLock?.visibility = if (on) View.INVISIBLE else View.VISIBLE
        applyTouch(p)
        windows.updateViewLayout(frame, p)
        if (on) frame.post { showHandle() } else removeHandle()
    }

    private fun showHandle() {
        val lock = barLock ?: return
        val p = params ?: return
        val frame = root ?: return
        if (!locked || handle != null) return
        val at = IntArray(2)
        val origin = IntArray(2)
        lock.getLocationOnScreen(at)
        frame.getLocationOnScreen(origin)
        val view = icon(R.drawable.ic_overlay_lock, R.string.overlay_unlock, PRIMARY) { setLocked(false) }
        view.background = GradientDrawable().apply {
            shape = GradientDrawable.OVAL
            setColor(SURFACE)
        }
        val layout = WindowManager.LayoutParams(
            lock.width,
            lock.height,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT,
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = p.x + at[0] - origin[0]
            y = p.y + at[1] - origin[1]
        }
        windows.addView(view, layout)
        handle = view
    }

    private fun removeHandle() {
        handle?.let { runCatching { windows.removeView(it) } }
        handle = null
    }

    private fun forgetViews() {
        barNow = null
        barNext = null
        barLock = null
        barButtons = emptyList()
        panelScroll = null
        panelLines = emptyList()
        syncLabel = null
    }

    private fun bubbleView(): View = ImageView(themed).apply {
        val size = dp(52)
        layoutParams = FrameLayout.LayoutParams(size, size)
        setImageResource(R.drawable.ic_overlay_note)
        imageTintList = ColorStateList.valueOf(PRIMARY)
        setPadding(dp(13), dp(13), dp(13), dp(13))
        background = GradientDrawable().apply {
            shape = GradientDrawable.OVAL
            setColor(SURFACE)
            setStroke(dp(2), PRIMARY)
        }
        contentDescription = app.getString(R.string.overlay_show)
        setOnClickListener { switchTo(Mode.BAR) }
        draggable(this, "bubble")
    }

    private fun barView(): View {
        val size = textSp()
        val now = text(size, TEXT, bold = true).apply {
            maxLines = 2
            ellipsize = TextUtils.TruncateAt.END
        }
        val next = text(size * 0.78f, MUTED).apply {
            maxLines = 1
            ellipsize = TextUtils.TruncateAt.END
        }
        val words = LinearLayout(themed).apply {
            orientation = LinearLayout.VERTICAL
            layoutParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f)
            addView(now)
            addView(next)
        }
        draggable(words, "bar")
        val lock = icon(R.drawable.ic_overlay_lock_open, R.string.overlay_lock) { setLocked(true) }
        val expand = icon(R.drawable.ic_overlay_expand, R.string.overlay_expand) { switchTo(Mode.PANEL) }
        val close = icon(R.drawable.ic_overlay_close, R.string.overlay_close) { close() }
        barNow = now
        barNext = next
        barLock = lock
        barButtons = listOf(expand, close)
        return LinearLayout(themed).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            background = card()
            setPadding(dp(16), dp(10), dp(6), dp(10))
            addView(words)
            addView(lock)
            addView(expand)
            addView(close)
        }
    }

    private fun panelView(current: LyricsSheet): View {
        val size = textSp()
        val title = text(13f, MUTED).apply {
            text = listOfNotNull(current.title.ifEmpty { null }, current.artist).joinToString(" · ")
            maxLines = 1
            ellipsize = TextUtils.TruncateAt.END
            layoutParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f)
        }
        val header = row(
            title,
            icon(R.drawable.ic_overlay_minimize, R.string.overlay_minimize) { switchTo(Mode.BUBBLE) },
            icon(R.drawable.ic_overlay_collapse, R.string.overlay_collapse) { switchTo(Mode.BAR) },
            icon(R.drawable.ic_overlay_close, R.string.overlay_close) { close() },
        )
        draggable(header, "panel")

        val lineViews = if (current.lines.isEmpty()) {
            val note = if (current.failed) R.string.overlay_failed else R.string.overlay_no_lyrics
            listOf(text(size, MUTED).apply { text = app.getString(note) })
        } else {
            current.lines.map { line ->
                text(size, TEXT).apply {
                    text = line.text
                    setPadding(0, dp(5), 0, dp(5))
                }
            }
        }
        val column = LinearLayout(themed).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(4), dp(8), dp(4), dp(8))
            for (view in lineViews) addView(view)
        }
        val scroll = ScrollView(themed).apply {
            isVerticalScrollBarEnabled = false
            layoutParams = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 0, 1f)
            addView(column)
            setOnTouchListener { _, _ ->
                userScrolledAt = SystemClock.uptimeMillis()
                false
            }
        }
        panelScroll = scroll
        panelLines = if (current.timed) lineViews else emptyList()

        val opacity = SeekBar(themed).apply {
            max = 60
            progress = ((opacity() * 100).roundToInt() - 40).coerceIn(0, 60)
            progressTintList = ColorStateList.valueOf(PRIMARY)
            thumbTintList = ColorStateList.valueOf(PRIMARY)
            contentDescription = app.getString(R.string.overlay_opacity)
            layoutParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f)
            setOnSeekBarChangeListener(object : SeekBar.OnSeekBarChangeListener {
                override fun onProgressChanged(bar: SeekBar, value: Int, fromUser: Boolean) {
                    if (!fromUser) return
                    prefs.edit().putFloat("opacity", (value + 40) / 100f).apply()
                    val p = params ?: return
                    applyTouch(p)
                    root?.let { windows.updateViewLayout(it, p) }
                }

                override fun onStartTrackingTouch(bar: SeekBar) {}

                override fun onStopTrackingTouch(bar: SeekBar) {}
            })
        }
        val looks = row(
            chip("A−", R.string.overlay_text_smaller) { textSize(-2f) },
            chip("A+", R.string.overlay_text_bigger) { textSize(2f) },
            opacity,
        )

        val label = text(12f, MUTED).apply {
            gravity = Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f)
        }
        syncLabel = label
        val later = chip("−0.5", R.string.overlay_sync_later) { sync(-SYNC_STEP_MS) }
        val earlier = chip("+0.5", R.string.overlay_sync_earlier) { sync(SYNC_STEP_MS) }
        if (!current.timed) {
            later.visibility = View.GONE
            earlier.visibility = View.GONE
            label.visibility = View.INVISIBLE
        }
        val resize = icon(R.drawable.ic_overlay_resize, R.string.overlay_resize, MUTED) {}
        resizable(resize)
        val actions = row(
            later,
            label,
            earlier,
            icon(R.drawable.ic_overlay_open, R.string.overlay_open_app) { openApp() },
            resize,
        )
        showSync()

        return LinearLayout(themed).apply {
            orientation = LinearLayout.VERTICAL
            background = card()
            setPadding(dp(14), dp(6), dp(6), dp(4))
            layoutParams = FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT,
            )
            addView(header)
            addView(scroll)
            addView(looks)
            addView(actions)
        }
    }

    private fun questionView(current: LyricsSheet): View {
        val ask = text(13f, MUTED).apply {
            text = app.getString(R.string.overlay_question)
            layoutParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f)
        }
        val header = row(
            ask,
            icon(R.drawable.ic_listen_mic, R.string.overlay_listen) { askInApp("listen") },
            icon(R.drawable.ic_overlay_close, R.string.overlay_close) { close() },
        )
        draggable(header, "bar")
        val title = text(textSp(), TEXT, bold = true).apply {
            text = current.title
            maxLines = 2
            ellipsize = TextUtils.TruncateAt.END
        }
        val artist = text(14f, MUTED).apply {
            text = current.artist.orEmpty()
            visibility = if (current.artist.isNullOrEmpty()) View.GONE else View.VISIBLE
        }
        val answers = row(
            chip(app.getString(R.string.overlay_yes), R.string.overlay_yes, primary = true) { confirm() },
            chip(app.getString(R.string.overlay_choose), R.string.overlay_choose) { askInApp("choose") },
            chip(app.getString(R.string.overlay_not_mezmur), R.string.overlay_not_mezmur) { notMezmur() },
        ).apply { setPadding(0, dp(8), 0, dp(2)) }
        return LinearLayout(themed).apply {
            orientation = LinearLayout.VERTICAL
            background = card()
            setPadding(dp(16), dp(4), dp(6), dp(10))
            addView(header)
            addView(title)
            addView(artist)
            addView(answers)
        }
    }

    private fun confirm() {
        val current = sheet ?: return
        emit(mapOf("type" to "confirm", "key" to current.key, "songId" to current.songId))
    }

    private fun notMezmur() {
        val key = sheet?.key ?: return
        hide()
        emit(mapOf("type" to "notMezmur", "key" to key))
    }

    private fun askInApp(ask: String) {
        val current = sheet ?: return
        runCatching { app.startActivity(LaunchChannel.detectedIntent(app, current.key, ask)) }
        switchTo(Mode.BUBBLE)
    }

    private fun showSync() {
        val offset = sheet?.offsetMs ?: return
        syncLabel?.text = app.getString(
            R.string.overlay_sync,
            String.format(Locale.US, "%+.1f", offset / 1000.0),
        )
    }

    private fun textSize(delta: Float) {
        prefs.edit().putFloat("text_sp", (textSp() + delta).coerceIn(12f, 30f)).apply()
        build()
    }

    fun appearance(context: Context): Map<String, Any> {
        attach(context)
        return mapOf(
            "textSp" to textSp().toDouble(),
            "opacity" to opacity().toDouble(),
            "start" to start(),
        )
    }

    fun setAppearance(context: Context, textSp: Float?, opacity: Float?, start: String?) {
        attach(context)
        prefs.edit().apply {
            textSp?.let { putFloat("text_sp", it.coerceIn(12f, 30f)) }
            opacity?.let { putFloat("opacity", it.coerceIn(0.4f, 1f)) }
            start?.takeIf { it in STARTS }?.let { putString("start", it) }
        }.apply()
        if (root != null) build()
    }

    fun onTapOnly(context: Context): Boolean {
        attach(context)
        return start() == "tap"
    }

    private fun start() = prefs.getString("start", null)?.takeIf { it in STARTS } ?: "bubble"

    private fun startMode() = if (start() == "bar") Mode.BAR else Mode.BUBBLE

    private fun textSp() = prefs.getFloat("text_sp", 18f)

    private fun opacity() = prefs.getFloat("opacity", 1f)

    private fun draggable(view: View, name: String) {
        val slop = ViewConfiguration.get(app).scaledTouchSlop
        var downX = 0f
        var downY = 0f
        var startX = 0
        var startY = 0
        var dragging = false
        view.setOnTouchListener { v, e ->
            val p = params ?: return@setOnTouchListener false
            when (e.actionMasked) {
                MotionEvent.ACTION_DOWN -> {
                    downX = e.rawX
                    downY = e.rawY
                    startX = p.x
                    startY = p.y
                    dragging = false
                }
                MotionEvent.ACTION_MOVE -> {
                    val dx = e.rawX - downX
                    val dy = e.rawY - downY
                    if (!dragging && hypot(dx, dy) > slop) dragging = true
                    if (dragging) {
                        p.x = startX + dx.toInt()
                        p.y = startY + dy.toInt()
                        clamp(p)
                        root?.let { windows.updateViewLayout(it, p) }
                    }
                }
                MotionEvent.ACTION_UP -> {
                    if (dragging) {
                        prefs.edit().putInt("${name}_x", p.x).putInt("${name}_y", p.y).apply()
                    } else {
                        v.performClick()
                    }
                }
            }
            true
        }
    }

    private fun resizable(view: View) {
        var downX = 0f
        var downY = 0f
        var startW = 0
        var startH = 0
        view.setOnTouchListener { _, e ->
            val p = params ?: return@setOnTouchListener false
            val screen = app.resources.displayMetrics
            when (e.actionMasked) {
                MotionEvent.ACTION_DOWN -> {
                    downX = e.rawX
                    downY = e.rawY
                    startW = p.width
                    startH = p.height
                }
                MotionEvent.ACTION_MOVE -> {
                    p.width = (startW + (e.rawX - downX).toInt())
                        .coerceIn(dp(240), maxOf(dp(240), screen.widthPixels - p.x))
                    p.height = (startH + (e.rawY - downY).toInt())
                        .coerceIn(dp(220), maxOf(dp(220), screen.heightPixels - p.y))
                    root?.let { windows.updateViewLayout(it, p) }
                }
                MotionEvent.ACTION_UP ->
                    prefs.edit().putInt("panel_w", p.width).putInt("panel_h", p.height).apply()
            }
            true
        }
    }

    private fun text(sp: Float, color: Int, bold: Boolean = false) = TextView(themed).apply {
        setTextSize(TypedValue.COMPLEX_UNIT_SP, sp)
        setTextColor(color)
        if (bold) setTypeface(typeface, Typeface.BOLD)
    }

    private fun icon(res: Int, label: Int, tint: Int = TEXT, onTap: () -> Unit) = ImageView(themed).apply {
        val size = dp(40)
        layoutParams = LinearLayout.LayoutParams(size, size)
        setImageResource(res)
        imageTintList = ColorStateList.valueOf(tint)
        setPadding(dp(9), dp(9), dp(9), dp(9))
        background = RippleDrawable(ColorStateList.valueOf(0x33FFFFFF), null, null)
        contentDescription = app.getString(label)
        setOnClickListener { onTap() }
    }

    private fun chip(
        label: String,
        description: Int,
        primary: Boolean = false,
        onTap: () -> Unit,
    ) = TextView(themed).apply {
        text = label
        setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
        setTextColor(if (primary) SURFACE else TEXT)
        if (primary) setTypeface(typeface, Typeface.BOLD)
        gravity = Gravity.CENTER
        minWidth = dp(44)
        setPadding(dp(10), dp(6), dp(10), dp(6))
        background = GradientDrawable().apply {
            cornerRadius = dp(14).toFloat()
            setColor(if (primary) PRIMARY else LINE)
        }
        layoutParams = LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.WRAP_CONTENT,
            ViewGroup.LayoutParams.WRAP_CONTENT,
        ).apply { marginEnd = dp(6) }
        contentDescription = app.getString(description)
        setOnClickListener { onTap() }
    }

    private fun row(vararg views: View) = LinearLayout(themed).apply {
        orientation = LinearLayout.HORIZONTAL
        gravity = Gravity.CENTER_VERTICAL
        setPadding(0, dp(2), 0, dp(2))
        for (view in views) addView(view)
    }

    private fun card() = GradientDrawable().apply {
        cornerRadius = dp(18).toFloat()
        setColor(SURFACE)
        setStroke(dp(1), LINE)
    }

    private fun dp(value: Number) = (value.toFloat() * app.resources.displayMetrics.density).roundToInt()
}
