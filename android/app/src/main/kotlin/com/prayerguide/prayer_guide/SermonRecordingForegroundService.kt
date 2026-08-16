package com.prayerguide.prayer_guide

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import androidx.core.app.NotificationCompat

/// Android's answer to the iOS Live Activity for an in-progress sermon-note
/// recording: an ongoing, ticking notification, backed by a real foreground
/// service so the process (and the `record` plugin's mic capture running
/// inside it) isn't killed while the app is minimized. Started/stopped from
/// MainActivity's MethodChannel handler, which mirrors the same
/// "com.prayerguide.prayer_guide/live_activity" channel LiveActivityChannel.swift
/// uses on iOS.
class SermonRecordingForegroundService : Service() {

  companion object {
    const val EXTRA_START_TIME_MILLIS = "startTimeMillis"
    private const val CHANNEL_ID = "sermon_recording_status"
    private const val NOTIFICATION_ID = 4200
  }

  private val handler = Handler(Looper.getMainLooper())
  private var startTimeMillis = 0L
  private lateinit var notificationManager: NotificationManager

  private val ticker = object : Runnable {
    override fun run() {
      notificationManager.notify(NOTIFICATION_ID, buildNotification())
      handler.postDelayed(this, 1000)
    }
  }

  override fun onCreate() {
    super.onCreate()
    notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
      val channel = NotificationChannel(
        CHANNEL_ID,
        "Sermon recording",
        NotificationManager.IMPORTANCE_LOW,
      ).apply { description = "Shows while a sermon note recording is in progress" }
      notificationManager.createNotificationChannel(channel)
    }
  }

  override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
    startTimeMillis = intent?.getLongExtra(EXTRA_START_TIME_MILLIS, System.currentTimeMillis())
      ?: System.currentTimeMillis()
    val notification = buildNotification()
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
      startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE)
    } else {
      startForeground(NOTIFICATION_ID, notification)
    }
    handler.removeCallbacks(ticker)
    handler.postDelayed(ticker, 1000)
    return START_STICKY
  }

  private fun buildNotification(): Notification {
    val elapsed = (System.currentTimeMillis() - startTimeMillis) / 1000
    val minutes = elapsed / 60
    val seconds = elapsed % 60
    val label = String.format("%d:%02d", minutes, seconds)

    val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
    val contentIntent = PendingIntent.getActivity(
      this, 0, launchIntent,
      PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )

    return NotificationCompat.Builder(this, CHANNEL_ID)
      .setContentTitle("Recording sermon note")
      .setContentText(label)
      .setSmallIcon(android.R.drawable.presence_audio_online)
      .setOngoing(true)
      .setOnlyAlertOnce(true)
      .setContentIntent(contentIntent)
      .build()
  }

  override fun onDestroy() {
    handler.removeCallbacks(ticker)
    super.onDestroy()
  }

  override fun onBind(intent: Intent?): IBinder? = null
}
