package com.example.spotify

import android.Manifest
import android.annotation.TargetApi
import android.content.ContentUris
import android.content.Context
import android.app.PictureInPictureParams
import android.content.pm.PackageManager
import android.content.res.Configuration
import android.database.Cursor
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import android.util.Rational
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

/**
 * Hosts the "melodix/media_store" channel used to sync the music library,
 * and the "melodix/pip" channel for picture-in-picture (a playing video
 * keeps going in a small window over other apps when the user leaves).
 *
 * Data safety rules (a wrong "empty" answer would delete the user's library):
 * - Every method checks the read permission first and fails with
 *   "permission_denied" without it. (Without permission Android returns an
 *   EMPTY result instead of an error, so this check is essential.)
 * - A SecurityException is reported as "permission_denied".
 * - A missing (null) cursor, an unavailable volume or any other error is
 *   reported as "query_failed". It is never turned into an empty list.
 * - An empty result is only returned when every query succeeded.
 *
 * Queries run on a background thread; replies go out on the main thread.
 *
 * Extends [AudioServiceActivity] so the UI and the background media
 * service share one Flutter engine (music keeps playing when the activity
 * is closed, and reopening the app shows the same player).
 */
class MainActivity : AudioServiceActivity() {
    private val worker = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    private var pipChannel: MethodChannel? = null

    /** Flutter turns this on only while a video is playing. */
    private var pipAutoEnter = false
    private var pipAspect = Rational(16, 9)

