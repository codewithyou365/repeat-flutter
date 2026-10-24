import {gamepadKeyLabel} from './gamepad.ts';

// 触发键配置的通用解析：一份配置是 • 分隔的多个按键，每个按键要么是一个可打印字符
// （比如 '.'、','、' '），要么是反斜杠开头的特殊按键名（比如 '\enter'、'\numlock'，
// 这类键不会作为字符出现在输入框的 value 里，只能从 keydown 事件的 e.key 里识别）。
// 分隔符用 • 而不是逗号：逗号本身就是常用的触发键（逐字母朗读默认就是 ','），
// 拿它当分隔符的话这个键没法跟别的键组合配在一起。
export type KeySpec =
    | { type: 'char'; char: string }
    | { type: 'special'; name: string };

// 注意：不 trim 每个 token，是为了保留用户故意配的单个空格键（' '）。
// 长度大于 1 又不是 \xxx 形式的 token 永远不可能匹配到一次按键，直接忽略。
export const parseKeySpecs = (raw: string): KeySpec[] => {
  if (!raw) return [];
  const specs: KeySpec[] = [];
  for (const token of raw.split('•')) {
    if (token === '') continue;
    if (token.startsWith('\\') && token.length > 1) {
      specs.push({type: 'special', name: token.slice(1).toLowerCase()});
    } else if (token.length === 1) {
      specs.push({type: 'char', char: token});
    }
  }
  return specs;
};

export const specsHaveChar = (specs: KeySpec[], ch: string): boolean =>
    specs.some((s) => s.type === 'char' && s.char === ch);

export const specsHaveSpecial = (specs: KeySpec[], name: string): boolean =>
    specs.some((s) => s.type === 'special' && s.name === name);

// 两组按键配置有没有共用的按键，用于触发键之间的冲突校验
export const specsOverlap = (a: KeySpec[], b: KeySpec[]): boolean =>
    a.some((sa) => b.some((sb) => {
      if (sa.type !== sb.type) return false;
      return sa.type === 'char'
          ? sa.char === (sb as { type: 'char'; char: string }).char
          : sa.name === (sb as { type: 'special'; name: string }).name;
    }));

// 把原始配置格式化成人类可读文案，给提示弹窗/展示用
export const formatKeySpecsDisplay = (raw: string, spaceLabel: string): string => {
  const specs = parseKeySpecs(raw);
  if (specs.length === 0) return '';
  return specs.map((s) => {
    if (s.type === 'special') {
      const padLabel = gamepadKeyLabel(s.name);
      if (padLabel) return padLabel;
      return s.name.charAt(0).toUpperCase() + s.name.slice(1);
    }
    return s.char === ' ' ? spaceLabel : s.char;
  }).join(' / ');
};
