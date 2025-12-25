<template>
  <label>
    <div class="typing" ref="containerRef" @click="focusInput">
      <div class="typing-line">
        <template v-for="(group, gIndex) in groups" :key="gIndex">
          <span v-if="group.type === 'word'" class="word"
                @touchstart="handleTouch($event, 'start')"
                @touchmove="handleTouch($event, 'move')"
                @touchend="handleTouch($event, 'end')">
            <span
                v-for="(ch, cIndex) in group.chars"
                :key="cIndex"
                class="typing-char"
                :data-index="ch.index"
                :class="getCharClass(ch.index)"
                :ref="el => setCharRef(el, ch.index)"
                @click="handleCharClick(ch.index)"
                @pointerover="handleCharTouch($event, ch.index)"
                @pointerdown="handleCharTouch($event, ch.index)"
            >
              {{ getDisplayChar(ch.index) }}
            </span>
          </span>
          <span v-else class="typing-char"
                :class="[getCharClass(group.index), group.type === 'space' ? 'space' : '']"
                :ref="el => setCharRef(el, group.index)"
          >
            {{ getDisplayChar(group.index) }}
          </span>
        </template>
      </div>

      <input
          ref="inputRef"
          :disabled="disabled"
          v-model="composingInput"
          @compositionstart="handleCompositionStart"
          @compositionend="handleCompositionEnd"
          @keydown="handleKeydown"
          class="overlay-input"
          autocomplete="off"
          spellcheck="false"
      />
    </div>
  </label>
</template>

<script setup lang="ts">
import {onMounted, ref, nextTick, computed, onBeforeUnmount, watch} from 'vue';

const props = withDefaults(defineProps<{
  disabled: boolean;
  content: string;
  clickFillCharWhenDisabled?: string;
  ignoreContentIndexes: number[];
  ignoreCase: boolean;
  ignorePunctuation: boolean;
}>(), {
  clickFillCharWhenDisabled: '',
});

const userInput = ref('');
const composingInput = ref('');
const inputRef = ref<HTMLInputElement | null>(null);
const containerRef = ref<HTMLElement | null>(null);
const charRefs = ref<HTMLElement[]>([]);
const cursorPos = ref(0);
const minCursorPos = ref(0);
const lastHoveredIndex = ref<number | null>(0);
const chars = computed<string[]>(() => {
  return props.content ? props.content.split('') : [];
});

