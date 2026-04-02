package com.example.rythm

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat
import androidx.media.app.NotificationCompat.MediaStyle
import androidx.media3.common.AudioAttributes
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.MediaMetadata
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.session.MediaSession
import org.json.JSONArray
import java.net.URL
import java.util.concurrent.Executors

@UnstableApi
class MusicService : Service() {

    companion object {
        const val ACTION_LOAD_QUEUE = "com.example.rythm.LOAD_QUEUE"
        const val ACTION_PLAY = "com.example.rythm.PLAY"
        const val ACTION_PAUSE = "com.example.rythm.PAUSE"
        const val ACTION_TOGGLE = "com.example.rythm.TOGGLE"
        const val ACTION_NEXT = "com.example.rythm.NEXT"
        const val ACTION_PREVIOUS = "com.example.rythm.PREVIOUS"
        const val ACTION_SEEK = "com.example.rythm.SEEK"
        const val ACTION_SET_SHUFFLE = "com.example.rythm.SET_SHUFFLE"
        const val ACTION_SET_REPEAT = "com.example.rythm.SET_REPEAT"

        const val EXTRA_SONGS_JSON = "songs_json"
        const val EXTRA_INDEX = "index"
        const val EXTRA_POSITION = "position"
        const val EXTRA_PLAY_WHEN_READY = "play_when_ready"
        const val EXTRA_ENABLED = "enabled"

        private const val CHANNEL_ID = "native_music_service"
        private const val NOTIFICATION_ID = 1101

        @Volatile
        var pendingSongsJson: String? = null
    }

    private data class SongItem(
        val id: String,
        val title: String,
        val artist: String,
        val url: String,
        val albumArt: String?
    )

