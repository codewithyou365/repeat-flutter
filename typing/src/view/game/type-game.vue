<template>
  <div v-if="isAdmin" style="margin: 8px">
    <nut-cell :title="t('ignoreCase')">
      <template #link>
        <nut-switch v-model="ignoreCase" @change="setIgnoreCase"/>
      </template>
    </nut-cell>
    <nut-cell :title="t('ignorePunctuation')">
      <template #link>
        <nut-switch v-model="ignorePunctuation" @change="setIgnorePunctuation"/>
      </template>
    </nut-cell>
    <nut-cell :title="t('intervalDisplay')">
      <template #link>
        <nut-radio-group v-model="intervalMode" direction="horizontal" @change="setIntervalMode">
          <nut-radio label="none">{{ t('intervalNone') }}</nut-radio>
          <nut-radio label="oddHidden">{{ t('intervalOddHidden') }}</nut-radio>
          <nut-radio label="evenHidden">{{ t('intervalEvenHidden') }}</nut-radio>
        </nut-radio-group>
      </template>
    </nut-cell>
    <nut-cell :title="t('ttsRate')">
      <template #link>
        <nut-radio-group v-model="ttsRate" direction="horizontal" @change="setTtsRate">
          <nut-radio :label="0.25">0.25x</nut-radio>
          <nut-radio :label="0.5">0.5x</nut-radio>
          <nut-radio :label="0.75">0.75x</nut-radio>
          <nut-radio :label="1">1.0x</nut-radio>
        </nut-radio-group>
      </template>
    </nut-cell>
    <nut-cell :title="t('manualTtsRate')">
      <template #link>
        <nut-radio-group v-model="manualTtsRate" direction="horizontal" @change="setManualTtsRate">
          <nut-radio :label="0.25">0.25x</nut-radio>
          <nut-radio :label="0.5">0.5x</nut-radio>
          <nut-radio :label="0.75">0.75x</nut-radio>
          <nut-radio :label="1">1.0x</nut-radio>
        </nut-radio-group>
      </template>
    </nut-cell>
    <nut-cell :title="t('manualPlayTrigger')">
      <template #link>
        <nut-input
            v-model="manualPlayTrigger"
            maxlength="1"
            style="text-align: right"
            @blur="setManualPlayTrigger(manualPlayTrigger)"
        />
      </template>
    </nut-cell>
    <nut-cell :title="t('speakLetters')">
      <template #link>
        <nut-switch v-model="speakLetters" @change="setSpeakLetters"/>
      </template>
    </nut-cell>
  </div>
  <nut-cell v-else-if="cantPlayForMaintain">
    {{ t('cantPlayForMaintain') }}
  </nut-cell>
  <div v-else-if="ready" class="type-game-container">
    <div class="info-bar">
      <Voice class="info-icon" width="18px" height="18px" @click="speakCurrentWord"/>
      <Ask class="info-icon" width="18px" height="18px" @click="showTips"/>
    </div>
    <div class="typing-content">
      <Typing
          ref="typingRef"
          :content="content"
          :disabled="false"
          :ignore-case="ignoreCase"
          :change-to-right-case-when-ignore-case="true"
          :ignore-punctuation="ignorePunctuation"
          :ignore-content-indexes="ignoreContentIndexes"
          :ignore-space="true"
          :block-on-wrong="true"
          :manual-play-trigger="manualPlayTrigger"
          @char-filled="onCharFilled"
          @completed="onCompleted"
          @manual-play="onManualPlay"
      />
    </div>

    <div class="actions">
      <nut-button shape="square" type="info" @pointerdown.prevent="tap('tapLeft')">
        {{ labels.left }}
      </nut-button>
      <nut-button shape="square" type="info" @pointerdown.prevent="tap('tapMiddle')">
        {{ labels.middle }}
      </nut-button>
      <nut-button shape="square" type="info" @pointerdown.prevent="tap('tapRight')">
        {{ labels.right }}
      </nut-button>
    </div>
  </div>
</template>
<script setup lang="ts">
import {onMounted, ref, inject, Ref, reactive, computed} from 'vue';
import {client, Request, Response} from '../../api/ws.ts';
import {Path} from '../../utils/constant.ts';
import Typing from '../../component/typing.vue';
import {useStore} from "vuex";
import {useI18n} from "vue-i18n";
import {Ask, Voice} from '@nutui/icons-vue';

const {t} = useI18n();
const store = useStore();