const isCJK = computed(() => {
  return /[\u4e00-\u9fff\u3040-\u309f\u30a0-\u30ff]/.test(props.content);
});
const disabled = computed(() => {
  return props.disabled;
});
const groups = computed(() => {
  const gs: any[] = [];
  if (isCJK.value) {
    props.content.split('').forEach((char, index) => {
      gs.push({type: char === ' ' ? 'space' : 'char', char, index});
    });
  } else {
    let currentWord: any[] = [];
    props.content.split('').forEach((char, index) => {
      if (char === ' ') {
        if (currentWord.length) {
          gs.push({type: 'word', chars: currentWord});
          currentWord = [];
        }
        gs.push({type: 'space', char, index});
      } else {
        currentWord.push({char, index});
      }
    });
    if (currentWord.length) {
      gs.push({type: 'word', chars: currentWord});
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

onMounted(() => {
  window.addEventListener('resize', positionInput);
  focusInput();
});

onBeforeUnmount(() => {
  window.removeEventListener('resize', positionInput);
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
  if (isComposing.value) {
    return;
  }
  if (newValue.length > 0) {
    applyInput(newValue);
    composingInput.value = '';
  }
});

const isIgnore = (c: string, index: number) => {
  if (props.ignorePunctuation && /\p{P}/u.test(c)) {
    return true;
  }

  return props.ignoreContentIndexes !== undefined &&
      props.ignoreContentIndexes.includes(index);
};

const applyInput = (val: string) => {
  let pos = cursorPos.value;
  let temp = userInput.value;

  for (const char of val) {
    while (pos < props.content.length && isIgnore(props.content[pos], pos)) {
      if (pos >= temp.length) {
        temp += props.content[pos];
      }
      pos++;
    }
    if (pos < temp.length) {
      temp = temp.slice(0, pos) + char + temp.slice(pos + 1);
    } else {
      temp += char;
    }
    pos++;
  }

  while (pos < props.content.length && isIgnore(props.content[pos], pos)) {
    if (pos >= temp.length) {
      temp += props.content[pos];
    }
    pos++;
  }
  userInput.value = temp;
  cursorPos.value = pos;

  // Truncate
  if (userInput.value.length > props.content.length) {
    userInput.value = userInput.value.slice(0, props.content.length);
  }
  if (cursorPos.value > props.content.length) {
    cursorPos.value = props.content.length;
  }
};
const handleTouch = (e: PointerEvent, type: 'start' | 'move' | 'end') => {
  if (disabled.value) {
    if (props.clickFillCharWhenDisabled.length === 1) {

      if (type === 'end') {
        lastHoveredIndex.value = null;
        return;
      }

      const touch = e.touches[0];
      const x = touch.clientX;
      const y = touch.clientY;
      const elem = document.elementFromPoint(x, y) as HTMLElement | null;

      if (elem?.classList.contains('typing-char')) {
        const index = Number(elem.dataset.index);
        if (!Number.isNaN(index) && index !== lastHoveredIndex.value) {
          handleCharTouch(null, index);
          lastHoveredIndex.value = index;
        }
      } else {
        lastHoveredIndex.value = null;
      }

      if (type === 'move') {
        e.preventDefault();
      }
    }
  }
};
const handleCharTouch = (e: PointerEvent | null, index: number) => {
  if (disabled.value && (e == null || e.buttons === 1)) {
    if (props.clickFillCharWhenDisabled.length === 1) {
      composingInput.value = '';
      const pos = index;
      if (pos >= 0 && pos < userInput.value.length && pos < props.content.length) {
        if (isIgnore(props.content[pos], pos)) {
          return;
        }
        let fillChar = props.clickFillCharWhenDisabled;
        if (userInput.value[index] === props.clickFillCharWhenDisabled) {
          fillChar = props.content[index];
        }
        userInput.value =
            userInput.value.slice(0, pos) +
            fillChar +
            userInput.value.slice(pos + 1);
      }
    }
    return;
  }
}
const handleCharClick = (index: number) => {
  if (disabled.value) {
    return;
  }
  cursorPos.value = Math.min(index, userInput.value.length);
  composingInput.value = '';
  positionInput();
  focusInput();
};
const fixCursorPos = () => {
  if (cursorPos.value < minCursorPos.value) {
    userInput.value = props.content.slice(0, minCursorPos.value)
    cursorPos.value = minCursorPos.value;
  }
}
const handleKeydown = (e: KeyboardEvent) => {
  if (isComposing.value) return;

  if (e.key === 'Backspace') {
    let p = cursorPos.value;
    if (cursorPos.value !== userInput.value.length && !isIgnore(props.content[p], p)) {
      p++;
      while (isIgnore(props.content[p], p) && p < userInput.value.length) {
        p++;
      }
      if (p === userInput.value.length) {
        userInput.value = userInput.value.slice(0, cursorPos.value);
        cursorPos.value = userInput.value.length;
      }
    } else {
      p = cursorPos.value;
      while (isIgnore(props.content[p], p) && p < userInput.value.length) {
        p++;
      }
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
          if (cursorPos.value == 0) {
            break;
          }
        }
      }
      fixCursorPos();
      positionInput();
    }
    e.preventDefault();
  } else if (e.key === 'ArrowLeft') {
    if (cursorPos.value > 0) {
      cursorPos.value--;
      while (isIgnore(props.content[cursorPos.value], cursorPos.value)) {
        cursorPos.value--;
      }
      positionInput();
    }
    e.preventDefault();
  } else if (e.key === 'ArrowRight') {
    if (cursorPos.value < userInput.value.length) {
      cursorPos.value++;
      while (isIgnore(props.content[cursorPos.value], cursorPos.value)) {
        cursorPos.value++;
      }
      positionInput();
    }
    e.preventDefault();
  }
};

const getDisplayChar = (index: number) => {
  const originalChar = chars.value[index];
  if (index >= userInput.value.length) {
    if (originalChar === ' ') return '⎵';
    if (isIgnore(originalChar, index)) return originalChar;
    return '';
  } else {
    return userInput.value[index] === ' ' ? '⎵' : userInput.value[index];
  }
};

const getCharClass = (index: number) => {
  const classes: string[] = [];
  const ignored = isIgnore(chars.value[index], index);
  if (index >= userInput.value.length) {
    if (ignored) {
      classes.push('pending-ignore');
    } else {
      classes.push('pending');
    }
  } else {
    const userCh = userInput.value[index];
    const origCh = chars.value[index];
    let isCorrect = userCh === origCh;
    if (props.ignoreCase) {
      isCorrect = userCh.toLowerCase() === origCh.toLowerCase();
    }
    if (ignored && isCorrect) {
      classes.push('ignore-correct');
    } else if (isCorrect) {
      classes.push('correct');
    } else {
      classes.push('wrong');
    }
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

watch(() => props.content, async () => {
  userInput.value = '';
  cursorPos.value = 0;
  charRefs.value = new Array(props.content.length);
  await nextTick();
  minCursorPos.value = 0;
  while (isIgnore(props.content[minCursorPos.value], minCursorPos.value)) {
    minCursorPos.value++;
  }
  fixCursorPos();
  positionInput();
  inputRef.value?.focus();
});

watch([userInput, groups], async () => {
  await nextTick();
  positionInput();
});

defineExpose({
  initUserInput(val: string) {
    userInput.value = val
    cursorPos.value = val.length
    nextTick(positionInput)
  },

  getUserInput() {
    return userInput.value;
  },
})
</script>

<style scoped>
.typing {
  cursor: text;
  user-select: none;
  position: relative;
}

.typing-line {
  display: flex;
  flex-wrap: wrap;
  gap: 4px;
  font-size: 22px;
  line-height: 1.6;
}

.word {
  display: inline-flex;
  flex-wrap: wrap;
  gap: 4px;
}

.typing-char {
  min-width: 14px;
  text-align: center;
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

.ignore-correct {
  color: #3b82f6;
  border-bottom-color: #3b82f6;
}

.space {
  border-bottom: none;
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

@keyframes flash {
  from {
    border-bottom-color: currentColor;
  }
  to {
    border-bottom-color: transparent;
  }
}
</style>