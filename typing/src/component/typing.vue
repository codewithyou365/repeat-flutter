<template>
  <label>
    <div class="typing" :class="{ 'no-scroll': paintMode, 'hide-pending': hidePending }" ref="containerRef" @click="focusInput"
         @touchstart="handleTouch($event, 'start')"
         @touchmove="handleTouch($event, 'move')"
         @touchend="handleTouch($event, 'end')"
         @touchcancel="handleTouch($event, 'end')"
         @pointerdown="handleTouch($event, 'start')"
         @pointermove="handleTouch($event, 'move')"
         @pointerup="handleTouch($event, 'end')"
    >
      <div class="typing-line">
        <template v-for="(group, gIndex) in groups" :key="gIndex">
          <div v-if="group.type === 'newline'" class="newline-br"></div>
          <span v-else-if="group.type === 'word'" class="word">
            <span
                v-for="(ch, cIndex) in group.chars"
                :key="cIndex"
                class="typing-char"
                :data-index="ch.index"
                :style="getCharStyle(ch.index)"
                :class="getCharClass(ch.index)"
                :ref="el => setCharRef(el, ch.index)"
                @click="handleCharClick(ch.index)"
            >
              {{ getDisplayChar(ch.index) }}
            </span>
          </span>
          <span v-else class="typing-char"
                :data-index="group.index"
                :style="getCharStyle(group.index)"
                :class="[getCharClass(group.index), group.type === 'space' ? 'space' : '']"
                :ref="el => setCharRef(el, group.index)"
                @click="handleCharClick(group.index)"
          >
            {{ getDisplayChar(group.index) }}
          </span>
        </template>
      </div>

      <input
          ref="inputRef"
          :type="inputType"
          :disabled="disabled"
          v-model="composingInput"
          @compositionstart="handleCompositionStart"
          @compositionend="handleCompositionEnd"
          @keydown="handleKeydown"
          class="overlay-input"
          autocomplete="off"
          autocapitalize="off"
          autocorrect="off"
          spellcheck="false"
      />
    </div>
  </label>
</template>

<script setup lang="ts">
import {onMounted, ref, nextTick, computed, onBeforeUnmount, watch} from 'vue';
import {useStore} from 'vuex';
import {parseKeySpecs, specsHaveChar, specsHaveSpecial} from '../utils/keyTrigger.ts';
import {gamepadKeyName, watchGamepadPress} from '../utils/gamepad.ts';

const props = withDefaults(defineProps<{
  disabled: boolean;
  content: string;
  clickFillCharWhenDisabled?: string;
  ignoreContentIndexes?: number[];
  ignoreCase: boolean;
  changeToRightCaseWhenIgnoreCase: boolean;
  ignorePunctuation: boolean;
  ignoreNumber?: boolean;
  ignoreSpace?: boolean;
  blockOnWrong?: boolean;
  manualPlayTrigger?: string;
  spellPlayTrigger?: string;
  hintTrigger?: string;
  maskTrigger?: string;
  deleteTrigger?: string;
  assistTriggers?: string[];
  keyMapping?: string;
  touchColor?: string;
  // 只显示已经打出来的内容：还没打到的格子（含下划线、被忽略的标点数字）整片藏起来，
  // 免得剩余长度和标点结构提前把答案透出去。占位仍在，排版不会跳。
  hidePending?: boolean;
  // 熟词在 content 里的位置（含头含尾），由父组件按熟词库算好。
  // 只用来标紫色和判断"熟词跳过键"按下时能不能跳——熟词不再有任何自动行为
  // （以前光标一到词首就响提示音、敲对首字母就整词补全，都太打断打字节奏，已经去掉）。
  familiarRanges?: { start: number; end: number }[];
  // 熟词跳过键：按下时光标所在的词是熟词就整词跳过，否则父组件响一声提示音
  familiarSkipTrigger?: string;
}>(), {
  clickFillCharWhenDisabled: '',
  touchColor: '',
  ignoreContentIndexes: () => [],
  ignoreNumber: false,
  ignoreSpace: false,
  blockOnWrong: false,
  manualPlayTrigger: '',
  spellPlayTrigger: '',
  hintTrigger: '',
  maskTrigger: '',
  deleteTrigger: '',
  assistTriggers: () => [],
  keyMapping: '',
  hidePending: false,
  familiarRanges: () => [],
  familiarSkipTrigger: '',
});

// T9 风格按键映射："a:abc•q:def" -> 按下 a 时，目标字母是 a/b/c 都算对；按下 q 时，
// 目标字母是 d/e/f 都算对。分组里混入的数字（比如老式九宫格键盘的助记写法 "a:2abc"）会被
// 过滤掉，不参与匹配，纯粹是可选的书写习惯。分隔符用 • 而不是逗号，因为有的用户键盘打不出逗号。
const keyMap = computed<Record<string, string>>(() => {
  const map: Record<string, string> = {};
  if (!props.keyMapping) return map;
  for (const pair of props.keyMapping.split('•')) {
    const [rawKey, rawGroup] = pair.split(':');
    if (!rawKey || !rawGroup) continue;
    const key = rawKey.trim().toLowerCase();
    const letters = rawGroup.replace(/[^a-zA-Z]/g, '').toLowerCase();
    if (key.length === 1 && letters) {
      map[key] = letters;
    }
  }
  return map;
});

