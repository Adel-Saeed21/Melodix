package com.example.spotify

import android.Manifest
import android.annotation.TargetApi
import android.content.ComponentName
import android.content.ContentUris
import android.content.Context
import android.app.PendingIntent
import android.app.PictureInPictureParams
import android.app.RemoteAction
import android.content.BroadcastReceiver
import android.content.Intent
import android.content.IntentFilter
import android.graphics.drawable.Icon
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

    /** Whether the video plays: the window's middle button is pause, else play. */
    private var pipPlaying = false

    /**
     * The window's own buttons (back, play / pause, forward). Without them
     * Android shows the media session's buttons there, and that session is
     * the music player's: they would control the music, not the video.
     */
    private val pipActionReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            val action = intent.getStringExtra(PIP_EXTRA_ACTION) ?: return
            pipChannel?.invokeMethod("pipAction", action)
        }
    }
    private var pipReceiverRegistered = false

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
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "melodix/app_icon")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "current" -> result.success(currentAppIcon())
                    "set" -> {
                        val name = call.argument<String>("name")
                        if (name == null || name !in APP_ICONS) {
                            result.error("unknown_icon", "No icon named $name", null)
                        } else {
                            try {
                                setAppIcon(name)
                                result.success(true)
                            } catch (e: Exception) {
                                result.error("icon_failed", e.message, null)
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "melodix/subtitles")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "videoPath" -> {
                        val uri = call.argument<String>("uri")
                        if (uri == null) {
                            result.success(null)
                        } else {
                            runInBackground(result) { videoPath(Uri.parse(uri)) }
                        }
                    }
                    "pick" -> pickSubtitle(result)
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
                            pipPlaying = call.argument<Boolean>("playing") ?: pipAutoEnter
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
        val builder = PictureInPictureParams.Builder()
            .setAspectRatio(pipAspect)
            .setActions(pipActions())
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            // Android 12+: slides into the window on its own when the user
            // goes home, only while a video plays.
            builder.setAutoEnterEnabled(pipAutoEnter)
            // Video: no seamless resize (it's meant for non-video content).
            builder.setSeamlessResizeEnabled(false)
        }
        return builder.build()
    }

    @TargetApi(Build.VERSION_CODES.O)
    private fun pipActions(): List<RemoteAction> = listOf(
        pipAction("rewind", 1, R.drawable.ic_media_rewind, "Back"),
        if (pipPlaying) {
            pipAction("pause", 2, R.drawable.ic_media_pause, "Pause")
        } else {
            pipAction("play", 3, R.drawable.ic_media_play, "Play")
        },
        pipAction("forward", 4, R.drawable.ic_media_forward, "Forward"),
    )

    @TargetApi(Build.VERSION_CODES.O)
    private fun pipAction(name: String, requestCode: Int, icon: Int, title: String): RemoteAction {
        val intent = Intent(PIP_BROADCAST)
            .setPackage(packageName)
            .putExtra(PIP_EXTRA_ACTION, name)
        val pending = PendingIntent.getBroadcast(
            this,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        return RemoteAction(Icon.createWithResource(this, icon), title, title, pending)
    }

    private fun registerPipReceiver() {
        if (pipReceiverRegistered) return
        val filter = IntentFilter(PIP_BROADCAST)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(pipActionReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            @Suppress("UnspecifiedRegisterReceiverFlag")
            registerReceiver(pipActionReceiver, filter)
        }
        pipReceiverRegistered = true
    }

    private fun unregisterPipReceiver() {
        if (!pipReceiverRegistered) return
        unregisterReceiver(pipActionReceiver)
        pipReceiverRegistered = false
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
        // The window's buttons are heard only while the window is up.
        if (isInPictureInPictureMode) registerPipReceiver() else unregisterPipReceiver()
        // Flutter shows only the video while in the window.
        pipChannel?.invokeMethod("pipChanged", isInPictureInPictureMode)
    }

    // ---- Subtitles ----------------------------------------------------------

    /** The pick waiting for the system file picker's answer. */
    private var pendingPick: MethodChannel.Result? = null

    /**
     * The video file's path (MediaStore's DATA column), so Flutter can look
     * for subtitle files next to it. Null when unknown or not readable.
     */
    private fun videoPath(uri: Uri): String? {
        @Suppress("DEPRECATION")
        val column = MediaStore.MediaColumns.DATA
        return try {
            contentResolver.query(uri, arrayOf(column), null, null, null)?.use { cursor ->
                if (cursor.moveToFirst()) cursor.getString(0) else null
            }
        } catch (e: Exception) {
            null
        }
    }

    /** Opens the system file picker for one subtitle file. */
    private fun pickSubtitle(result: MethodChannel.Result) {
        if (pendingPick != null) {
            result.error("busy", "A file picker is already open", null)
            return
        }
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT)
            .addCategory(Intent.CATEGORY_OPENABLE)
            .setType("*/*")
            .putExtra(
                Intent.EXTRA_MIME_TYPES,
                arrayOf(
                    "application/x-subrip",
                    "text/vtt",
                    "text/plain",
                    "application/octet-stream",
                ),
            )
        pendingPick = result
        try {
            startActivityForResult(intent, PICK_SUBTITLE)
        } catch (e: Exception) {
            pendingPick = null
            result.error("unavailable", "No file picker on this device", null)
        }
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != PICK_SUBTITLE) return
        val result = pendingPick ?: return
        pendingPick = null
        val uri = data?.data
        if (resultCode != RESULT_OK || uri == null) {
            result.success(null) // cancelled
            return
        }
        runInBackground(result) { readPicked(uri) }
    }

    /** The picked file's name and bytes (at most 5 MB: subtitles are small). */
    private fun readPicked(uri: Uri): Map<String, Any> {
        var name = "subtitles.srt"
        contentResolver.query(
            uri,
            arrayOf(android.provider.OpenableColumns.DISPLAY_NAME),
            null,
            null,
            null,
        )?.use { cursor ->
            if (cursor.moveToFirst()) cursor.getString(0)?.let { name = it }
        }
        val stream = contentResolver.openInputStream(uri)
            ?: throw QueryFailed("The file can't be opened")
        val bytes = stream.use { input ->
            val out = java.io.ByteArrayOutputStream()
            val buffer = ByteArray(16 * 1024)
            var total = 0
            while (true) {
                val read = input.read(buffer)
                if (read < 0) break
                total += read
                if (total > MAX_SUBTITLE_BYTES) throw QueryFailed("The file is too large")
                out.write(buffer, 0, read)
            }
            out.toByteArray()
        }
        return mapOf("name" to name, "bytes" to bytes)
    }

    override fun onDestroy() {
        unregisterPipReceiver()
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

    /** The launcher alias for icon [name] ("classic", "blue", ...). */
    private fun appIconComponent(name: String) = ComponentName(
        this,
        "com.example.spotify.Launcher" + name.replaceFirstChar { it.uppercase() },
    )

    /** The icon whose launcher entry is on ("classic" if none says so). */
    private fun currentAppIcon(): String = APP_ICONS.firstOrNull { name ->
        val state = packageManager.getComponentEnabledSetting(appIconComponent(name))
        state == PackageManager.COMPONENT_ENABLED_STATE_ENABLED ||
            (state == PackageManager.COMPONENT_ENABLED_STATE_DEFAULT && name == "classic")
    } ?: "classic"

    /**
     * Turns on the launcher entry for [name] first, then the others off, so
     * there is always one to open the app with. DONT_KILL_APP: the app keeps
     * running (some launchers take a moment to show the new icon).
     */
    private fun setAppIcon(name: String) {
        packageManager.setComponentEnabledSetting(
            appIconComponent(name),
            PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
            PackageManager.DONT_KILL_APP,
        )
        for (other in APP_ICONS) {
            if (other == name) continue
            packageManager.setComponentEnabledSetting(
                appIconComponent(other),
                PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                PackageManager.DONT_KILL_APP,
            )
        }
    }

    private companion object {
        /** Must match the activity-alias entries in AndroidManifest.xml. */
        val APP_ICONS = listOf(
            "classic", "blue", "purple", "pink", "red", "orange", "yellow", "teal", "green",
        )

        /** MediaStore.Audio.AudioColumns.IS_AUDIOBOOK (API 29). */
        const val IS_AUDIOBOOK = "is_audiobook"

        /** The picture-in-picture buttons' broadcast (to this app only). */
        const val PIP_BROADCAST = "com.melodix.PIP_ACTION"
        const val PIP_EXTRA_ACTION = "action"

        const val PICK_SUBTITLE = 4711
        const val MAX_SUBTITLE_BYTES = 5 * 1024 * 1024
    }
}