    private class PermissionDenied(message: String) : Exception(message)
    private class QueryFailed(message: String) : Exception(message)

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "melodix/media_store")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "audioCheckpoint" -> runInBackground(result) {
                        audioCheckpoint(applicationContext)
                    }
                    "audioChangesSince" -> {
                        @Suppress("UNCHECKED_CAST")
                        val since = call.argument<Map<String, Number>>("since") ?: emptyMap()
                        runInBackground(result) {
                            audioChangesSince(applicationContext, since)
                        }
                    }
                    "audioFullScan" -> runInBackground(result) {
                        audioFullScan(applicationContext)
                    }
                    else -> result.notImplemented()
                }
            }
        pipChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "melodix/pip")
            .also { channel ->
                channel.setMethodCallHandler { call, result ->
                    when (call.method) {
                        "isSupported" -> result.success(pipSupported())
                        "setAutoEnter" -> {
                            pipAutoEnter = call.argument<Boolean>("enabled") ?: false
                            pipAspect = clampedAspect(
                                call.argument<Int>("width") ?: 16,
                                call.argument<Int>("height") ?: 9,
                            )
                            applyPipParams()
                            result.success(null)
                        }
                        else -> result.notImplemented()
                    }
                }
            }
    }

    // ---- Picture-in-picture -------------------------------------------------

    private fun pipSupported(): Boolean =
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            packageManager.hasSystemFeature(PackageManager.FEATURE_PICTURE_IN_PICTURE)

    /**
     * The video's shape, within what Android accepts for the window
     * (between 1:2.39 and 2.39:1); 16:9 if unknown.
     */
    private fun clampedAspect(width: Int, height: Int): Rational {
        if (width <= 0 || height <= 0) return Rational(16, 9)
        val ratio = width.toDouble() / height
        return when {
            ratio > 2.39 -> Rational(239, 100)
            ratio < 1 / 2.39 -> Rational(100, 239)
            else -> Rational(width, height)
        }
    }

    @TargetApi(Build.VERSION_CODES.O)
    private fun pipParams(): PictureInPictureParams {
        val builder = PictureInPictureParams.Builder().setAspectRatio(pipAspect)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            // Android 12+: slides into the window on its own when the user
            // goes home, only while a video plays.
            builder.setAutoEnterEnabled(pipAutoEnter)
            // Video: no seamless resize (it's meant for non-video content).
            builder.setSeamlessResizeEnabled(false)
        }
        return builder.build()
    }

    private fun applyPipParams() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O || !pipSupported()) return
        try {
            setPictureInPictureParams(pipParams())
        } catch (e: IllegalStateException) {
            // The activity can't take parameters right now; next call will.
        }
    }

    /** Android 8–11: enter the window by hand when the user goes home. */
    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        if (pipAutoEnter &&
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            Build.VERSION.SDK_INT < Build.VERSION_CODES.S &&
            pipSupported()
        ) {
            try {
                enterPictureInPictureMode(pipParams())
            } catch (e: IllegalStateException) {
                // Not allowed now (e.g. turned off for the app in settings).
            }
        }
    }

    override fun onPictureInPictureModeChanged(
        isInPictureInPictureMode: Boolean,
        newConfig: Configuration,
    ) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        // Flutter shows only the video while in the window.
        pipChannel?.invokeMethod("pipChanged", isInPictureInPictureMode)
    }

    override fun onDestroy() {
        worker.shutdown()
        super.onDestroy()
    }

    private fun runInBackground(result: MethodChannel.Result, work: () -> Any?) {
        worker.execute {
            try {
                val value = work()
                main.post { result.success(value) }
            } catch (e: PermissionDenied) {
                main.post { result.error("permission_denied", e.message, null) }
            } catch (e: SecurityException) {
                main.post { result.error("permission_denied", e.message, null) }
            } catch (e: Exception) {
                main.post { result.error("query_failed", e.message ?: e.javaClass.simpleName, null) }
            }
        }
    }

    /** READ_MEDIA_AUDIO on Android 13+, READ_EXTERNAL_STORAGE before. */
    private fun requireAudioPermission(context: Context) {
        val permission = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            Manifest.permission.READ_MEDIA_AUDIO
        } else {
            Manifest.permission.READ_EXTERNAL_STORAGE
        }
        if (context.checkSelfPermission(permission) != PackageManager.PERMISSION_GRANTED) {
            throw PermissionDenied("$permission not granted")
        }
    }

    /** A cursor that must exist: null means the query failed (never "empty"). */
    private fun queryOrFail(
        context: Context,
        uri: Uri,
        columns: Array<String>,
        selection: String? = null,
        args: Array<String>? = null,
    ): Cursor = context.contentResolver.query(uri, columns, selection, args, null)
        ?: throw QueryFailed("MediaStore returned no cursor for $uri")

    /**
     * MediaStore's version, each external volume's latest generation and the
     * audio row count. Null ONLY when the device has no generations (before
     * Android 11); every other problem is an error.
     */
    private fun audioCheckpoint(context: Context): Map<String, Any>? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) return null
        requireAudioPermission(context)
        return checkpointR(context)
    }

    @TargetApi(Build.VERSION_CODES.R)
    private fun checkpointR(context: Context): Map<String, Any> {
        val version = MediaStore.getVersion(context)
        val generations = HashMap<String, Long>()
        for (volume in MediaStore.getExternalVolumeNames(context)) {
            generations[volume] = MediaStore.getGeneration(context, volume)
        }
        val count = queryOrFail(
            context,
            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
            arrayOf(MediaStore.Audio.Media._ID),
        ).use { it.count }
        return mapOf("version" to version, "generations" to generations, "count" to count)
    }

    /**
     * Rows changed since [since] (per volume; a volume missing from it, or at
     * 0, is read entirely) and every current audio id (deletions are found by
     * comparing ids). The checkpoint is read first, so anything changing
     * during the queries has a later generation and is picked up next time.
     * If any query fails the whole call fails: no partial results.
     */
    @TargetApi(Build.VERSION_CODES.R)
    private fun audioChangesSince(context: Context, since: Map<String, Number>): Map<String, Any> {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) {
            throw QueryFailed("Generations need Android 11+")
        }
        requireAudioPermission(context)
        val checkpoint = checkpointR(context)

        val changed = ArrayList<Map<String, Any?>>()
        @Suppress("UNCHECKED_CAST")
        val volumes = (checkpoint["generations"] as Map<String, Long>).keys
        for (volume in volumes) {
            val after = since[volume]?.toLong() ?: 0L
            // From 0 means "everything on this volume" (no generation filter,
            // so rows that never got a generation are included too).
            val cursor = if (after > 0L) {
                queryOrFail(
                    context,
                    MediaStore.Audio.Media.getContentUri(volume),
                    rowColumns(),
                    "${MediaStore.MediaColumns.GENERATION_MODIFIED} > ?",
                    arrayOf(after.toString()),
                )
            } else {
                queryOrFail(context, MediaStore.Audio.Media.getContentUri(volume), rowColumns())
            }
            cursor.use { while (it.moveToNext()) changed.add(readRow(it)) }
        }

        val ids = ArrayList<Long>()
        queryOrFail(
            context,
            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
            arrayOf(MediaStore.Audio.Media._ID),
        ).use { cursor ->
            val idColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media._ID)
            while (cursor.moveToNext()) ids.add(cursor.getLong(idColumn))
        }

        return mapOf("checkpoint" to checkpoint, "changed" to changed, "ids" to ids)
    }

    /**
     * Every audio row (all external volumes), plus the checkpoint taken before
     * reading them (null before Android 11). Works on all Android versions and
     * reports failures instead of returning an empty list.
     */
    private fun audioFullScan(context: Context): Map<String, Any?> {
        requireAudioPermission(context)
        val checkpoint = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            checkpointR(context)
        } else {
            null
        }
        val rows = ArrayList<Map<String, Any?>>()
        queryOrFail(context, MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, rowColumns())
            .use { while (it.moveToNext()) rows.add(readRow(it)) }
        return mapOf("checkpoint" to checkpoint, "rows" to rows)
    }

    /** One row, with the same fields (and URI form) the app's songs use. */
    private fun readRow(cursor: Cursor): Map<String, Any?> {
        val id = cursor.longOrNull(MediaStore.Audio.Media._ID) ?: 0L
        return mapOf(
            "id" to id,
            "path" to (cursor.stringOrNull(MediaStore.Audio.Media.DATA) ?: ""),
            // Same form as on_audio_query: content://media/external/audio/media/<id>
            "uri" to ContentUris.withAppendedId(
                MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                id,
            ).toString(),
            "title" to cursor.stringOrNull(MediaStore.Audio.Media.TITLE),
            "artist" to cursor.stringOrNull(MediaStore.Audio.Media.ARTIST),
            "album" to cursor.stringOrNull(MediaStore.Audio.Media.ALBUM),
            "albumId" to cursor.longOrNull(MediaStore.Audio.Media.ALBUM_ID),
            "duration" to cursor.longOrNull(MediaStore.Audio.Media.DURATION),
            "size" to cursor.longOrNull(MediaStore.Audio.Media.SIZE),
            "dateAdded" to cursor.longOrNull(MediaStore.Audio.Media.DATE_ADDED),
            "isMusic" to cursor.longOrNull(MediaStore.Audio.Media.IS_MUSIC),
            "isAlarm" to cursor.longOrNull(MediaStore.Audio.Media.IS_ALARM),
            "isNotification" to cursor.longOrNull(MediaStore.Audio.Media.IS_NOTIFICATION),
            "isRingtone" to cursor.longOrNull(MediaStore.Audio.Media.IS_RINGTONE),
            "isPodcast" to cursor.longOrNull(MediaStore.Audio.Media.IS_PODCAST),
            "isAudioBook" to cursor.longOrNull(IS_AUDIOBOOK),
        )
    }

    private fun Cursor.stringOrNull(column: String): String? {
        val index = getColumnIndex(column)
        return if (index < 0 || isNull(index)) null else getString(index)
    }

    private fun Cursor.longOrNull(column: String): Long? {
        val index = getColumnIndex(column)
        return if (index < 0 || isNull(index)) null else getLong(index)
    }

    /** Columns to read; IS_AUDIOBOOK only exists from Android 10. */
    private fun rowColumns(): Array<String> {
        val columns = arrayListOf(
            MediaStore.Audio.Media._ID,
            MediaStore.Audio.Media.DATA,
            MediaStore.Audio.Media.TITLE,
            MediaStore.Audio.Media.ARTIST,
            MediaStore.Audio.Media.ALBUM,
            MediaStore.Audio.Media.ALBUM_ID,
            MediaStore.Audio.Media.DURATION,
            MediaStore.Audio.Media.SIZE,
            MediaStore.Audio.Media.DATE_ADDED,
            MediaStore.Audio.Media.IS_MUSIC,
            MediaStore.Audio.Media.IS_ALARM,
            MediaStore.Audio.Media.IS_NOTIFICATION,
            MediaStore.Audio.Media.IS_RINGTONE,
            MediaStore.Audio.Media.IS_PODCAST,
        )
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) columns.add(IS_AUDIOBOOK)
        return columns.toTypedArray()
    }

    private companion object {
        /** MediaStore.Audio.AudioColumns.IS_AUDIOBOOK (API 29). */
        const val IS_AUDIOBOOK = "is_audiobook"
    }
}
