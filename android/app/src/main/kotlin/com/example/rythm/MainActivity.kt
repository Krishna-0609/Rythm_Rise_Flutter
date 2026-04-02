package com.example.rythm

import android.Manifest
import android.content.pm.PackageManager
import android.content.Intent
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val methodChannelName = "rythm/native_player"
    private val eventChannelName = "rythm/player_events"
    private val notificationPermissionRequestCode = 1102

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            methodChannelName
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "loadQueue" -> {
                    val songsJson = call.argument<String>("songsJson")
                    val index = call.argument<Int>("index") ?: 0
                    val playWhenReady = call.argument<Boolean>("playWhenReady") ?: true

                    if (songsJson == null) {
                        result.error("INVALID_QUEUE", "songsJson is null", null)
                        return@setMethodCallHandler
                    }

                    MusicService.pendingSongsJson = songsJson
                    startMusicService(
                        Intent(this, MusicService::class.java).apply {
                            action = MusicService.ACTION_LOAD_QUEUE
                            putExtra(MusicService.EXTRA_INDEX, index)
                            putExtra(MusicService.EXTRA_PLAY_WHEN_READY, playWhenReady)
                        }
                    )
                    result.success(null)
                }
                "play" -> {
                    startMusicService(Intent(this, MusicService::class.java).apply {
                        action = MusicService.ACTION_PLAY
                    })
                    result.success(null)
                }
                "pause" -> {
                    startMusicService(Intent(this, MusicService::class.java).apply {
                        action = MusicService.ACTION_PAUSE
                    })
                    result.success(null)
                }
                "togglePlayPause" -> {
                    startMusicService(Intent(this, MusicService::class.java).apply {
                        action = MusicService.ACTION_TOGGLE
                    })
                    result.success(null)
                }
                "seek" -> {
                    val position = call.argument<Int>("position") ?: 0
                    startMusicService(Intent(this, MusicService::class.java).apply {
                        action = MusicService.ACTION_SEEK
                        putExtra(MusicService.EXTRA_POSITION, position.toLong())
                    })
                    result.success(null)
                }
                "next" -> {
                    startMusicService(Intent(this, MusicService::class.java).apply {
                        action = MusicService.ACTION_NEXT
                    })
                    result.success(null)
                }
                "previous" -> {
                    startMusicService(Intent(this, MusicService::class.java).apply {
                        action = MusicService.ACTION_PREVIOUS
                    })
                    result.success(null)
                }
                "setShuffle" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    startMusicService(Intent(this, MusicService::class.java).apply {
                        action = MusicService.ACTION_SET_SHUFFLE
                        putExtra(MusicService.EXTRA_ENABLED, enabled)
                    })
                    result.success(null)
                }
                "setRepeat" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    startMusicService(Intent(this, MusicService::class.java).apply {
                        action = MusicService.ACTION_SET_REPEAT
                        putExtra(MusicService.EXTRA_ENABLED, enabled)
                    })
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            eventChannelName
        ).setStreamHandler(PlayerEventStream)
    }

    override fun onResume() {
        super.onResume()
        requestNotificationPermissionIfNeeded()
    }

    private fun startMusicService(intent: Intent) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    private fun requestNotificationPermissionIfNeeded() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            return
        }

        if (ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.POST_NOTIFICATIONS
            ) == PackageManager.PERMISSION_GRANTED
        ) {
            return
        }

        ActivityCompat.requestPermissions(
            this,
            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
            notificationPermissionRequestCode
        )
    }
}
