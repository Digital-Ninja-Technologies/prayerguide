package com.prayerguide.prayer_guide

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat

/// Fired by AlarmManager (scheduled from MainActivity's MethodChannel
/// handler) at the moment a running prayer timer's countdown ends. This is
/// the Android analog of iOS's `NotificationScheduler.scheduleTimerCompletion` —
/// a fallback in case the app isn't in the foreground to notice on its own;
/// the Dart side already knows how to correctly reconcile against the real
/// end time whenever the app is actually reopened.
class TimerAlarmReceiver : BroadcastReceiver() {

  companion object {
    const val EXTRA_CATEGORY = "category"
    private const val CHANNEL_ID = "prayer_timer_status"
    private const val NOTIFICATION_ID = 4100
  }

  override fun onReceive(context: Context, intent: Intent) {
    val category = intent.getStringExtra(EXTRA_CATEGORY) ?: "Prayer"
    val notificationManager =
      context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
      val channel = NotificationChannel(
        CHANNEL_ID,
        "Prayer timer",
        NotificationManager.IMPORTANCE_HIGH,
      ).apply { description = "Lets you know when a running prayer timer finishes" }
      notificationManager.createNotificationChannel(channel)
    }

    val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
    val contentIntent = PendingIntent.getActivity(
      context, 0, launchIntent,
      PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )

    val notification = NotificationCompat.Builder(context, CHANNEL_ID)
      .setContentTitle("Your prayer time is up")
      .setContentText("$category — well prayed. Come back to close it out.")
      .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
      .setAutoCancel(true)
      .setContentIntent(contentIntent)
      .build()

    notificationManager.notify(NOTIFICATION_ID, notification)
  }
}
