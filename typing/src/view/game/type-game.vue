<template>
  <label>
    <div class="typing-game" ref="containerRef" @click="focusInput">
      <div class="typing-line">
        <template v-for="(group, gIndex) in groups" :key="gIndex">
          <span v-if="group.type === 'word'" class="word">
             <span
                 v-for="(ch, cIndex) in group.chars"
                 :key="cIndex"
                 class="typing-char"
                 :class="getCharClass(ch.index)"
                 :ref="el => setCharRef(el, ch.index)"
                 @click="handleCharClick(ch.index)"
             >
              {{ getDisplayChar(ch.index) }}
            </span>
          </span>
          <span v-else class="typing-char" :class="[getCharClass(group.index), group.type === 'space' ? 'space' : '']"
                :ref="el => setCharRef(el, group.index)" @click="handleCharClick(group.index)">
            {{ getDisplayChar(group.index) }}
          </span>
        </template>
      </div>

      <input
          ref="inputRef"
          v-model="composingInput"
          @compositionstart="handleCompositionStart"
          @compositionend="handleCompositionEnd"
          @keydown="handleKeydown"
          class="overlay-input"
          autocomplete="off"
          spellcheck="false"
      />
    </div>
    <nut-overlay v-model:visible="overlayVisible">
      <div class="overlay-body">
        <div class="overlay-content">
          <Loading1/>
        </div>
      </div>
    </nut-overlay>
  </label>
</template>
<script setup lang="ts">
import {onMounted, ref, nextTick, computed, onBeforeUnmount, watch} from "vue";
import {bus, EventName, RefreshGameType} from "../../api/bus.ts";
import {client, Request} from "../../api/ws.ts";
import {GetVerseContentReq, GetVerseContentRes, Path} from "../../utils/constant.ts";
import {Loading1} from "@nutui/icons-vue";
import {useRoute, useRouter} from 'vue-router';

const route = useRoute();
const router = useRouter();

const userInput = ref('');
const composingInput = ref('');
const inputRef = ref<HTMLInputElement | null>(null);
const containerRef = ref<HTMLElement | null>(null);
const charRefs = ref<HTMLElement[]>([]);
const cursorPos = ref(0);

const content = ref('');
const chars = computed<string[]>(() => {
  return content.value ? content.value.split('') : [];
});

const isCJK = computed(() => {
  return /[\u4e00-\u9fff\u3040-\u309f\u30a0-\u30ff]/.test(content.value);
});

const groups = computed(() => {
  const gs: any[] = [];
  if (isCJK.value) {
    content.value.split('').forEach((char, index) => {
      gs.push({type: char === ' ' ? 'space' : 'char', char, index});
    });
  } else {
    let currentWord: any[] = [];
    content.value.split('').forEach((char, index) => {
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

const overlayVisible = ref(false);
let refreshGame: RefreshGameType;

const isComposing = ref(false);

const setCharRef = (el: Element | null, index: number) => {
  if (el) {
    charRefs.value[index] = el as HTMLElement;
  }
};

onMounted(async () => {
  refreshGame = RefreshGameType.from(route.query);

  await refresh(refreshGame);
  bus().on(EventName.RefreshGame, (data: RefreshGameType) => {
    refreshGame = data;
    refresh(data);
  });
  window.addEventListener('resize', positionInput);
});
onBeforeUnmount(() => {
  bus().off(EventName.RefreshGame);
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

const applyInput = (val: string) => {
  let pos = cursorPos.value;
  let temp = userInput.value;

  for (const char of val) {
    if (pos < temp.length) {
      temp = temp.slice(0, pos) + char + temp.slice(pos + 1);
    } else {
      temp += char;
    }
    pos++;
  }
  userInput.value = temp;
  cursorPos.value = pos;

  // Truncate
  if (userInput.value.length > content.value.length) {
    userInput.value = userInput.value.slice(0, content.value.length);
  }
  if (cursorPos.value > content.value.length) {
    cursorPos.value = content.value.length;
  }
};

const handleCharClick = (index: number) => {
  cursorPos.value = Math.min(index, userInput.value.length);
  composingInput.value = '';
  positionInput();
  focusInput();
};

const handleKeydown = (e: KeyboardEvent) => {
  if (isComposing.value) return;

  if (e.key === 'Backspace') {
    if (cursorPos.value > 0) {
      userInput.value = userInput.value.slice(0, cursorPos.value - 1) + userInput.value.slice(cursorPos.value);
      cursorPos.value--;
      positionInput();
    }
    e.preventDefault();
  } else if (e.key === 'Delete') {
    if (cursorPos.value < userInput.value.length) {
      userInput.value = userInput.value.slice(0, cursorPos.value) + userInput.value.slice(cursorPos.value + 1);
      positionInput();  // Cursor stays in place
    }
    e.preventDefault();
  } else if (e.key === 'ArrowLeft') {
    if (cursorPos.value > 0) {
      cursorPos.value--;
      positionInput();
    }
    e.preventDefault();
  } else if (e.key === 'ArrowRight') {
    if (cursorPos.value < userInput.value.length) {
      cursorPos.value++;
      positionInput();
    }
    e.preventDefault();
  }
};

const getDisplayChar = (index: number) => {
  const originalChar = chars.value[index];
  if (index >= userInput.value.length) {
    return originalChar === ' ' ? '⎵' : '';
  } else {
    return userInput.value[index] === ' ' ? '⎵' : userInput.value[index];
  }
};
const getCharClass = (index: number) => {
  const classes: string[] = [];
  if (index >= userInput.value.length) {
    classes.push('pending');
  } else {
    classes.push(userInput.value[index] === chars.value[index] ? 'correct' : 'wrong');
  }
  if (index === cursorPos.value && index < chars.value.length) {
    classes.push('flashing');
  }
  return classes;
};
const refresh = async (refreshGame: RefreshGameType) => {
  try {

    overlayVisible.value = true;
    const data: GetVerseContentReq = {
      verseId: refreshGame.verseId,
    };

    const req = new Request({path: Path.getVerseContent, data});
    const res0 = await client.node!.send(req);
    const res = GetVerseContentRes.from(res0.data);
    const contentJson = JSON.parse(res.content);
    content.value = contentJson?.a ?? '';
    await router.replace({
      query: {
        verseId: refreshGame.verseId,
      },
    });
    charRefs.value = new Array(content.value.length);
    userInput.value = '';
    cursorPos.value = 0;
    await nextTick();
    positionInput();
  } catch (error) {
    console.error('Failed to refresh game:', error);
  } finally {
    overlayVisible.value = false;
  }
}

const positionInput = () => {
  if (!inputRef.value || !containerRef.value || !charRefs.value.length) return;

  const pos = cursorPos.value;
  const targetPos = pos < content.value.length ? pos : content.value.length - 1;
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

watch([userInput, groups], async () => {
  await nextTick();
  positionInput();
});
</script>
<style scoped>
.typing-game {
  padding: 8px;
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

.correct {
  color: #22c55e;
  border-bottom-color: #22c55e;
}

.wrong {
  color: #ef4444;
  border-bottom-color: #ef4444;
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