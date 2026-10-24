// 手柄按键接入触发键体系：在配置里写成 \pad0、\pad12 这样的特殊按键名，数字是 Gamepad API
// 里 buttons 的下标。跟键盘的 \enter 一样走 parseKeySpecs / specsHaveSpecial，键盘的 e.key
// 不可能是 pad0 这种值，所以两者不会互相误触发。
// Gamepad API 只能在安全上下文（https / localhost）里用，而且页面打开后要在手柄上先按一下键，
// 浏览器才会把手柄暴露给网页。

export const gamepadKeyName = (index: number) => `pad${index}`;

// mapping === 'standard' 的手柄按钮下标是统一的（Xbox 布局），非标准手柄只能显示下标
const standardButtonLabels = ['A', 'B', 'X', 'Y', 'LB', 'RB', 'LT', 'RT', 'Select', 'Start', 'L3', 'R3', '↑', '↓', '←', '→', 'Home'];

// 不是手柄按键名就返回 null，交给调用方按普通特殊按键显示
export const gamepadKeyLabel = (name: string): string | null => {
  const m = /^pad(\d+)$/.exec(name);
  if (!m) return null;
  const index = Number(m[1]);
  return `Pad ${standardButtonLabels[index] ?? index}`;
};

export type GamepadAvailability = 'ok' | 'insecure' | 'unsupported';

export const gamepadAvailability = (): GamepadAvailability => {
  if (!window.isSecureContext) return 'insecure';
  if (typeof navigator.getGamepads !== 'function') return 'unsupported';
  return 'ok';
};

const readGamepads = (): Gamepad[] => {
  try {
    return navigator.getGamepads().filter((p): p is Gamepad => p !== null);
  } catch {
    // 非安全上下文里有的浏览器会直接抛 SecurityError
    return [];
  }
};

export const connectedGamepadIds = (): string[] => readGamepads().map((p) => p.id);

// Gamepad API 没有"按下"事件，只能每帧轮询按钮状态，自己判断"上一帧没按、这一帧按了"。
// 手柄刚出现时没有上一帧，视为全都没按：让揭示手柄的那一次按键也能触发。
// 返回停止函数，组件卸载时调用。
export const watchGamepadPress = (onPress: (index: number) => void): (() => void) => {
  if (gamepadAvailability() !== 'ok') return () => {};
  const prev = new Map<number, boolean[]>();
  let raf = 0;
  const tick = () => {
    for (const pad of readGamepads()) {
      const before = prev.get(pad.index) ?? [];
      const now = pad.buttons.map((b) => b.pressed);
      prev.set(pad.index, now);
      now.forEach((pressed, i) => {
        if (pressed && !before[i]) onPress(i);
      });
    }
    raf = requestAnimationFrame(tick);
  };
  raf = requestAnimationFrame(tick);
  return () => cancelAnimationFrame(raf);
};