const ignoreCase = ref(false);
const ignorePunctuation = ref(false);
const intervalMode = ref<'none' | 'oddHidden' | 'evenHidden'>('none');
const ttsRate = ref(1);
const speakLetters = ref(false);
const manualTtsRate = ref(0.5);
const manualPlayTrigger = ref('.');
const ignoreContentIndexes = ref<number[]>([]);
const adminEnable = ref(false);
const adminId = ref(0);
const content = ref('');
const typingRef = ref<InstanceType<typeof Typing>>();
const labels = reactive({
  left: '',
  middle: '',
  right: ''
});

const overlayVisible = inject<Ref<boolean>>('overlayVisible')!;
const tipDialogVisible = inject<Ref<boolean>>('tipDialogVisible')!
const tipDialogContent = inject<Ref<string>>('tipDialogContent')!

const ready = computed(() => {
  return adminId.value !== 0;
});
const cantPlayForMaintain = computed(() => {
  return adminEnable.value && adminId.value != store.getters.currentUserId;
});

const isAdmin = computed(() => {
  return adminEnable.value && adminId.value == store.getters.currentUserId;
});


const showTips = () => {

  const formatStatus = (val: boolean) => val ? t('enabled') : t('disabled');

  const formatIntervalMode = (mode: string) => {
    if (mode === 'oddHidden') return t('intervalOddHidden');
    if (mode === 'evenHidden') return t('intervalEvenHidden');
    return t('intervalNone');
  };

  const rows = [
    {label: t('ignoreCase'), value: formatStatus(ignoreCase.value)},
    {label: t('ignorePunctuation'), value: formatStatus(ignorePunctuation.value)},
    {label: t('intervalDisplay'), value: formatIntervalMode(intervalMode.value)},
    {label: t('ttsRate'), value: `${ttsRate.value}x`},
    {label: t('speakLetters'), value: formatStatus(speakLetters.value)},
    {label: t('manualTtsRate'), value: `${manualTtsRate.value}x`},
    {label: t('manualPlayTrigger'), value: manualPlayTrigger.value}
  ];

  let html = `<div style="display: flex; flex-direction: column; gap: 10px; text-align: left;">`;

  html += rows.map((row, index) => {
    const isLast = index === rows.length - 1;
    const borderStyle = isLast ? '' : 'border-bottom: 1px solid rgba(128,128,128,0.15);';

    return `
      <div style="display: flex; justify-content: space-between; align-items: center; padding-bottom: ${isLast ? '0' : '6px'}; ${borderStyle}">
        <b style="font-size: 14px;">${row.label}</b>
        <span style="font-size: 14px; opacity: 0.8;">${row.value}</span>
      </div>
    `.replace(/\n/g, '');
  }).join('');

  html += `</div>`;

  tipDialogContent.value = html;
  tipDialogVisible.value = true;
};
const getLabel = async () => {
  const req = new Request({
    path: Path.game,
    headers: {'jsMethod': 'Game.label'},
  });
  const res = await client.node!.send(req);

  labels.left = res.data.left;
  labels.middle = res.data.middle;
  labels.right = res.data.right;
};

const getConfig = async () => {
  const req = new Request({
    path: Path.game,
    headers: {'jsMethod': 'Game.getConfig'},
  });
  const res0 = await client.node!.send(req);
  const res = res0.data;
  ignorePunctuation.value = res['ignorePunctuation'];
  ignoreCase.value = res['ignoreCase'];
  intervalMode.value = res['intervalMode'] || 'none';
  ttsRate.value = typeof res['ttsRate'] === 'number' ? res['ttsRate'] : 1;
  speakLetters.value = typeof res['speakLetters'] === 'boolean' ? res['speakLetters'] : false;
  manualTtsRate.value = typeof res['manualTtsRate'] === 'number' ? res['manualTtsRate'] : 0.5;
  manualPlayTrigger.value = typeof res['manualPlayTrigger'] === 'string' ? res['manualPlayTrigger'] : '.';
};
const getAdmin = async () => {
  const req = new Request({
    path: Path.gameAdmin,
  });
  const res0 = await client.node!.send(req);
  const admin = res0.data;
  adminEnable.value = admin.adminEnable;
  adminId.value = admin.adminId;
};

const tap = async (event: String) => {
  const req = new Request({
    path: Path.game,
    headers: {'jsMethod': 'Game.tap'},
    data: event,
  });
  await client.node!.send(req);
  if (event == 'tapLeft') {
    await refresh();
  }
};