// 各触发键配置支持用 • 分隔的多个按键，其中反斜杠开头的是特殊按键名（如 \enter、\numlock）。
// 可打印字符在 applyInput 里逐字符匹配输入框 value，特殊按键在 handleKeydown 里按 e.key 匹配。
const manualPlaySpecs = computed(() => parseKeySpecs(props.manualPlayTrigger));
const spellPlaySpecs = computed(() => parseKeySpecs(props.spellPlayTrigger));
const hintSpecs = computed(() => parseKeySpecs(props.hintTrigger));
const maskSpecs = computed(() => parseKeySpecs(props.maskTrigger));
const deleteSpecs = computed(() => parseKeySpecs(props.deleteTrigger));
const familiarSkipSpecs = computed(() => parseKeySpecs(props.familiarSkipTrigger));
// 每条辅助触控绑定各自的配置，raw 是绑定原本的 key 字符串（用于 emit 出去让父组件按原样匹配）
const assistSpecsList = computed(() => props.assistTriggers.map((raw) => ({raw, specs: parseKeySpecs(raw)})));

const emit = defineEmits<{
  // skip=true 的字符是"熟词跳过"补出来的，不是用户敲的、也不是间隔模式补的：
  // 父组件收到要跳过朗读和熟词计时（跳过时已经整词念过一遍了）。
  (e: 'charFilled', index: number, char: string, auto: boolean, correct: boolean, skip: boolean): void;
  (e: 'completed'): void;
  (e: 'manualPlay', word: string): void;
  (e: 'spellPlay', word: string): void;
  (e: 'hintTrigger'): void;
  (e: 'maskTrigger'): void;
  // bounds 是按下这个键时光标所在词在 content 里的起止下标（含头含尾），不在词上时为 null。
  // "单词提问"要拿它去标下划线；普通的辅助触控绑定用不到，忽略即可。
  (e: 'assistTrigger', key: string, bounds: { start: number; end: number } | null): void;
  // 已输入内容发生变化（打字/退格/清词）。父组件用它把进度同步给服务端做多人协作。
  // changedIndexes 是本次新落下的字符下标，用来记"这几个字是谁敲的"；退格/清词传空数组。
  // 注意：只在用户自己的操作里发，initUserInput（应用远端下发的内容）不发，否则会来回回声。
  (e: 'userInputChange', userInput: string, changedIndexes: number[]): void;
  // 按了熟词跳过键。skipped=true 表示确实跳过了一个熟词（word 是那个词，父组件负责朗读），
  // false 表示光标所在的词不是熟词/已经打完了，什么都没动，父组件响一声提示音就行。
  (e: 'familiarSkip', word: string, skipped: boolean): void;
}>();

const store = useStore();

// password 类型会绕过输入法，直接给出纯 ASCII 键盘，适合练英文。
// 一旦设置了按键映射（T9），映射依赖的是物理按键，输入法候选词/联想会打乱映射逻辑，
// 所以只要 keyMapping 非空就强制用 password 类型，不受全局键盘设置影响。
const inputType = computed(() => {
  if (props.keyMapping) return 'password';
  return store.getters.currentKeyboardType === 'password' ? 'password' : 'text';
});

const contentIndexToColor = ref<Record<number, string>>({});
const userInput = ref('');
const composingInput = ref('');
const inputRef = ref<HTMLInputElement | null>(null);
const containerRef = ref<HTMLElement | null>(null);
const charRefs = ref<HTMLElement[]>([]);
const cursorPos = ref(0);
const minCursorPos = ref(0);
const lastHoveredIndex = ref<number | null>(null); // 防抖用的上一个索引

const chars = computed<string[]>(() => {
  return props.content ? props.content.split('') : [];
});

// 只显示已打内容时，词尾被 autoFill 顺手带出来的空格/标点先别露出来：一露出来就等于告诉用户
// "这个词打完了"（apple 后面冒出空格，就知道不是 apples）。从这个下标起的已填字符按未打处理，
// 等用户敲下一个词的首字母时再一起显示；整句打完则全部显示。
const hiddenTailStart = computed(() => {
  const len = userInput.value.length;
  if (!props.hidePending || len >= props.content.length) return Infinity;
  let i = len;
  while (i > 0) {
    const c = chars.value[i - 1];
    if (!(c === ' ' || /\p{P}/u.test(c)) || !isIgnore(c, i - 1)) break;
    i--;
  }
  return i;
});

const isCJK = computed(() => {
  return /[\u4e00-\u9fff\u3040-\u309f\u30a0-\u30ff]/.test(props.content);
});

const disabled = computed(() => {
  return props.disabled;
});

