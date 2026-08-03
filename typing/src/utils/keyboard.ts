import {client, Request} from '../api/ws.ts';
import {Path} from './constant.ts';

// 页面跑在 App 内嵌 WebView 里时才是本机（App 加载的是 https://127.0.0.1:port），
// 局域网扫码进来的其它设备 hostname 是那台手机的局域网 IP。
const isLocalWebView = () => {
  const host = location.hostname;
  return host === '127.0.0.1' || host === 'localhost' || host === '::1';
};

/**
 * 请求 App 弹出软键盘。
 *
 * 页面自己调 input.focus() 是弹不出来的：Chromium 只在页面有用户手势时才因聚焦唤起 IME，
 * 而"进入游戏"那一下点击发生在 Flutter 侧，不会传进这个页面。所以让 App 那边走原生的
 * InputMethodManager 帮我们弹。
 *
 * 只在本机 WebView 里发，否则局域网里别人一进游戏就会把主机的键盘弹起来。
 */
export const raiseSoftKeyboard = async () => {
  if (!isLocalWebView()) return;
  try {
    await client.node!.send(new Request({path: Path.showKeyboard}));
  } catch (error) {
    console.error('Failed to raise soft keyboard:', error);
  }
};
