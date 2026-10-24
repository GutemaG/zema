package com.zemaapp.zema

import android.Manifest
import android.content.ContentUris
import android.content.Context
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import android.util.Log
import android.util.Size
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.FileNotFoundException
import java.util.concurrent.Executors

/**
 * Reads local audio files from MediaStore for the Dart `MediaStoreLibraryScanner`.
 *
 * Methods:
 * - `scan` → list of maps, one per audio file (see [readRow] for the keys)
 * - `loadArtwork` {id, size} → JPEG bytes or null
 * - `sdkInt` → the Android API level (picks the right audio permission)
 *
 * Errors: `permission_denied` when audio access is missing, `scan_failed` otherwise.
 * Work runs on a background thread; results are posted back on the main thread.
 */
class LibraryChannel(private val context: Context, messenger: BinaryMessenger) :
    MethodChannel.MethodCallHandler {

    private val channel = MethodChannel(messenger, NAME)
    private val executor = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    init {
        channel.setMethodCallHandler(this)
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        executor.shutdown()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "scan" -> runInBackground(result) { scan() }
            "loadArtwork" -> {
                val id = call.argument<Number>("id")?.toLong()
                val size = call.argument<Number>("size")?.toInt() ?: 200
                if (id == null) {
                    result.error("bad_args", "loadArtwork needs an id", null)
                } else {
                    runInBackground(result) { loadArtwork(id, size) }
                }
            }
            "sdkInt" -> result.success(Build.VERSION.SDK_INT)
            else -> result.notImplemented()
        }
    }

    private fun runInBackground(result: MethodChannel.Result, work: () -> Any?) {
        executor.execute {
            try {
                val value = work()
                main.post { result.success(value) }
            } catch (e: PermissionMissing) {
                main.post { result.error("permission_denied", e.message, null) }
            } catch (e: Exception) {
                Log.w(TAG, "Library call failed", e)
                main.post { result.error("scan_failed", e.message, null) }
            }
        }
    }

    private fun hasAudioAccess(): Boolean {
        val permission = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            Manifest.permission.READ_MEDIA_AUDIO
        } else {
            Manifest.permission.READ_EXTERNAL_STORAGE
        }
        return context.checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED
    }

    private fun collection(): Uri =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            MediaStore.Audio.Media.getContentUri(MediaStore.VOLUME_EXTERNAL)
        } else {
            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
        }

    private fun scan(): List<Map<String, Any?>> {
        if (!hasAudioAccess()) throw PermissionMissing()

        val columns = mutableListOf(
            MediaStore.Audio.Media._ID,
            MediaStore.Audio.Media.DATA,
            MediaStore.Audio.Media.DISPLAY_NAME,
            MediaStore.Audio.Media.TITLE,
            MediaStore.Audio.Media.ARTIST,
            MediaStore.Audio.Media.ALBUM,
            MediaStore.Audio.Media.TRACK,
            MediaStore.Audio.Media.YEAR,
            MediaStore.Audio.Media.DURATION,
            MediaStore.Audio.Media.SIZE,
            MediaStore.Audio.Media.DATE_ADDED,
            // Not a public constant before API 30, but the column exists since API 1.
            "album_artist",
        )
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            columns += MediaStore.Audio.Media.RELATIVE_PATH
        }
        // System sounds are not music; everything else is filtered in Dart.
        val selection = "${MediaStore.Audio.Media.IS_ALARM} = 0 AND " +
            "${MediaStore.Audio.Media.IS_RINGTONE} = 0 AND " +
            "${MediaStore.Audio.Media.IS_NOTIFICATION} = 0"

        val rows = mutableListOf<Map<String, Any?>>()
        val started = System.currentTimeMillis()
        context.contentResolver.query(
            collection(), columns.toTypedArray(), selection, null, null,
        )?.use { cursor ->
            while (cursor.moveToNext()) {
                readRow(cursor)?.let(rows::add)
            }
        } ?: throw IllegalStateException("MediaStore query returned no cursor")
        Log.i(TAG, "Scanned ${rows.size} audio files in ${System.currentTimeMillis() - started} ms")
        return rows
    }

    private fun readRow(cursor: android.database.Cursor): Map<String, Any?>? {
        fun string(column: String): String? {
            val index = cursor.getColumnIndex(column)
            return if (index < 0 || cursor.isNull(index)) null else cursor.getString(index)
        }
        fun long(column: String): Long? {
            val index = cursor.getColumnIndex(column)
            return if (index < 0 || cursor.isNull(index)) null else cursor.getLong(index)
        }

        val id = long(MediaStore.Audio.Media._ID) ?: return null
        val displayName = string(MediaStore.Audio.Media.DISPLAY_NAME) ?: return null
        val path = string(MediaStore.Audio.Media.DATA)?.takeIf { it.isNotEmpty() }
            ?: string(MediaStore.Audio.Media.RELATIVE_PATH)?.let { relative ->
                // Android 10+ may leave DATA empty; rebuild it on primary storage.
                val root = Environment.getExternalStorageDirectory().path
                "$root/${relative.trimEnd('/')}/$displayName"
            }
            ?: return null
        // TRACK is stored as disc * 1000 + track number.
        val track = long(MediaStore.Audio.Media.TRACK)?.let { (it % 1000).toInt() }
            ?.takeIf { it > 0 }

        return mapOf(
            "id" to id,
            "uri" to ContentUris.withAppendedId(collection(), id).toString(),
            "path" to path,
            "displayName" to displayName,
            "title" to string(MediaStore.Audio.Media.TITLE),
            "artist" to string(MediaStore.Audio.Media.ARTIST),
            "album" to string(MediaStore.Audio.Media.ALBUM),
            "albumArtist" to string("album_artist"),
            "track" to track,
            "year" to long(MediaStore.Audio.Media.YEAR)?.toInt()?.takeIf { it > 0 },
            "durationMs" to (long(MediaStore.Audio.Media.DURATION) ?: 0L),
            "sizeBytes" to (long(MediaStore.Audio.Media.SIZE) ?: 0L),
            "dateAddedSeconds" to (long(MediaStore.Audio.Media.DATE_ADDED) ?: 0L),
        )
    }

    private fun loadArtwork(id: Long, size: Int): ByteArray? {
        if (!hasAudioAccess()) throw PermissionMissing()
        val uri = ContentUris.withAppendedId(collection(), id)
        val bitmap = try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                context.contentResolver.loadThumbnail(uri, Size(size, size), null)
            } else {
                embeddedPicture(uri)
            }
        } catch (e: FileNotFoundException) {
            null // No embedded art.
        } ?: return null
        return ByteArrayOutputStream().use { out ->
            bitmap.compress(Bitmap.CompressFormat.JPEG, 85, out)
            out.toByteArray()
        }
    }

    private fun embeddedPicture(uri: Uri): Bitmap? {
        val retriever = MediaMetadataRetriever()
        return try {
            retriever.setDataSource(context, uri)
            retriever.embeddedPicture?.let { BitmapFactory.decodeByteArray(it, 0, it.size) }
        } finally {
            retriever.release()
        }
    }

    private class PermissionMissing : Exception("Audio access not granted")

    companion object {
        const val NAME = "com.zemaapp.zema/library"
        private const val TAG = "Zema"
    }
}