// 划字模式：只有它成立时 handleTouch 才会吃掉手势，别的场景要把纵向滚动让给页面
const paintMode = computed(() => {
  return disabled.value && (props.clickFillCharWhenDisabled.length === 1 || !!props.touchColor);
});

const groups = computed(() => {
  const gs: any[] = [];
  const contentChars = props.content.split('');

  if (isCJK.value) {
    contentChars.forEach((char, index) => {
      if (char === '\n') {
        gs.push({ type: 'newline', char, index });
      } else {
        gs.push({ type: char === ' ' ? 'space' : 'char', char, index });
      }
    });
  } else {
    let currentWord: any[] = [];
    contentChars.forEach((char, index) => {
      if (char === '\n') {
        if (currentWord.length) {
          gs.push({ type: 'word', chars: currentWord });
          currentWord = [];
        }
        gs.push({ type: 'newline', char, index });
      } else if (char === ' ') {
        if (currentWord.length) {
          gs.push({ type: 'word', chars: currentWord });
          currentWord = [];
        }
        gs.push({ type: 'space', char, index });
      } else {
        currentWord.push({ char, index });
      }
    });
    if (currentWord.length) {
      gs.push({ type: 'word', chars: currentWord });
    }
  }
  return gs;
});
const isComposing = ref(false);

const setCharRef = (el: Element | null, index: number) => {
  if (el) {
    charRefs.value[index] = el as HTMLElement;
  }
};

// 手柄按键当成 \pad0 这样的特殊按键，跟键盘特殊按键走同一套匹配
let stopGamepadWatch = () => {};

onMounted(() => {
  window.addEventListener('resize', positionInput);
  focusInput();
  stopGamepadWatch = watchGamepadPress((index) => {
    if (props.disabled) return;
    handleSpecialKeyTrigger(gamepadKeyName(index));
  });
});

onBeforeUnmount(() => {
  window.removeEventListener('resize', positionInput);
  stopGamepadWatch();
});

const focusInput = async () => {
  await nextTick();
  inputRef.value?.focus();
  positionInput();
};

const handleCompositionStart = () => {
  isComposing.value = true;
};

const handleCompositionEnd = (e: Event) => {
  isComposing.value = false;
  const input = e.target as HTMLInputElement;
  const newValue = input.value;
  applyInput(newValue);
  composingInput.value = '';
};

watch(composingInput, (newValue) => {
  if (isComposing.value) return;
  if (newValue.length > 0) {
    applyInput(newValue);
    composingInput.value = '';
  }
});

const isIgnore = (c: string, index: number) => {
  if (props.ignoreSpace && c === ' ') {
    return true;
  }
  if (props.ignorePunctuation && /\p{P}/u.test(c)) {
    return true;
  }
  if (props.ignoreNumber && /\p{N}/u.test(c)) {
    return true;
  }
  return props.ignoreContentIndexes && props.ignoreContentIndexes.includes(index);
};

// skip=true 的是"熟词跳过"补出来的字符：父组件收到 charFilled 时要跳过朗读和熟词计时
type FilledEvent = { index: number; auto: boolean; skip?: boolean };

// 把 index 处新落下的字符标记为一个待通知事件；auto=true 表示是被自动跳过/填充的
// （忽略的空格、标点或 ignoreContentIndexes），不是用户敲的
const isCorrectAt = (index: number, ch: string) => {
  const origCh = chars.value[index] ?? '';
  const group = keyMap.value[ch.toLowerCase()];
  if (group) {
    // 这个键已经被映射成组合键，不再代表它本来的字母，只按分组里的字母判断对错
    // （比如只配了 q:def，输入 q 时目标字母就算是 q 本身也算错，因为 q 已经被映射走了）
    return group.includes(origCh.toLowerCase());
  }
  const chNorm = props.ignoreCase ? ch.toLowerCase() : ch;
  const origNorm = props.ignoreCase ? origCh.toLowerCase() : origCh;
  return chNorm === origNorm;
};

const isWordChar = (c: string) => /[\p{L}\p{N}]/u.test(c);

// 找到 index 位置所在（或紧邻左侧）的连续字母/数字片段，用于"手动播放当前光标所在单词"
// 找到 index 位置所在（或紧邻左侧）单词的起止下标；不在任何单词内时返回 null
const getWordBounds = (index: number): { start: number; end: number } | null => {
  const content = props.content;
  let i = index;
  if (i >= content.length || !isWordChar(content[i])) {
    i = index - 1;
  }
  if (i < 0 || !isWordChar(content[i])) {
    return null;
  }
  let start = i;
  while (start > 0 && isWordChar(content[start - 1])) start--;
  let end = i;
  while (end < content.length - 1 && isWordChar(content[end + 1])) end++;
  return {start, end};
};

const getWordAt = (index: number): string => {
  const bounds = getWordBounds(index);
  return bounds ? props.content.slice(bounds.start, bounds.end + 1) : '';
};

// 以 index 为词首的熟词区间；index 不是任何熟词的词首就返回 null
const familiarRangeStartingAt = (index: number) => {
  return props.familiarRanges.find((r) => r.start === index) ?? null;
};

