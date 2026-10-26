import {reactive} from 'vue';

// 单键摩斯码输入：给只有寥寥几个按键的游戏手柄用。一个键，短按是点、长按是划，
// 松手后停顿够久就把攒下的点划翻译成一个字符交出去。

// 码表：字母、数字和几个常用标点。'.' 是点，'-' 是划
export const MORSE_TABLE: Record<string, string> = {
  '.-': 'a', '-...': 'b', '-.-.': 'c', '-..': 'd', '.': 'e', '..-.': 'f', '--.': 'g', '....': 'h',
  '..': 'i', '.---': 'j', '-.-': 'k', '.-..': 'l', '--': 'm', '-.': 'n', '---': 'o', '.--.': 'p',
  '--.-': 'q', '.-.': 'r', '...': 's', '-': 't', '..-': 'u', '...-': 'v', '.--': 'w', '-..-': 'x',
  '-.--': 'y', '--..': 'z',
  '-----': '0', '.----': '1', '..---': '2', '...--': '3', '....-': '4',
  '.....': '5', '-....': '6', '--...': '7', '---..': '8', '----.': '9',
  '.-.-.-': '.', '--..--': ',', '..--..': '?', '.----.': "'", '-.-.--': '!', '-..-.': '/',
  '-.--.': '(', '-.--.-': ')', '---...': ':', '-.-.-.': ';', '-...-': '=', '.-.-.': '+',
  '-....-': '-', '.-..-.': '"', '.--.-.': '@',
};

const CODES = Object.keys(MORSE_TABLE);

// 码表里有没有以 prefix 开头、又比它长的码：没有的话这一串已经到头了，不用再等停顿
export const morseHasLonger = (prefix: string) => CODES.some((c) => c.length > prefix.length && c.startsWith(prefix));
// 码表里有没有以 prefix 开头的码（含它自己）：没有就说明这一串已经敲废了
export const morseIsPrefix = (prefix: string) => CODES.some((c) => c.startsWith(prefix));

export type MorseOptions = {
  dashMs: () => number; // 按住超过这么久算划
  gapMs: () => number;  // 松手后停这么久没再按，就把这一串定下来
  onCommit: (ch: string) => void;
  onInvalid: (code: string) => void; // 敲出了码表里没有的串
};

// 状态全放 reactive 里，展示面板直接读：
// code 已经定下来的点划；pressing 正按着；pressId/releaseId 每次按下/松开加一，
// 面板拿它当 key 重启进度条动画。
export const createMorseInput = (options: MorseOptions) => {
  const state = reactive({code: '', pressing: false, pressId: 0, releaseId: 0, lastChar: '', lastCode: ''});
  let pressAt = 0;
  let gapTimer = 0;

  const clearGap = () => {
    window.clearTimeout(gapTimer);
    gapTimer = 0;
  };

  const finish = () => {
    clearGap();
    const code = state.code;
    state.code = '';
    if (!code) return;
    const ch = MORSE_TABLE[code];
    state.lastCode = code;
    state.lastChar = ch ?? '';
    if (ch) options.onCommit(ch);
    else options.onInvalid(code);
  };

  const down = () => {
    if (state.pressing) return; // 键盘长按会连发 keydown
    clearGap();
    state.pressing = true;
    state.pressId++;
    pressAt = performance.now();
  };

  const up = () => {
    if (!state.pressing) return;
    state.pressing = false;
    state.releaseId++;
    state.code += performance.now() - pressAt >= options.dashMs() ? '-' : '.';
    // 已经敲废了，或者已经是一条到头的码，就不必等停顿
    if (!morseIsPrefix(state.code) || !morseHasLonger(state.code)) {
      finish();
      return;
    }
    gapTimer = window.setTimeout(finish, options.gapMs());
  };

  // 换句、页面切走时调：丢掉正在敲的半截，别带到下一处
  const reset = () => {
    clearGap();
    state.code = '';
    state.pressing = false;
  };

  return {state, down, up, reset};
};
