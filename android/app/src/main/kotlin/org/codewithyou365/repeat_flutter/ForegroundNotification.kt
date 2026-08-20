package org.codewithyou365.repeat_flutter

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat

/**
 * 前台服务那条常驻通知的构建。两个前台服务（游戏服务器、录音会话）共用这一份。
 *
 * 抽出来是因为两个 Service 的通知长得一模一样，只有渠道 id 和文案不同；
 * 但它们必须是两个独立的 Service 组件，不能合并成一个（理由见 [RecordForegroundService]）。
 */
object ForegroundNotification {

    fun build(
        service: Service,
        channelId: String,
        channelNameRes: Int,
        titleRes: Int,
        textRes: Int,
    ): Notification {
        val manager = service.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                service.getString(channelNameRes),
                // LOW：不出声、不弹横幅，只是常驻在通知栏
                NotificationManager.IMPORTANCE_LOW,
            )
            channel.setShowBadge(false)
            manager.createNotificationChannel(channel)
        }

        val launch = Intent(service, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingFlags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        val contentIntent = PendingIntent.getActivity(service, 0, launch, pendingFlags)

        return NotificationCompat.Builder(service, channelId)
            .setSmallIcon(android.R.drawable.stat_notify_sync)
            .setContentTitle(service.getString(titleRes))
            .setContentText(service.getString(textRes))
            .setContentIntent(contentIntent)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
            .build()
    }
}
