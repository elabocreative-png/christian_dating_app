package com.example.christian_dating_app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.graphics.Color
import android.os.Build
import android.os.Bundle
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannel()
        WindowCompat.setDecorFitsSystemWindows(window, true)
        applySystemBarColors()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val manager = getSystemService(NotificationManager::class.java) ?: return

        val chatChannel = NotificationChannel(
            "chat_messages",
            "Messages",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "New chat messages"
        }
        manager.createNotificationChannel(chatChannel)

        val matchChannel = NotificationChannel(
            "new_matches",
            "Matches",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "New mutual matches"
        }
        manager.createNotificationChannel(matchChannel)
    }

    override fun onPostResume() {
        super.onPostResume()
        applySystemBarColors()
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) applySystemBarColors()
    }

    private fun applySystemBarColors() {
        window.statusBarColor = Color.WHITE
        window.navigationBarColor = Color.TRANSPARENT
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            window.isNavigationBarContrastEnforced = false
        }
        val controller = WindowCompat.getInsetsController(window, window.decorView)
        controller.isAppearanceLightNavigationBars = true
        controller.isAppearanceLightStatusBars = true
    }
}