// 熟词跳过：光标所在的词是熟词、且还没打完时，把它剩下的字母一次性补上（连同紧跟其后的
// 标点空格），并让父组件把整词念出来；否则什么都不动，只通知父组件响一声提示音。
//
// 直接改 live 的 userInput/cursorPos（跟 clearCurrentWord 一个写法），所以在 applyInput
// 里必须走 pendingTriggerEmits 延后执行，不然会被那边末尾的 userInput.value = temp 覆盖掉。
const doFamiliarSkip = () => {
  const bounds = getWordBounds(cursorPos.value);
  const range = bounds ? familiarRangeStartingAt(bounds.start) : null;
  // 词已经打完（光标停在词尾之后）也算没跳成：这时想再听一遍该用手动播放键
  if (!range || cursorPos.value > range.end) {
    emit('familiarSkip', '', false);
    return;
  }
  const word = props.content.slice(range.start, range.end + 1);
  const filled: FilledEvent[] = [];
  let temp = userInput.value;
  let pos = cursorPos.value;
  const fillAt = (i: number) => {
    if (i < temp.length) {
      temp = temp.slice(0, i) + props.content[i] + temp.slice(i + 1);
    } else {
      temp += props.content[i];
    }
    filled.push({index: i, auto: true, skip: true});
  };
  for (let i = pos; i <= range.end; i++) {
    fillAt(i);
  }
  pos = range.end + 1;
  // 词后面紧跟的标点/空格照常带出来，跟正常打字时的 autoFill 一致
  while (pos < props.content.length && isIgnore(props.content[pos], pos)) {
    if (pos >= temp.length) {
      fillAt(pos);
    }
    pos++;
  }
  userInput.value = temp;
  cursorPos.value = pos;
  // 同步要排在 emitFilledEvents 前面，理由同 applyInput：后者可能 emit('completed')
  emitUserInputChange(filled.map((item) => item.index));
  emitFilledEvents(filled);
  emit('familiarSkip', word, true);
  nextTick(positionInput);
};

const inFamiliarRange = (index: number) => {
  return props.familiarRanges.some((r) => index >= r.start && index <= r.end);
};

const emitUserInputChange = (changedIndexes: number[]) => {
  emit('userInputChange', userInput.value, changedIndexes);
};

// 把光标所在单词的已输入内容清空，重新回到这个单词开头（会重新自动带出单词开头那段自动填充的字符）
const clearCurrentWord = () => {
  const bounds = getWordBounds(cursorPos.value);
  if (!bounds) return;
  let temp = userInput.value.slice(0, bounds.start);
  let pos = bounds.start;
  while (pos < props.content.length && isIgnore(props.content[pos], pos)) {
    if (pos >= temp.length) temp += props.content[pos];
    pos++;
  }
  userInput.value = temp;
  cursorPos.value = pos;
  emitUserInputChange([]);
  nextTick(positionInput);
};

