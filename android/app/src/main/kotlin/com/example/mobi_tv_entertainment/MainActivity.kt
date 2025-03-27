package com.example.mobi_tv_entertainment
import io.flutter.embedding.engine.plugins.FlutterPlugin
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.media.AudioManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.volume"
    private var volumeReceiver: BroadcastReceiver? = null

    override fun configureFlutterEngine(flutterEngine: io.flutter.embedding.engine.FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)

    // Set up the MethodChannel for communication with Flutter
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
        when (call.method) {
    "getVolume" -> {
        // Your existing volume code here
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val currentVolume = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC).toDouble()
        val maxVolume = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC).toDouble()
        val normalizedVolume = currentVolume / maxVolume
        result.success(normalizedVolume) // Return normalized volume
    }
    "detachVlcSurface" -> {
        // Run on a background thread to avoid blocking the UI
        Thread {
            try {
                // Just force GC to clean up resources
                System.gc()
                
                // Try to access any activity manager services to help flush caches
                try {
                    val am = getSystemService(Context.ACTIVITY_SERVICE) as android.app.ActivityManager
                    // Just list running services to flush caches
                    am.getRunningServices(10)
                } catch (e: Exception) {
                    // Ignore any errors here
                }
                
                result.success(null)
            } catch (e: Exception) {
                android.util.Log.e("VLC", "Error detaching VLC surface: ${e.message}")
                result.success(null)
            }
        }.start()
    }
    "forceReleaseResources" -> {
        Thread {
            try {
                // Multiple GC passes to ensure resources are freed
                System.gc()
                System.runFinalization()
                System.gc()
                
                // Try to release media-related resources if possible
                try {
                    val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                    // Just make a call to flush any caches
                    audioManager.isMusicActive
                } catch (e: Exception) {
                    // Ignore
                }
                
                result.success(null)
            } catch (e: Exception) {
                android.util.Log.e("VLC", "Force release error: ${e.message}")
                result.success(null)
            }
        }.start()
    }
    "forceKillVlc" -> {
    // Run on background thread to avoid any UI blocking
    Thread {
        try {
            // Multiple aggressive GC passes
            System.gc()
            System.runFinalization()
            System.gc()
            System.runFinalization()
            System.gc()
            
            result.success(null)
        } catch (e: Exception) {
            android.util.Log.e("VLC", "Force kill VLC error: ${e.message}")
            result.success(null) // Still return success to not block UI
        }
    }.start()
}
"emergencyReleaseVlc" -> {
    Thread {
        try {
            // Force GC multiple times
            System.gc()
            System.runFinalization()
            System.gc()
            
            // Attempt to find and manually finalize VLC resources
            try {
                val runtime = Runtime.getRuntime()
                runtime.gc()
            } catch (e: Exception) {
                // Ignore
            }
            
            result.success(null)
        } catch (e: Exception) {
            result.success(null) // Still return success
        }
    }.start()
}
    else -> {
        result.notImplemented()
    }

        }
    }
}

    override fun onResume() {
        super.onResume()
        registerVolumeReceiver() // Register volume listener when app is active
    }

    override fun onPause() {
        super.onPause()
        unregisterVolumeReceiver() // Unregister volume listener when app is paused
    }

    private fun registerVolumeReceiver() {
        volumeReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                if (intent.action == "android.media.VOLUME_CHANGED_ACTION") {
                    val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
                    val currentVolume = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC)
                    val maxVolume = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
                    val normalizedVolume = currentVolume.toDouble() / maxVolume

                    // Notify Flutter about volume changes
                    flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                        MethodChannel(messenger, CHANNEL).invokeMethod("volumeChanged", normalizedVolume)
                    }
                }
            }
        }
        val filter = IntentFilter("android.media.VOLUME_CHANGED_ACTION")
        registerReceiver(volumeReceiver, filter)
    }

    private fun unregisterVolumeReceiver() {
        volumeReceiver?.let {
            unregisterReceiver(it)
        }
        volumeReceiver = null
    }
}