const setIgnoreCase = (value: boolean) => {
  setConfig("ignoreCase", value);
};
const setIgnorePunctuation = (value: boolean) => {
  setConfig("ignorePunctuation", value);
};
const setIntervalMode = (value: 'none' | 'oddHidden' | 'evenHidden') => {
  setConfig("intervalMode", value);
};
const setTtsRate = (value: number) => {
  setConfig("ttsRate", value);
};
const setSpeakLetters = (value: boolean) => {
  setConfig("speakLetters", value);
};
const setManualTtsRate = (value: number) => {
  setConfig("manualTtsRate", value);
};
const setManualPlayTrigger = (value: string) => {
  setConfig("manualPlayTrigger", value);
};
const updateIgnoreIndexes = (mask: string) => {
  const indexes: number[] = [];
  for (let i = 0; i < mask.length; i++) {
    if (mask[i] !== '•') indexes.push(i);
  }
  ignoreContentIndexes.value = indexes;
};
const setConfig = async (key: String, value: boolean | string | number) => {
  overlayVisible.value = true;
  const req = new Request({
    path: Path.game,
    headers: {'jsMethod': 'Game.setConfig'},
    data: {key: key, value: value},
  });
  await client.node!.send(req);
  overlayVisible.value = false;
};
// 水滴音效：纯代码合成（仓库里没有现成音效素材），短促正弦波+快速衰减
let audioCtx: AudioContext | null = null;
const playDrip = () => {
  try {
    if (!audioCtx) {
      audioCtx = new (window.AudioContext || (window as any).webkitAudioContext)();
    }
    const ctx = audioCtx;
    const now = ctx.currentTime;
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.type = 'sine';
    osc.frequency.setValueAtTime(1200, now);
    osc.frequency.exponentialRampToValueAtTime(400, now + 0.12);
    gain.gain.setValueAtTime(0.25, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.15);
    osc.connect(gain);
    gain.connect(ctx.destination);
    osc.start(now);
    osc.stop(now + 0.15);
  } catch (e) {
    console.error('Failed to play drip sound:', e);
  }
};

// TTS 朗读：串行播放，避免间隔模式下一次自动补全多个字母时同时开口
let speakQueue: Promise<void> = Promise.resolve();
const speak = (text: string, rate?: number) => {
  if (!text) return;
  speakQueue = speakQueue.then(async () => {
    try {
      const req = new Request({
        path: Path.game,
        headers: {'jsMethod': 'Game.tts'},
        data: {text, type: 'a', rate},
      });
      await client.node!.send(req);
    } catch (error) {
      console.error('Failed to send tts:', error);
    }
  });
};
const isSpeakable = (ch: string) => /[\p{L}\p{N}]/u.test(ch);

// 整词朗读：非字母/数字（空格、撇号、标点等）都当作词与词之间的分界
let currentWord = '';
const flushWord = () => {
  if (currentWord.length > 0) {
    speak(currentWord);
  }
  currentWord = '';
};

const onCharFilled = (_index: number, char: string, auto: boolean, correct: boolean) => {
  if (auto || correct) {
    if (isSpeakable(char)) {
      currentWord += char;
    } else {
      flushWord();
    }
  }

  if (auto) {
    if (speakLetters.value && isSpeakable(char)) speak(char);
    return;
  }
  if (correct) {
    if (speakLetters.value && isSpeakable(char)) speak(char);
  } else {
    playDrip();
  }
};

const onCompleted = () => {
  flushWord();
};

const speakCurrentWord = () => {
  const word = typingRef.value?.getCurrentWord();
  if (word) speak(word, manualTtsRate.value);
};

const onManualPlay = (word: string) => {
  if (word) speak(word, manualTtsRate.value);
};

const refresh = async () => {
  try {
    overlayVisible.value = true;
    currentWord = '';
    const req = new Request({
      path: Path.game,
      headers: {'jsMethod': 'Game.answer'},
    });
    const res = await client.node!.send(req);
    content.value = res.data.answer;
    updateIgnoreIndexes(res.data.mask);

    await getLabel();
  } catch (error) {
    console.error('Failed to refresh game:', error);
  } finally {
    overlayVisible.value = false;
  }
};

onMounted(async () => {
  await getConfig();
  await getAdmin();
  await refresh();
  client.controllers.set('gameRefresh', async (_: Request) => {
    await refresh();
    return new Response();
  });
});

</script>
<style scoped>
.type-game-container {
  display: flex;
  flex-direction: column;
  flex: 1; /* 继承父级的高度占满 */
}

.typing-content {
  flex: 1; /* 自动撑开，把 actions 挤到最下面 */
  padding: 10px;
  padding-top: 0;
}

.actions {
  display: flex;
  justify-content: space-around;
  padding: 10px 0;
  padding-bottom: env(safe-area-inset-bottom); /* 适配手机底部安全区 */
  flex-shrink: 0;
}

.actions .nut-button {
  line-height: 1.1;
  width: 32%;
}

.nut-theme-dark .info-icon {
  color: white;
}

.info-bar {
  display: flex;
  justify-content: flex-end;
  align-items: center;
  gap: 12px;
  padding: 0 15px;
}
</style>