const applyInput = (val: string) => {
  let pos = cursorPos.value;
  let temp = userInput.value;
  const before = userInput.value;
  const filled: FilledEvent[] = [];
  let blocked = false;
  // 触发键（手动播放/逐字母朗读/提示）的 emit 不能在循环内立刻发出：这几个事件的处理方（父组件）
  // 可能会同步地反过来改 userInput/cursorPos（比如逐字母朗读后清空当前单词），如果在这里立刻
  // emit，父组件改完之后，本函数末尾 `userInput.value = temp; cursorPos.value = pos;` 还会
  // 执行，用循环开始时快照的 temp/pos 把父组件刚做的修改覆盖掉。所以这里只记录，等本函数
  // 自己该写的状态都写完之后，再统一在最后触发。
  const pendingTriggerEmits: (() => void)[] = [];

  const autoFill = () => {
    while (pos < props.content.length && isIgnore(props.content[pos], pos)) {
      if (pos >= temp.length) {
        temp += props.content[pos];
        filled.push({index: pos, auto: true});
      }
      pos++;
    }
  };

  for (const char of val) {
    if (specsHaveChar(manualPlaySpecs.value, char)) {
      const word = getWordAt(pos);
      pendingTriggerEmits.push(() => emit('manualPlay', word));
      continue; // 触发字符本身不写入内容，也不推进 pos
    }
    if (specsHaveChar(spellPlaySpecs.value, char)) {
      const word = getWordAt(pos);
      pendingTriggerEmits.push(() => emit('spellPlay', word));
      continue; // 触发字符本身不写入内容，也不推进 pos
    }
    if (specsHaveChar(hintSpecs.value, char)) {
      pendingTriggerEmits.push(() => emit('hintTrigger'));
      continue; // 触发字符本身不写入内容，也不推进 pos
    }
    if (specsHaveChar(maskSpecs.value, char)) {
      pendingTriggerEmits.push(() => emit('maskTrigger'));
      continue; // 触发字符本身不写入内容，也不推进 pos
    }
    // 删除触发键：等同于按了一次退格。跟其它触发键一样只记录、不立刻执行——doBackspace 改的是
    // userInput/cursorPos，而本函数末尾还会用循环里的快照 temp/pos 覆盖回去，立刻执行等于白删。
    if (specsHaveChar(deleteSpecs.value, char)) {
      pendingTriggerEmits.push(() => doBackspace());
      continue; // 触发字符本身不写入内容，也不推进 pos
    }
    // 熟词跳过键：跟删除键同理，doFamiliarSkip 改的是 userInput/cursorPos，必须延后执行
    if (specsHaveChar(familiarSkipSpecs.value, char)) {
      pendingTriggerEmits.push(() => doFamiliarSkip());
      continue; // 触发字符本身不写入内容，也不推进 pos
    }
    // 绑定到 App 辅助触控按钮的键，数量由用户配置，可以有多个，每条绑定又可以配多个按键
    const assistMatch = assistSpecsList.value.find(({specs}) => specsHaveChar(specs, char));
    if (assistMatch) {
      // 跟 manualPlay 一样在这里就把词的位置取好：触发字符不写进内容，
      // 但后面还会继续处理这一批输入，等 emit 真正执行时光标未必还在这个词上。
      const bounds = getWordBounds(pos);
      const raw = assistMatch.raw;
      pendingTriggerEmits.push(() => emit('assistTrigger', raw, bounds));
      continue; // 触发字符本身不写入内容，也不推进 pos
    }

    autoFill();
    if (pos >= props.content.length) break;

    const correct = isCorrectAt(pos, char);
    const isMapped = keyMap.value[char.toLowerCase()] !== undefined;

    // T9 映射键（比如 x:4ghi）的物理键字符本身不是要输入的字母，只是一个"数字键"。
    // 打错且要拦截时不把这个物理键字符写进内容，否则会在格子里显示出无意义的键字符
    // （比如按 x 想打 g/h/i，却在别处显示出 "x"）。仍然记录 filled，让父组件照常给出
    // 打错反馈并原地拦住。普通（未映射）按键打错时保持原样，还是显示用户敲下的那个字符。
    if (!(props.blockOnWrong && !correct && isMapped)) {
      if (pos < temp.length) {
        temp = temp.slice(0, pos) + char + temp.slice(pos + 1);
      } else {
        temp += char;
      }
    }
    filled.push({index: pos, auto: false});

    if (props.blockOnWrong && !correct) {
      blocked = true;
      break; // 打错了，原地停住，不允许继续往下推进
    }
    pos++;
  }

  if (!blocked) {
    autoFill();
  }

  userInput.value = temp;
  cursorPos.value = pos;

  if (userInput.value.length > props.content.length) {
    userInput.value = userInput.value.slice(0, props.content.length);
  }
  if (cursorPos.value > props.content.length) {
    cursorPos.value = props.content.length;
  }

  // 同步要排在 emitFilledEvents 前面：后者可能 emit('completed')，父组件收到就去通知服务端
  // "这句打完了"，得保证那之前服务端已经拿到完整的输入串。
  // 打错且被拦住的映射键不会写进 temp（userInput 没变），这种就不必同步了。
  if (userInput.value !== before) {
    emitUserInputChange(filled.map((item) => item.index));
  }
  emitFilledEvents(filled, !blocked);
  for (const fn of pendingTriggerEmits) fn();
};

const emitFilledEvents = (filled: FilledEvent[], allowCompletion = true) => {
  for (const item of filled) {
    const origCh = chars.value[item.index];
    const userCh = userInput.value[item.index];
    const correct = item.auto ? true : isCorrectAt(item.index, userCh ?? '');
    emit('charFilled', item.index, origCh, item.auto, correct, item.skip === true);
  }
  if (allowCompletion && filled.length > 0 && props.content.length > 0 && userInput.value.length >= props.content.length) {
    emit('completed');
  }
};

// 统一滑动处理枢纽
const handleTouch = (e: any, type: 'start' | 'move' | 'end') => {
  if (!disabled.value) return;

  if (props.clickFillCharWhenDisabled.length === 1 || props.touchColor) {
    if (type === 'end') {
      lastHoveredIndex.value = null;
      return;
    }

    // 坐标提取：兼容 touch 和 mouse
    let clientX = 0, clientY = 0;
    if (e.touches && e.touches.length > 0) {
      clientX = e.touches[0].clientX;
      clientY = e.touches[0].clientY;
    } else {
      clientX = e.clientX;
      clientY = e.clientY;
      // 鼠标模式下：如果没有按住左键，直接退出
      if (e.type === 'pointermove' && e.buttons !== 1) return;
    }

    const elem = document.elementFromPoint(clientX, clientY) as HTMLElement | null;

    if (elem?.classList.contains('typing-char')) {
      const index = Number(elem.dataset.index);

      // 关键防抖：只有当前划到的 Index 和上一次不一样，才触发修改
      if (!Number.isNaN(index) && index !== lastHoveredIndex.value) {
        handleCharTouch(null, index);
        lastHoveredIndex.value = index;
      }
    } else {
      // 划出文字区域时，也要重置索引
      lastHoveredIndex.value = null;
    }

    // 阻止页面滚动
    if (type === 'move' && e.cancelable) {
      e.preventDefault();
    }
  }
};

