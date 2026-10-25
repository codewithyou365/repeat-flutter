<template>
  <div class="word-ask" :class="themeClass">
    <!-- 顶部：本节答案，问过的重点词标出来，点一下滚到对应的卡片 -->
    <div class="answer-bar">
      <div class="answer-label">{{ t('wordAskKeyWords') }}</div>
      <div class="answer-text">
        <template v-for="(part, idx) in answerParts" :key="idx">
          <span v-if="part.index >= 0" class="key-word" @click="scrollToItem(part.index)">{{ part.text }}</span>
          <span v-else>{{ part.text }}</span>
        </template>
      </div>
    </div>

    <div class="item-list">
      <div v-if="items.length === 0" class="empty">{{ t('wordAskTipEmpty') }}</div>
      <div
          v-for="(item, index) in items"
          :key="index"
          :id="`ask-${index}`"
          class="item"
          :class="{ flash: flashingIndex === index }"
      >
        <div class="item-head">
          <span class="item-word">{{ item.word }}</span>
          <span class="item-actions">
            <Voice width="18px" height="18px" class="item-speak" @click="speak(item.text)"/>
            <Del width="18px" height="18px" class="item-del" @click="removeWord(item.word)"/>
          </span>
        </div>
        <div class="item-text">{{ item.text }}</div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import {computed, onMounted, ref} from 'vue';
import {client, Request, Response} from '../../api/ws.ts';
import {Path} from '../../utils/constant.ts';
import {useStore} from 'vuex';
import {useI18n} from 'vue-i18n';
import {Voice, Del} from '@nutui/icons-vue';
import {showDialog, showToast} from '@nutui/nutui';

type AskItem = { word: string; text: string };

const {t} = useI18n();
const store = useStore();
const field = ref('t');
const answer = ref('');
const items = ref<AskItem[]>([]);
const flashingIndex = ref<number | null>(null);

const themeClass = computed(() => (store.getters.currentTheme === 'dark' ? 'theme-dark' : 'theme-light'));

// 把答案切成「普通文本 / 重点词」两种片段。每个重点词只标它在答案里第一次出现的位置，
// index 是它在 items 里第一条的下标（点它滚过去）；没出现在答案里的词（答案改过）就只在下面的列表里。
const answerParts = computed(() => {
  const text = answer.value;
  const spans: { start: number; end: number; index: number }[] = [];
  items.value.forEach((item, index) => {
    if (spans.some((s) => s.index >= 0 && items.value[s.index].word === item.word)) return;
    let from = 0;
    while (from <= text.length) {
      const at = text.indexOf(item.word, from);
      if (at < 0) break;
      const end = at + item.word.length;
      if (!spans.some((s) => at < s.end && s.start < end)) {
        spans.push({start: at, end, index});
        break;
      }
      from = at + 1;
    }
  });
  spans.sort((a, b) => a.start - b.start);
  const parts: { text: string; index: number }[] = [];
  let pos = 0;
  for (const s of spans) {
    if (s.start > pos) parts.push({text: text.slice(pos, s.start), index: -1});
    parts.push({text: text.slice(s.start, s.end), index: s.index});
    pos = s.end;
  }
  if (pos < text.length) parts.push({text: text.slice(pos), index: -1});
  return parts;
});

const scrollToItem = (index: number) => {
  document.getElementById(`ask-${index}`)?.scrollIntoView({behavior: 'smooth', block: 'center'});
  flashingIndex.value = index;
  window.setTimeout(() => {
    if (flashingIndex.value === index) flashingIndex.value = null;
  }, 1200);
};

// 点喇叭是用户主动要听，不看静音开关
const speak = async (text: string) => {
  if (!client.node) return;
  try {
    await client.node.send(new Request({
      path: Path.tip,
      headers: {'jsMethod': 'Tip.tts'},
      data: {text, type: field.value},
    }));
  } catch (error) {
    console.error('Error sending tts:', error);
  }
};

// 删的是重点词本身：它问过的每一条都删，正文摘要里也去掉这个词
const removeWord = (word: string) => {
  showDialog({
    title: t('wordAskDelete'),
    content: t('wordAskDeleteConfirm', {word}),
    okText: t('confirm'),
    cancelText: t('cancel'),
    onOk: async () => {
      if (!client.node) return;
      try {
        const res = await client.node.send(new Request({
          path: Path.tip,
          headers: {'jsMethod': 'Tip.removeWord'},
          data: {word, prefix: t('wordAskKeyWords')},
        }));
        if (res.status !== 200 || res.error) {
          showToast.fail(res.error || 'error');
          return;
        }
        await refresh();
      } catch (error) {
        console.error('Error removing word:', error);
      }
    },
  });
};

const refresh = async () => {
  const res = await client.node!.send(new Request({
    path: Path.tip,
    headers: {'jsMethod': 'Tip.asks'},
  }));
  const data = res.data || {};
  field.value = typeof data.field === 'string' && data.field ? data.field : 't';
  answer.value = typeof data.answer === 'string' ? data.answer : '';
  items.value = Array.isArray(data.items) ? data.items : [];
};

onMounted(async () => {
  await refresh();
  client.controllers.set('gameRefresh', async () => {
    await refresh();
    return new Response();
  });
});
</script>

<style scoped>
.word-ask {
  display: flex;
  flex-direction: column;
  min-height: 100%;
  background: var(--bg);
  color: var(--fg);
}

.theme-light {
  --bg: #f7f2e8;
  --fg: #2c2218;
  --card: #fffdf8;
  --border: rgba(0, 0, 0, 0.08);
  --accent: #b5532a;
  --muted: rgba(44, 34, 24, 0.55);
  --flash: #fbe3c8;
}

.theme-dark {
  --bg: #1d1a17;
  --fg: #ece4d8;
  --card: #2a2622;
  --border: rgba(255, 255, 255, 0.1);
  --accent: #f0a272;
  --muted: rgba(236, 228, 216, 0.55);
  --flash: #4a3626;
}

.answer-bar {
  position: sticky;
  top: 0;
  z-index: 2;
  background: var(--bg);
  padding: 12px 16px;
  border-bottom: 1px solid var(--border);
}

.answer-label {
  font-size: 12px;
  color: var(--muted);
  margin-bottom: 4px;
}

.answer-text {
  font-size: 18px;
  line-height: 1.6;
  white-space: pre-wrap;
  word-break: break-word;
}

.key-word {
  color: var(--accent);
  text-decoration: underline;
  text-underline-offset: 3px;
  cursor: pointer;
}

.item-list {
  padding: 12px 16px;
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.empty {
  color: var(--muted);
  font-size: 14px;
  padding: 24px 0;
  text-align: center;
}

.item {
  background: var(--card);
  border: 1px solid var(--border);
  border-radius: 10px;
  padding: 10px 12px;
  transition: background 0.3s;
}

.item.flash {
  background: var(--flash);
}

.item-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
  margin-bottom: 6px;
}

.item-word {
  font-size: 16px;
  font-weight: 600;
  color: var(--accent);
}

.item-speak {
  cursor: pointer;
  opacity: 0.7;
  flex-shrink: 0;
}

.item-actions {
  display: flex;
  align-items: center;
  gap: 14px;
  flex-shrink: 0;
}

.item-del {
  cursor: pointer;
  opacity: 0.55;
}

.item-text {
  font-size: 14px;
  line-height: 1.6;
  white-space: pre-wrap;
  word-break: break-word;
}
</style>
