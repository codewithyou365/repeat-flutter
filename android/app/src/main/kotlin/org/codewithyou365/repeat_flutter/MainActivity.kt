package org.codewithyou365.repeat_flutter

import android.content.Context
import android.util.Log
import android.view.KeyEvent
import android.view.View
import android.view.ViewGroup
import android.view.inputmethod.InputMethodManager
import android.webkit.WebView
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, KEYBOARD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "showSoftInputForWebView" -> result.success(showSoftInputForWebView())
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * 硬件（蓝牙）键盘的按键，在 WebView 拿着焦点时直接投给 WebView，绕开 Flutter。
     *
     * 默认链路是 ViewRootImpl → DecorView → Activity.dispatchKeyEvent → FlutterView.dispatchKeyEvent
     * → 子 View(WebView)。问题出在 FlutterView：它在往下传之前先让自己的 KeyboardManager 处理，
     * 而 KeyboardManager 会把字符键喂给 TextInputPlugin 最后一次创建的 InputConnection 并当作
     * "已处理"，于是按键永远到不了作为子 View 的 WebView。只要之前在 Flutter 页面聚焦过任何
     * 输入框（比如"改课堂名"），游戏里的蓝牙键盘就整个失灵——软键盘那条路走的是 WebView 自己的
     * InputConnection，不经过这里，所以只有接硬件键盘才暴露。
     *
     * 只在 WebView 就是当前焦点时才拦；BACK 之类的系统键仍旧走原来的链路交给 Flutter。
     */
    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        val focused = currentFocus
        if (focused is WebView && event.keyCode != KeyEvent.KEYCODE_BACK) {
            if (focused.dispatchKeyEvent(event)) {
                return true
            }
        }
        return super.dispatchKeyEvent(event)
    }

    /**
     * 让内嵌 WebView 弹出软键盘。
     *
     * 页面里 JS 的 input.focus() 单独是不够的：Chromium 只在页面存在用户手势（user activation）
     * 时才因元素聚焦唤起 IME，而"进入游戏"那一下点击发生在 Flutter 这边，不会传进 WebView 页面，
     * 所以页面从头到尾没有用户激活，键盘不会自己起来。只能从原生这边显式请求。
     *
     * flutter_inappwebview 6 的 InAppWebViewController 没有 requestFocus()，也没暴露相关设置，
     * 所以这里直接在视图树里把 WebView 找出来。useHybridComposition 默认为 true，WebView 是
     * 真实的原生 View，一定在 decorView 下面。
     */
    private fun showSoftInputForWebView(): Boolean {
        val webView = findWebView(window.decorView)
        if (webView == null) {
            Log.i(TAG, "showSoftInputForWebView: webView not found")
            return false
        }
        val imm = getSystemService(Context.INPUT_METHOD_SERVICE) as? InputMethodManager ?: return false
        focusWebView(webView, imm)

        val shown = imm.showSoftInput(webView, InputMethodManager.SHOW_IMPLICIT)
        // 刚进游戏时 WebView 可能还没完成布局、还没拿到窗口焦点，第一次会返回 false；
        // 接了硬件键盘时软键盘本来就不会弹（SHOW_IMPLICIT 被系统抑制），也是 false。
        // 两种情况都排到下一帧再补一次焦点，硬件键盘的按键分发只认焦点，跟软键盘弹不弹无关。
        webView.post {
            focusWebView(webView, imm)
            imm.showSoftInput(webView, InputMethodManager.SHOW_IMPLICIT)
        }
        return shown
    }

    /**
     * 把 Android 层的输入焦点抢到 WebView 上。
     *
     * 硬件（蓝牙）键盘的按键是按"当前聚焦的 View"分发的，跟软键盘无关。默认情况下焦点在
     * FlutterView 上，FlutterView.dispatchKeyEvent 会先让 Flutter 的 KeyboardManager 处理，
     * 而 KeyboardManager 又会把按键喂给 TextInputPlugin 最后一次创建的 InputConnection ——
     * 只要 Flutter 侧曾经聚焦过任何一个输入框（比如"改课堂名"），这个 InputConnection 就会把
     * 字符键全部吃掉，按键根本传不到作为子 View 的 WebView，网页里一个 keydown 都收不到。
     * 所以这里必须显式把 FlutterView 的焦点摘掉，再让 WebView 拿到焦点。
     */
    private fun focusWebView(webView: WebView, imm: InputMethodManager) {
        val before = currentFocus
        if (before != null && before !== webView) {
            before.clearFocus()
        }
        webView.isFocusable = true
        webView.isFocusableInTouchMode = true
        val requested = webView.requestFocus()
        // 焦点换人之后要让 IME 重新建连接，否则 IME 还挂在原来那个 View 的 InputConnection 上
        imm.restartInput(webView)
        Log.i(
            TAG,
            "focusWebView: before=${before?.javaClass?.simpleName} requested=$requested " +
                "webViewFocused=${webView.isFocused} after=${currentFocus?.javaClass?.simpleName}",
        )
    }

    private fun findWebView(view: View): WebView? {
        if (view is WebView) {
            return view
        }
        if (view is ViewGroup) {
            for (i in 0 until view.childCount) {
                findWebView(view.getChildAt(i))?.let { return it }
            }
        }
        return null
    }

    companion object {
        private const val TAG = "RepeatKeyboard"
        private const val KEYBOARD_CHANNEL = "repeat_flutter/keyboard"
    }
}