// 真正的修改逻辑，现在被 handleTouch 严格保护，不会被乱触发
const handleCharTouch = (e: PointerEvent | null, index: number) => {
  if (disabled.value && (e == null || e.buttons === 1)) {
    if (props.clickFillCharWhenDisabled.length === 1) {
      composingInput.value = '';
      const pos = index;

      if (pos >= 0 && pos < userInput.value.length && pos < props.content.length) {
        if (isIgnore(props.content[pos], pos)) return;

        let fillChar = props.clickFillCharWhenDisabled;
        if (userInput.value[index] === props.clickFillCharWhenDisabled) {
          fillChar = props.content[index];
        }

        userInput.value =
            userInput.value.slice(0, pos) +
            fillChar +
            userInput.value.slice(pos + 1);
      }
    } else if (props.touchColor) {
      const pos = index;
      if (isIgnore(props.content[pos], pos)) return;
      if (contentIndexToColor.value[pos]) {
        delete contentIndexToColor.value[pos];
      } else {
        contentIndexToColor.value[pos] = props.touchColor;
      }
    }
  }
};

const handleCharClick = (index: number) => {
  if (disabled.value) return;
  cursorPos.value = Math.min(index, userInput.value.length);
  composingInput.value = '';
  positionInput();
  focusInput();
};

const fixCursorPos = () => {
  if (cursorPos.value < minCursorPos.value) {
    userInput.value = props.content.slice(0, minCursorPos.value);
    cursorPos.value = minCursorPos.value;
  }
};

// 退格：物理 Backspace 键和用户配置的"删除触发键"共用这一份逻辑
const doBackspace = () => {
  let p = cursorPos.value;
  const before = userInput.value;
  if (cursorPos.value !== userInput.value.length && !isIgnore(props.content[p], p)) {
    p++;
    while (isIgnore(props.content[p], p) && p < userInput.value.length) p++;
    if (p === userInput.value.length) {
      userInput.value = userInput.value.slice(0, cursorPos.value);
      cursorPos.value = userInput.value.length;
    }
  } else {
    p = cursorPos.value;
    while (isIgnore(props.content[p], p) && p < userInput.value.length) p++;
    if (p === userInput.value.length) {
      userInput.value = userInput.value.slice(0, cursorPos.value);
      cursorPos.value = userInput.value.length;
    }
    if (cursorPos.value === userInput.value.length && cursorPos.value > 0) {
      userInput.value = userInput.value.slice(0, cursorPos.value - 1) + userInput.value.slice(cursorPos.value);
      cursorPos.value--;
      while (isIgnore(props.content[cursorPos.value], cursorPos.value)) {
        userInput.value = userInput.value.slice(0, cursorPos.value - 1) + userInput.value.slice(cursorPos.value);
        cursorPos.value--;
        if (cursorPos.value == 0) break;
      }
    }
    fixCursorPos();
    positionInput();
  }
  if (userInput.value !== before) {
    emitUserInputChange([]);
  }
};

// 特殊按键（Enter、NumLock 等）不会作为字符出现在 input 的 value 里，只能在 keydown 阶段
// 按 e.key 识别。命中就直接执行对应动作并返回 true，交给 handleKeydown 去 preventDefault。
// 手柄按键也从这里进来，keyName 是 pad0 这样的名字。
const handleSpecialKeyTrigger = (keyName: string): boolean => {
  if (specsHaveSpecial(manualPlaySpecs.value, keyName)) {
    emit('manualPlay', getWordAt(cursorPos.value));
    return true;
  }
  if (specsHaveSpecial(spellPlaySpecs.value, keyName)) {
    emit('spellPlay', getWordAt(cursorPos.value));
    return true;
  }
  if (specsHaveSpecial(hintSpecs.value, keyName)) {
    emit('hintTrigger');
    return true;
  }
  if (specsHaveSpecial(maskSpecs.value, keyName)) {
    emit('maskTrigger');
    return true;
  }
  if (specsHaveSpecial(deleteSpecs.value, keyName)) {
    doBackspace();
    return true;
  }
  if (specsHaveSpecial(familiarSkipSpecs.value, keyName)) {
    doFamiliarSkip();
    return true;
  }
  const assistMatch = assistSpecsList.value.find(({specs}) => specsHaveSpecial(specs, keyName));
  if (assistMatch) {
    emit('assistTrigger', assistMatch.raw, getWordBounds(cursorPos.value));
    return true;
  }
  return false;
};

const handleKeydown = (e: KeyboardEvent) => {
  if (isComposing.value) return;

  if (handleSpecialKeyTrigger(e.key.toLowerCase())) {
    e.preventDefault();
    return;
  }

  if (e.key === 'Backspace') {
    doBackspace();
    e.preventDefault();
  } else if (e.key === 'ArrowLeft') {
    if (cursorPos.value > 0) {
      cursorPos.value--;
      while (isIgnore(props.content[cursorPos.value], cursorPos.value)) cursorPos.value--;
      positionInput();
    }
    e.preventDefault();
  } else if (e.key === 'ArrowRight') {
    if (cursorPos.value < userInput.value.length) {
      cursorPos.value++;
      while (isIgnore(props.content[cursorPos.value], cursorPos.value)) cursorPos.value++;
      positionInput();
    }
    e.preventDefault();
  }
};

