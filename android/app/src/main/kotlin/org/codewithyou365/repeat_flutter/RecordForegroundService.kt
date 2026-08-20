package org.codewithyou365.repeat_flutter

import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.IBinder
import androidx.core.app.ServiceCompat

/**
 * 息屏录音会话跑着的时候挂一条常驻通知，类型是 microphone。
 *
 * 为什么必须是独立的 Service，而不是给 GameForegroundService 加个类型参数：
 * 1. Service 是单例组件。游戏和录音万一同时开着，一次 stopService() 会把另一个的通知和
 *    免冻一起干掉——那是对现有游戏行为的硬回归，而且极难查。
 * 2. 前台服务类型是按组件在 manifest 里声明的。一个 Service 同时声明 dataSync|microphone，
 *    会让游戏那条路径也一起受 Android 14 对麦克风前台服务的前置条件约束
 *    （没有 RECORD_AUDIO 就直接抛 SecurityException）。
 * 3. 独立的渠道和通知 id，用户看到的才是诚实的"正在录音"，也对得上系统的麦克风隐私指示器。
 *
 * 启动时机很关键：必须在 Activity 还可见的时候起，起完再 startStream。
 * Android 11+ 的 while-in-use 规则会把后台启动的麦克风前台服务**静默静音**——
 * 不报错，只是从此拿到一路全零的音频。见 Dart 侧 ForegroundService.start 的注释。
 *
 * 配额：Android 15 的每天 6 小时前台服务上限管的是 dataSync 和 mediaProcessing，
 * microphone 不在其列，所以这条路径不受那个限制。
 */
class RecordForegroundService : Service() {

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // 必须用带类型的重载，理由同 GameForegroundService：targetSdk 34+ 光靠 manifest 不够。
        ServiceCompat.startForeground(
            this,
            NOTIFICATION_ID,
            ForegroundNotification.build(
                this,
                CHANNEL_ID,
                R.string.record_session_channel_name,
                R.string.record_session_notification_title,
                R.string.record_session_notification_text,
            ),
            ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE,
        )
        // 被系统杀掉后不要自己重启：那时 Dart 侧的录音早就没了，重启只会留一条骗人的通知。
        return START_NOT_STICKY
    }

    companion object {
        private const val CHANNEL_ID = "record_session"
        private const val NOTIFICATION_ID = 1002
    }
}
