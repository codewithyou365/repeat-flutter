package org.codewithyou365.repeat_flutter

import android.content.Context
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
        val webView = findWebView(window.decorView) ?: return false
        webView.isFocusable = true
        webView.isFocusableInTouchMode = true
        webView.requestFocus()

        val imm = getSystemService(Context.INPUT_METHOD_SERVICE) as? InputMethodManager ?: return false
        val shown = imm.showSoftInput(webView, InputMethodManager.SHOW_IMPLICIT)
        if (!shown) {
            // 刚进游戏时 WebView 可能还没完成布局、还没拿到窗口焦点，第一次会返回 false，
            // 排到下一帧再补一次。
            webView.post {
                webView.requestFocus()
                imm.showSoftInput(webView, InputMethodManager.SHOW_IMPLICIT)
            }
        }
        return shown
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
        private const val KEYBOARD_CHANNEL = "repeat_flutter/keyboard"
    }
}