const getDisplayChar = (index: number) => {
  const originalChar = chars.value[index];
  if (originalChar === '\n') return '';
  if (index >= userInput.value.length) {
    if (originalChar === ' ') return '⎵';
    if (isIgnore(originalChar, index)) return originalChar;
    return '';
  } else {
    return userInput.value[index] === ' ' ? '⎵' : userInput.value[index];
  }
};

const getCharStyle = (index: number) => {
  const originalChar = chars.value[index];
  let color: string = contentIndexToColor.value[index];
  if (color) {
    let borderBottomColor = color;
    if (color.indexOf(',') != -1) {
      const colors: string[] = color.split(',');
      color = colors[0];
      borderBottomColor = colors[1];
    } else if (isIgnore(originalChar, index)) {
      borderBottomColor = '#999';
    }
    return {color: color, borderBottomColor: borderBottomColor, opacity: 1};
  }
  return {};
};

const getCharClass = (index: number) => {
  const classes: string[] = [];
  const ignored = isIgnore(chars.value[index], index);
  if (index >= hiddenTailStart.value) {
    classes.push('pending-ignore');
  } else if (index >= userInput.value.length) {
    if (ignored) classes.push('pending-ignore');
    else classes.push('pending');
    // 还没打到的熟词换个下划线颜色：一眼能看出"这个词只要敲首字母"，
    // 免得没留意提示音、把整个词敲下去，后面的字母全落到下一个词上
    if (inFamiliarRange(index)) classes.push('familiar');
  } else {
    const userCh = userInput.value[index];
    const origCh = chars.value[index];
    // 判断格子里已有的字符对不对：如果它本身就等于目标字符，那它一定是对的，绝不能再把它
    // 当成一次 T9 击键喂回 isCorrectAt。否则当目标字符恰好又是个被映射走的键时（比如目标
    // 'e'，而 e:9wxyz），changeToRightCase 把格子归一成 'e' 后，再按击键语义判就成了
    // "wxyz 里不含 e"→误判为错、标红。只有跟目标不一致的字符才走击键映射判断。
    const matchesOrig = props.ignoreCase
        ? userCh.toLowerCase() === origCh.toLowerCase()
        : userCh === origCh;
    const isCorrect = matchesOrig || isCorrectAt(index, userCh);
    if (isCorrect && userCh !== origCh && props.changeToRightCaseWhenIgnoreCase) {
      userInput.value =
          userInput.value.slice(0, index) +
          origCh +
          userInput.value.slice(index + 1);
    }
    if (ignored && isCorrect) classes.push('ignore-correct');
    else if (isCorrect) classes.push('correct');
    else classes.push('wrong');
  }
  if (index === cursorPos.value && index < chars.value.length) {
    classes.push('flashing');
  }
  return classes;
};

const positionInput = () => {
  if (!inputRef.value || !containerRef.value || !charRefs.value.length) return;
  const pos = cursorPos.value;
  const targetPos = pos < props.content.length ? pos : props.content.length - 1;
  const targetEl = charRefs.value[targetPos];
  if (targetEl) {
    // 内容超过一屏时，光标走到看不见的行要把它带回可视区（block:'nearest' 在已可见时是空操作）
    targetEl.scrollIntoView({block: 'nearest', inline: 'nearest'});
    const targetRect = targetEl.getBoundingClientRect();
    const containerRect = containerRef.value.getBoundingClientRect();
    inputRef.value.style.left = `${targetRect.left - containerRect.left}px`;
    inputRef.value.style.top = `${targetRect.top - containerRect.top}px`;
    inputRef.value.style.width = `${targetRect.width}px`;
    inputRef.value.style.height = `${targetRect.height}px`;
    inputRef.value.style.fontSize = getComputedStyle(targetEl).fontSize;
    inputRef.value.style.lineHeight = getComputedStyle(targetEl).lineHeight;
  }
};

// 内容刚换、下面这个 watch 还没跑完（它中间 await 了一次 nextTick，之后会把 userInput 重置成自动填充的那段），
// 这期间父组件 initUserInput 进来的值先存着，等 watch 跑完再套上，否则会被重置冲掉
let contentLoading = false;
let pendingInitInput: string | null = null;

const applyInitUserInput = (val: string) => {
  userInput.value = val;
  cursorPos.value = val.length;
  nextTick(positionInput);
};

