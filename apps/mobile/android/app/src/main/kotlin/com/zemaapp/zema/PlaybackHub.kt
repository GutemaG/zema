package com.zemaapp.zema

import android.content.Context

object PlaybackHub {
    private const val PREFS = "zema_detection"
    private const val SOURCES = "sources"

    val defaultSources = setOf(
        "com.google.android.youtube",
        "com.google.android.apps.youtube.music",
        "org.telegram.messenger",
        "org.telegram.messenger.web",
        "org.thunderdog.challegram",
    )

    private val latest = LinkedHashMap<String, Map<String, Any?>>()
    private val listeners = LinkedHashSet<(Map<String, Any?>) -> Unit>()
    var onSourcesChanged: (() -> Unit)? = null

    fun sources(context: Context): Set<String> =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getStringSet(SOURCES, null)?.toSet() ?: defaultSources

    fun setSources(context: Context, sources: Set<String>) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit().putStringSet(SOURCES, sources).apply()
        for (source in latest.keys.filter { it !in sources }) gone(source)
        onSourcesChanged?.invoke()
    }

    fun publish(event: Map<String, Any?>) {
        val source = event["sourcePackage"] as? String ?: return
        if (latest[source] == event) return
        latest[source] = event
        for (listener in listeners.toList()) listener(event)
    }

    fun gone(source: String) {
        if (latest.remove(source) == null) return
        val event = mapOf("sourcePackage" to source, "playbackState" to "gone")
        for (listener in listeners.toList()) listener(event)
    }

    fun active(): Set<String> = latest.keys.toSet()

    fun anyPlaying(): Boolean = latest.values.any { it["playbackState"] == "playing" }

    fun listen(listener: (Map<String, Any?>) -> Unit): () -> Unit {
        listeners.add(listener)
        for (event in latest.values.toList()) listener(event)
        return { listeners.remove(listener) }
    }
}
