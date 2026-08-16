package com.prayerguide.prayer_guide

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/// Android side of the same "com.prayerguide.prayer_guide/live_activity"
/// channel LiveActivityChannel.swift implements on iOS — reusing the name
/// and method signatures means lib/core/live_activity/live_activity_service.dart
/// doesn't need any platform branching at its call sites.
///
/// There's no Dynamic Island/Live Activity equivalent on Android, so this
/// dispatches to two different mechanisms depending on what's actually
/// needed: `start`/`update`/`end` (the prayer timer, no sensor in use) go
/// through AlarmManager plus a one-shot completion notification;
/// `startRecording`/`endRecording` (sermon notes, mic genuinely active) go
/// through a real foreground service so the process survives backgrounding.
class MainActivity : FlutterActivity() {
  private val channelName = "com.prayerguide.prayer_guide/live_activity"

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
      .setMethodCallHandler { call, result ->
        when (call.method) {
          "start", "update" -> {
            val category = call.argument<String>("category") ?: "Prayer"
            val endDateMillis = (call.argument<Number>("endDateMillis"))?.toLong()
            val isPaused = call.argument<Boolean>("isPaused") ?: false
            if (endDateMillis == null || isPaused) {
              cancelTimerAlarm()
            } else {
              scheduleTimerAlarm(endDateMillis, category)
            }
            result.success(true)
          }
          "end" -> {
            cancelTimerAlarm()
            result.success(true)
          }
          "startRecording" -> {
            val intent = Intent(this, SermonRecordingForegroundService::class.java)
              .putExtra(
                SermonRecordingForegroundService.EXTRA_START_TIME_MILLIS,
                System.currentTimeMillis(),
              )
            ContextCompat.startForegroundService(this, intent)
            result.success(true)
          }
          "endRecording" -> {
            stopService(Intent(this, SermonRecordingForegroundService::class.java))
            result.success(true)
          }
          else -> result.notImplemented()
        }
      }
  }

  private fun timerAlarmPendingIntent(category: String): PendingIntent {
    val intent = Intent(this, TimerAlarmReceiver::class.java)
      .putExtra(TimerAlarmReceiver.EXTRA_CATEGORY, category)
    return PendingIntent.getBroadcast(
      this, 0, intent,
      PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )
  }

  private fun scheduleTimerAlarm(endDateMillis: Long, category: String) {
    val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
    // Inexact-but-idle-tolerant: this notification is a convenience nudge,
    // not the source of truth — the Dart side always recomputes correctly
    // from the real end time on resume, so a real exact-alarm permission
    // isn't worth the extra Play Store eligibility/review surface.
    alarmManager.setAndAllowWhileIdle(
      AlarmManager.RTC_WAKEUP,
      endDateMillis,
      timerAlarmPendingIntent(category),
    )
  }

  private fun cancelTimerAlarm() {
    val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
    alarmManager.cancel(timerAlarmPendingIntent(""))
  }
}