watch(() => props.content, async () => {
  contentLoading = true;
  userInput.value = '';
  cursorPos.value = 0;
  charRefs.value = new Array(props.content.length);
  await nextTick();

  // 内容一开始就可能有一串被忽略（自动填充）的字符（比如间隔显示模式下第一个字母就是自动显示的），
  // 这段要提前把它们写进 userInput，minCursorPos/cursorPos 才会落在第一个真正需要输入的位置上，
  // 同时把这批字符也当作“已落下的字符”通知出去（用于父组件同步朗读等）
  let pos = 0;
  let temp = '';
  const filled: FilledEvent[] = [];
  while (pos < props.content.length && isIgnore(props.content[pos], pos)) {
    temp += props.content[pos];
    filled.push({index: pos, auto: true});
    pos++;
  }
  userInput.value = temp;
  cursorPos.value = pos;
  minCursorPos.value = pos;

  fixCursorPos();
  positionInput();
  inputRef.value?.focus();
  // 刚加载新内容时的这批自动填充绝不能触发 'completed'：如果整段内容恰好全是被忽略/自动填充的
  // 字符（比如很短又被整词遮罩、或间隔模式下把每个字母都藏了），userInput 一上来就 >= 内容长度，
  // 一旦允许完成就会 emit('completed') -> 父组件 tap('tapLeft') -> refresh() 换下一段 -> 又全自动
  // 填充 -> 再次 completed……形成 refresh 无限递归，每轮还会堆一次网络请求和 TTS 队列，最终内存
  // 撑爆导致网页闪退。所以这里显式禁止完成事件。
  emitFilledEvents(filled, false);
  contentLoading = false;
  if (pendingInitInput !== null) {
    applyInitUserInput(pendingInitInput);
    pendingInitInput = null;
  }
}, {immediate: true});

watch([userInput, groups], async () => {
  await nextTick();
  positionInput();
});

defineExpose({
  initUserInput(val: string) {
    if (contentLoading) {
      pendingInitInput = val;
      return;
    }
    applyInitUserInput(val);
  },
  initContentIndexToColor(val: Record<number, string>) {
    contentIndexToColor.value = val;
  },
  focus() {
    inputRef.value?.focus();
  },
  getUserInput() {
    return userInput.value;
  },
  getContentIndexToColor() {
    return contentIndexToColor.value;
  },
  getCurrentWord() {
    return getWordAt(cursorPos.value);
  },
  // 按内容下标取整词：父组件做整词朗读时用，保证读的是原文而不是自己攒的串
  getWordAt(index: number) {
    return getWordAt(index);
  },
  // 按内容下标取整词的起止位置：父组件给熟词计时用
  getWordBoundsAt(index: number) {
    return getWordBounds(index);
  },
  clearCurrentWord() {
    clearCurrentWord();
  },
});
</script>

<style scoped>
.typing {
  cursor: text;
  user-select: none;
  position: relative;
  /* 只锁横向手势，纵向留给外层滚动：内容多到一屏放不下时手指还能把页面划上去 */
  touch-action: pan-y;
}

/* 只显示已打内容：用 visibility 而不是 display，保留占位，切换时排版不跳 */
.typing.hide-pending .pending,
.typing.hide-pending .pending-ignore {
  visibility: hidden;
}

/* 划字模式（disabled + 点击/涂色填字）下手指是用来涂格子的，这时才彻底禁掉滚动 */
.typing.no-scroll {
  touch-action: none;
}

.typing-line {
  display: flex;
  flex-wrap: wrap;
  gap: 4px;
  font-size: 22px;
  line-height: 1.6;
}
.newline-br {
  flex-basis: 100%;
  height: 0;
  margin: 0;
  padding: 0;
}
.word {
  display: inline-flex;
  flex-wrap: wrap;
  gap: 4px;
}

.typing-char {
  /* 固定宽度，防止日文和圆点切换时抖动 */
  width: 1.2em;
  min-width: 1.2em;
  text-align: center;
  font-family: 'Courier New', Courier, monospace;
  display: inline-block;
  overflow: hidden;
  white-space: nowrap;

  border-bottom: 2px solid #ccc;
  min-height: 1.6em;
  position: relative;
}

.pending {
  color: transparent;
}

.pending-ignore {
  color: #999;
  border-bottom-color: #999;
}

.correct {
  color: #22c55e;
  border-bottom-color: #22c55e;
}

.wrong {
  color: #ef4444;
  border-bottom-color: #ef4444;
}

/* 熟词（还没打到的部分）：只要敲首字母就会整词补全 */
.familiar {
  border-bottom-color: #a855f7;
}

.ignore-correct {
  color: #3b82f6;
  border-bottom-color: #3b82f6;
}

.space {
  border-bottom-color: transparent;
}

.pending.space {
  color: #ccc;
}

.overlay-input {
  position: absolute;
  color: transparent;
  background: transparent;
  border: none;
  outline: none;
  caret-color: transparent;
  padding: 0;
  margin: 0;
  z-index: 10;
}

.overlay-input:disabled {
  pointer-events: none;
}

.flashing {
  display: inline-block;
  vertical-align: bottom;
  animation: blink 1s steps(1) infinite;
}

@keyframes blink {
  0%, 50% {
    opacity: 1;
  }
  50.01%, 100% {
    opacity: 0.3;
  }
}
</style>