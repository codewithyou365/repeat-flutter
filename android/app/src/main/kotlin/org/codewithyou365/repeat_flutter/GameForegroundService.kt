package org.codewithyou365.repeat_flutter

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat

/**
 * 游戏服务器跑着的时候挂一条常驻通知，把进程钉在前台重要度上。
 *
 * 为什么需要：游戏的 HttpServer/WebSocket、just_audio 的判停定时器全都跑在 Flutter 主 isolate 上。
 * 手机一锁屏，Android 12+ 的 cached-app freezer 会把后台进程整个冻住，于是局域网上的学生端连不上、
 * 音频也不会停在 qEnd。前台服务是唯一可靠的免冻手段。
 *
 * 这个 Service 本身什么都不做，只负责那条通知——真正的服务器仍在 Dart 侧，
 * 由 GameWebServer.start()/stop() 通过 MethodChannel 启停它，生命周期严格对齐。
 *
 * 配额提醒：Android 15 起 dataSync 类型的前台服务有每天累计 6 小时的上限，超了会被系统停掉。
 * 课堂/练习这种量级够用，真撞上了表现是通知消失 + 进程恢复可被冻结。
 */
class GameForegroundService : Service() {

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // 必须用带类型的重载：targetSdk 34+ 光靠 manifest 里的 foregroundServiceType 不够，
        // 运行时不报类型的话系统的 FGS 类型记账拿不到它（logcat 会警告 "does not have any types"），
        // 某些路径还会直接抛 MissingForegroundServiceTypeException。
        ServiceCompat.startForeground(
            this,
            NOTIFICATION_ID,
            buildNotification(),
            ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC,
        )
        // 被系统杀掉后不要自己重启：那时 Dart 侧的服务器早就没了，重启只会留一条骗人的通知。
        return START_NOT_STICKY
    }

    private fun buildNotification(): Notification {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                getString(R.string.game_server_channel_name),
                // LOW：不出声、不弹横幅，只是常驻在通知栏
                NotificationManager.IMPORTANCE_LOW,
            )
            channel.setShowBadge(false)
            manager.createNotificationChannel(channel)
        }

        val launch = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingFlags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        val contentIntent = PendingIntent.getActivity(this, 0, launch, pendingFlags)

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.stat_notify_sync)
            .setContentTitle(getString(R.string.game_server_notification_title))
            .setContentText(getString(R.string.game_server_notification_text))
            .setContentIntent(contentIntent)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
            .build()
    }

    companion object {
        private const val CHANNEL_ID = "game_server"
        private const val NOTIFICATION_ID = 1001
    }
}
