package com.zemaapp.zema

data class LyricsLine(val atMs: Long?, val text: String)

data class LyricsSheet(
    val key: String,
    val source: String,
    val songId: String?,
    val title: String,
    val artist: String?,
    val lines: List<LyricsLine>,
    val offsetMs: Long,
) {
    val timed: Boolean get() = lines.isNotEmpty() && lines.all { it.atMs != null }

    fun lineAt(positionMs: Long): Int {
        if (!timed) return -1
        var found = -1
        for ((index, line) in lines.withIndex()) {
            if (line.atMs!! > positionMs) break
            found = index
        }
        return found
    }

    companion object {
        fun of(map: Map<*, *>): LyricsSheet? {
            val key = map["key"] as? String ?: return null
            val source = map["source"] as? String ?: return null
            val lines = (map["lines"] as? List<*>).orEmpty().mapNotNull { item ->
                val line = item as? Map<*, *> ?: return@mapNotNull null
                val text = line["text"] as? String ?: return@mapNotNull null
                LyricsLine((line["atMs"] as? Number)?.toLong(), text)
            }
            return LyricsSheet(
                key = key,
                source = source,
                songId = map["songId"] as? String,
                title = map["title"] as? String ?: "",
                artist = map["artist"] as? String,
                lines = if (lines.all { it.atMs != null }) lines.sortedBy { it.atMs } else lines,
                offsetMs = (map["offsetMs"] as? Number)?.toLong() ?: 0,
            )
        }
    }
}

data class PlaybackClock(
    val playing: Boolean,
    val positionMs: Long,
    val updatedAt: Long,
    val speed: Double,
    val durationMs: Long?,
) {
    fun positionAt(now: Long): Long {
        if (!playing) return positionMs
        val moved = positionMs + ((now - updatedAt).coerceAtLeast(0) * speed).toLong()
        return durationMs?.let { minOf(moved, it) } ?: moved
    }

    companion object {
        fun of(event: Map<String, Any?>): PlaybackClock? {
            val position = (event["positionMs"] as? Number)?.toLong() ?: return null
            return PlaybackClock(
                playing = event["playbackState"] == "playing",
                positionMs = position,
                updatedAt = (event["positionUpdatedAt"] as? Number)?.toLong() ?: System.currentTimeMillis(),
                speed = (event["speed"] as? Number)?.toDouble()?.takeIf { it > 0 } ?: 1.0,
                durationMs = (event["durationMs"] as? Number)?.toLong(),
            )
        }
    }
}