    private lateinit var player: ExoPlayer
    private lateinit var mediaSession: MediaSession
    private val artworkExecutor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())
    private val progressUpdateRunnable = object : Runnable {
        override fun run() {
            sendPlayerState()
            if (player.isPlaying) {
                mainHandler.postDelayed(this, 500L)
            }
        }
    }
    private var songs: List<SongItem> = emptyList()
    private var isForeground = false
    private var cachedArtworkUrl: String? = null
    private var cachedArtworkBitmap: Bitmap? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        player = ExoPlayer.Builder(this).build().apply {
            val audioAttributes = AudioAttributes.Builder()
                .setUsage(C.USAGE_MEDIA)
                .setContentType(C.AUDIO_CONTENT_TYPE_MUSIC)
                .build()
            setAudioAttributes(audioAttributes, true)
            setHandleAudioBecomingNoisy(true)
            addListener(object : Player.Listener {
                override fun onIsPlayingChanged(isPlaying: Boolean) {
                    manageProgressUpdates()
                    updateNotification()
                    sendPlayerState()
                }

                override fun onMediaItemTransition(mediaItem: MediaItem?, reason: Int) {
                    cachedArtworkUrl = null
                    cachedArtworkBitmap = null
                    updateNotification()
                    sendPlayerState()
                }

                override fun onPlaybackStateChanged(playbackState: Int) {
                    manageProgressUpdates()
                    updateNotification()
                    sendPlayerState()
                }

                override fun onPlayerError(error: PlaybackException) {
                    manageProgressUpdates()
                    updateNotification()
                    sendPlayerState(error.message)
                }

                override fun onShuffleModeEnabledChanged(shuffleModeEnabled: Boolean) {
                    sendPlayerState()
                }

                override fun onRepeatModeChanged(repeatMode: Int) {
                    sendPlayerState()
                }
            })
        }
        mediaSession = MediaSession.Builder(this, player).build().apply {
            val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
            if (launchIntent != null) {
                setSessionActivity(
                    android.app.PendingIntent.getActivity(
                        this@MusicService,
                        0,
                        launchIntent,
                        android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
                    )
                )
            }
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_LOAD_QUEUE -> {
                val songsJson = pendingSongsJson
                val index = intent.getIntExtra(EXTRA_INDEX, 0)
                val playWhenReady = intent.getBooleanExtra(EXTRA_PLAY_WHEN_READY, true)
                if (songsJson != null) {
                    pendingSongsJson = null
                    loadQueue(songsJson, index, playWhenReady)
                }
            }
            ACTION_PLAY -> player.play()
            ACTION_PAUSE -> player.pause()
            ACTION_TOGGLE -> if (player.isPlaying) player.pause() else player.play()
            ACTION_NEXT -> if (player.hasNextMediaItem()) player.seekToNextMediaItem()
            ACTION_PREVIOUS -> if (player.hasPreviousMediaItem()) player.seekToPreviousMediaItem() else player.seekTo(0, 0)
            ACTION_SEEK -> player.seekTo(intent.getLongExtra(EXTRA_POSITION, 0L))
            ACTION_SET_SHUFFLE -> player.shuffleModeEnabled = intent.getBooleanExtra(EXTRA_ENABLED, false)
            ACTION_SET_REPEAT -> {
                player.repeatMode = if (intent.getBooleanExtra(EXTRA_ENABLED, false)) {
                    Player.REPEAT_MODE_ONE
                } else {
                    Player.REPEAT_MODE_OFF
                }
            }
        }

        updateNotification()
        sendPlayerState()
        return START_STICKY
    }

    private fun loadQueue(songsJson: String, index: Int, playWhenReady: Boolean) {
        songs = parseSongs(songsJson)
        if (songs.isEmpty()) {
            mainHandler.removeCallbacks(progressUpdateRunnable)
            stopForegroundState()
            sendPlayerState("No playable songs found in queue")
            return
        }

        val mediaItems = songs.map { song ->
            MediaItem.Builder()
                .setUri(song.url)
                .setMediaId(song.id)
                .setMediaMetadata(
                    MediaMetadata.Builder()
                        .setTitle(song.title)
                        .setArtist(song.artist)
                        .setArtworkUri(song.albumArt?.let { android.net.Uri.parse(it) })
                        .build()
                )
                .build()
        }

        player.setMediaItems(mediaItems, index.coerceIn(0, (mediaItems.size - 1).coerceAtLeast(0)), 0L)
        player.prepare()
        player.playWhenReady = playWhenReady
    }

    private fun parseSongs(songsJson: String): List<SongItem> {
        val jsonArray = JSONArray(songsJson)
        val items = mutableListOf<SongItem>()
        for (i in 0 until jsonArray.length()) {
            val jsonObject = jsonArray.getJSONObject(i)
            items.add(
                SongItem(
                    id = jsonObject.opt("id").toString(),
                    title = jsonObject.optString("title", "Unknown Title"),
                    artist = jsonObject.optString("artist", "Unknown Artist"),
                    url = jsonObject.optString("url"),
                    albumArt = jsonObject.optString("album_art").ifBlank { null }
                )
            )
        }
        return items
    }

    private fun currentSong(): SongItem? {
        val index = player.currentMediaItemIndex
        return if (index in songs.indices) songs[index] else null
    }

    private fun buildNotification(song: SongItem, bitmap: Bitmap? = null): Notification {
        val contentIntent = packageManager.getLaunchIntentForPackage(packageName)?.let {
            android.app.PendingIntent.getActivity(
                this,
                0,
                it,
                android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
            )
        }

        val previousIntent = servicePendingIntent(ACTION_PREVIOUS, 1)
        val toggleIntent = servicePendingIntent(ACTION_TOGGLE, 2)
        val nextIntent = servicePendingIntent(ACTION_NEXT, 3)

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(song.title)
            .setContentText(song.artist)
            .setSubText("Rythm")
            .setSmallIcon(R.drawable.ic_notification)
            .setLargeIcon(bitmap)
            .setContentIntent(contentIntent)
            .setOnlyAlertOnce(true)
            .setSilent(true)
            .setOngoing(player.isPlaying)
            .setShowWhen(false)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setCategory(NotificationCompat.CATEGORY_TRANSPORT)
            .setColor(0xFFD9519D.toInt())
            .setColorized(true)
            .setStyle(
                MediaStyle()
                    .setMediaSession(mediaSession.sessionCompatToken)
                    .setShowActionsInCompactView(0, 1, 2)
            )
            .addAction(R.drawable.prev_button, "Previous", previousIntent)
            .addAction(
                if (player.isPlaying) R.drawable.pause_icon else R.drawable.play_icon,
                if (player.isPlaying) "Pause" else "Play",
                toggleIntent
            )
            .addAction(R.drawable.next_icon, "Next", nextIntent)
            .build()
    }

    private fun updateNotification() {
        val currentSong = currentSong()
        if (currentSong == null) {
            mainHandler.removeCallbacks(progressUpdateRunnable)
            stopForegroundState()
            return
        }

        val notificationManager = getSystemService(NotificationManager::class.java)

        if (cachedArtworkUrl == currentSong.albumArt && cachedArtworkBitmap != null) {
            val notification = buildNotification(currentSong, cachedArtworkBitmap)
            notificationManager.notify(NOTIFICATION_ID, notification)
            startInForeground(notification)
            return
        }

        if (currentSong.albumArt.isNullOrBlank()) {
            cachedArtworkUrl = null
            cachedArtworkBitmap = null
            val notification = buildNotification(currentSong)
            notificationManager.notify(NOTIFICATION_ID, notification)
            startInForeground(notification)
            return
        }

        artworkExecutor.execute {
            val bitmap = runCatching {
                BitmapFactory.decodeStream(URL(currentSong.albumArt).openStream())
            }.getOrNull()
            mainHandler.post {
                val latestSong = currentSong()
                if (latestSong?.id != currentSong.id) {
                    return@post
                }

                cachedArtworkUrl = currentSong.albumArt
                cachedArtworkBitmap = bitmap
                val notification = buildNotification(currentSong, bitmap)
                notificationManager.notify(NOTIFICATION_ID, notification)
                startInForeground(notification)
            }
        }
    }

    private fun startInForeground(notification: Notification) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            ServiceCompat.startForeground(
                this,
                NOTIFICATION_ID,
                notification,
                android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
        isForeground = true
    }

    private fun stopForegroundState() {
        if (!isForeground) {
            return
        }
        stopForeground(STOP_FOREGROUND_REMOVE)
        getSystemService(NotificationManager::class.java).cancel(NOTIFICATION_ID)
        isForeground = false
    }

    private fun servicePendingIntent(action: String, requestCode: Int): android.app.PendingIntent {
        val intent = Intent(this, MusicService::class.java).apply { this.action = action }
        return android.app.PendingIntent.getService(
            this,
            requestCode,
            intent,
            android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun sendPlayerState(errorMessage: String? = null) {
        val currentSongId = currentSong()?.id ?: ""
        val event = hashMapOf<String, Any>(
            "position" to player.currentPosition,
            "duration" to (if (player.duration == C.TIME_UNSET) 0L else player.duration),
            "isPlaying" to player.isPlaying,
            "index" to player.currentMediaItemIndex.coerceAtLeast(0),
            "songId" to currentSongId,
            "shuffle" to player.shuffleModeEnabled,
            "repeat" to (player.repeatMode == Player.REPEAT_MODE_ONE)
        )
        if (!errorMessage.isNullOrBlank()) {
            event["error"] = errorMessage
        }
        PlayerEventStream.eventSink?.success(event)
    }

    private fun manageProgressUpdates() {
        mainHandler.removeCallbacks(progressUpdateRunnable)
        if (player.isPlaying) {
            mainHandler.post(progressUpdateRunnable)
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Music playback",
                NotificationManager.IMPORTANCE_LOW
            )
            getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
        }
    }

    override fun onDestroy() {
        artworkExecutor.shutdownNow()
        mainHandler.removeCallbacks(progressUpdateRunnable)
        stopForegroundState()
        mediaSession.release()
        player.release()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
