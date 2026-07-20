<template>
  <div v-if="isAdmin" style="margin: 8px">
    <nut-cell :title="t('profile')">
      <template #link>
        <nut-radio-group v-model="activeProfile" direction="horizontal" @change="setActiveProfile">
          <nut-radio v-for="(name, i) in profileNames" :key="i" :label="i">{{ name }}</nut-radio>
        </nut-radio-group>
      </template>
    </nut-cell>
    <nut-cell :title="t('profileName')">
      <template #link>
        <nut-input
            v-model="profileNames[activeProfile]"
            style="text-align: right"
            @blur="setProfileName(activeProfile, profileNames[activeProfile])"
        />
      </template>
    </nut-cell>
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
        <span v-if="manualPlayTrigger === ' '" style="margin-right: 8px; opacity: 0.6">{{ t('spaceKey') }}</span>
        <nut-input
            v-model="manualPlayTrigger"
            maxlength="1"
            style="text-align: right"
            @blur="setManualPlayTrigger(manualPlayTrigger)"
        />
      </template>
    </nut-cell>
    <nut-cell :title="t('spellPlayTrigger')">
      <template #link>
        <span v-if="spellPlayTrigger === ' '" style="margin-right: 8px; opacity: 0.6">{{ t('spaceKey') }}</span>
        <nut-input
            v-model="spellPlayTrigger"
            maxlength="1"
            style="text-align: right"
            @blur="setSpellPlayTrigger(spellPlayTrigger)"
        />
      </template>
    </nut-cell>
    <nut-cell :title="t('spellClearWord')">
      <template #link>
        <nut-switch v-model="spellClearWord" @change="setSpellClearWord"/>
      </template>
    </nut-cell>
    <nut-cell :title="t('speakLetters')">
      <template #link>
        <nut-switch v-model="speakLetters" @change="setSpeakLetters"/>
      </template>
    </nut-cell>
    <nut-cell :title="t('hintTrigger')">
      <template #link>
        <span v-if="hintTrigger === ' '" style="margin-right: 8px; opacity: 0.6">{{ t('spaceKey') }}</span>
        <nut-input
            v-model="hintTrigger"
            maxlength="1"
            style="text-align: right"
            @blur="setHintTrigger(hintTrigger)"
        />
      </template>
    </nut-cell>
    <nut-cell :title="t('keyMapping')" :desc="t('keyMappingDesc')">
      <template #link>
        <nut-input
            v-model="keyMapping"
            placeholder="a:abc,q:def"
            style="text-align: right"
            @blur="setKeyMapping(keyMapping)"
        />
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
          :spell-play-trigger="spellPlayTrigger"
          :hint-trigger="hintTrigger"
          :key-mapping="keyMapping"
          @char-filled="onCharFilled"
          @completed="onCompleted"
          @manual-play="onManualPlay"
          @spell-play="onSpellPlay"
          @hint-trigger="onHintTrigger"
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
import {showToast} from "@nutui/nutui";

const {t} = useI18n();
const store = useStore();

type ProfileConfig = Record<string, any>;

const activeProfile = ref(0);
const profileNames = ref<string[]>(['1', '2', '3']);
const profiles = ref<ProfileConfig[]>([]); // 本地缓存全部槽位，切换 profile 时不用重新请求

const ignoreCase = ref(false);
const ignorePunctuation = ref(false);
const intervalMode = ref<'none' | 'oddHidden' | 'evenHidden'>('none');
const ttsRate = ref(1);
const speakLetters = ref(false);
const manualTtsRate = ref(0.5);
const manualPlayTrigger = ref('.');
const spellPlayTrigger = ref(',');
const spellClearWord = ref(true);
const hintTrigger = ref(' ');
// 三个触发键各自最后一次成功保存的值，用于校验失败时把输入框还原回去
let manualPlayTriggerSaved = '.';
let spellPlayTriggerSaved = ',';
let hintTriggerSaved = ' ';
const keyMapping = ref('');
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
    {label: t('profile'), value: profileNames.value[activeProfile.value]},
    {label: t('ignoreCase'), value: formatStatus(ignoreCase.value)},
    {label: t('ignorePunctuation'), value: formatStatus(ignorePunctuation.value)},
    {label: t('intervalDisplay'), value: formatIntervalMode(intervalMode.value)},
    {label: t('ttsRate'), value: `${ttsRate.value}x`},
    {label: t('speakLetters'), value: formatStatus(speakLetters.value)},
    {label: t('manualTtsRate'), value: `${manualTtsRate.value}x`},
    {label: t('manualPlayTrigger'), value: formatTriggerKey(manualPlayTrigger.value)},
    {label: t('spellPlayTrigger'), value: formatTriggerKey(spellPlayTrigger.value)},
    {label: t('spellClearWord'), value: formatStatus(spellClearWord.value)},
    {label: t('hintTrigger'), value: formatTriggerKey(hintTrigger.value)},
    {label: t('keyMapping'), value: keyMapping.value || t('disabled')}
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

// 把 profiles.value[index] 的各字段套用到现有的独立 ref 上（切换 profile / 初次加载都走这里）
const applyProfile = (index: number) => {
  const res = profiles.value[index] || {};
  ignorePunctuation.value = res['ignorePunctuation'];
  ignoreCase.value = res['ignoreCase'];
  intervalMode.value = res['intervalMode'] || 'none';
  ttsRate.value = typeof res['ttsRate'] === 'number' ? res['ttsRate'] : 1;
  speakLetters.value = typeof res['speakLetters'] === 'boolean' ? res['speakLetters'] : false;
  manualTtsRate.value = typeof res['manualTtsRate'] === 'number' ? res['manualTtsRate'] : 0.5;
  manualPlayTrigger.value = typeof res['manualPlayTrigger'] === 'string' ? res['manualPlayTrigger'] : '.';
  spellPlayTrigger.value = typeof res['spellPlayTrigger'] === 'string' ? res['spellPlayTrigger'] : ',';
  spellClearWord.value = typeof res['spellClearWord'] === 'boolean' ? res['spellClearWord'] : true;
  hintTrigger.value = typeof res['hintTrigger'] === 'string' ? res['hintTrigger'] : ' ';
  manualPlayTriggerSaved = manualPlayTrigger.value;
  spellPlayTriggerSaved = spellPlayTrigger.value;
  hintTriggerSaved = hintTrigger.value;
  keyMapping.value = typeof res['keyMapping'] === 'string' ? res['keyMapping'] : '';
};

const getConfig = async () => {
  const req = new Request({
    path: Path.game,
    headers: {'jsMethod': 'Game.getConfig'},
  });
  const res0 = await client.node!.send(req);
  const res = res0.data;
  activeProfile.value = typeof res['activeProfile'] === 'number' ? res['activeProfile'] : 0;
  profileNames.value = Array.isArray(res['profileNames']) ? res['profileNames'] : ['1', '2', '3'];
  profiles.value = Array.isArray(res['profiles']) ? res['profiles'] : [];
  applyProfile(activeProfile.value);
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

// 每个 setXxx 除了持久化到服务端，还要同步更新本地缓存的 profiles.value[activeProfile]，
// 这样切换到别的 profile 再切回来，不用重新请求就能看到刚才改过的值
const setIgnoreCase = (value: boolean) => {
  profiles.value[activeProfile.value].ignoreCase = value;
  setConfig("ignoreCase", value);
};
const setIgnorePunctuation = (value: boolean) => {
  profiles.value[activeProfile.value].ignorePunctuation = value;
  setConfig("ignorePunctuation", value);
};
const setIntervalMode = (value: 'none' | 'oddHidden' | 'evenHidden') => {
  profiles.value[activeProfile.value].intervalMode = value;
  setConfig("intervalMode", value);
};
const setTtsRate = (value: number) => {
  profiles.value[activeProfile.value].ttsRate = value;
  setConfig("ttsRate", value);
};
const setSpeakLetters = (value: boolean) => {
  profiles.value[activeProfile.value].speakLetters = value;
  setConfig("speakLetters", value);
};
const setManualTtsRate = (value: number) => {
  profiles.value[activeProfile.value].manualTtsRate = value;
  setConfig("manualTtsRate", value);
};
// 三个触发键不能互相重复（比如手动播放和逐字母朗读不能都设成 '.'），
// 冲突时提示并把输入框还原成上一次成功保存的值
const setManualPlayTrigger = (value: string) => {
  if (value && (value === spellPlayTrigger.value || value === hintTrigger.value)) {
    showToast.warn(t('triggerKeyConflict'));
    manualPlayTrigger.value = manualPlayTriggerSaved;
    return;
  }
  manualPlayTriggerSaved = value;
  profiles.value[activeProfile.value].manualPlayTrigger = value;
  setConfig("manualPlayTrigger", value);
};
const setSpellPlayTrigger = (value: string) => {
  if (value && (value === manualPlayTrigger.value || value === hintTrigger.value)) {
    showToast.warn(t('triggerKeyConflict'));
    spellPlayTrigger.value = spellPlayTriggerSaved;
    return;
  }
  spellPlayTriggerSaved = value;
  profiles.value[activeProfile.value].spellPlayTrigger = value;
  setConfig("spellPlayTrigger", value);
};
const setSpellClearWord = (value: boolean) => {
  profiles.value[activeProfile.value].spellClearWord = value;
  setConfig("spellClearWord", value);
};
const setHintTrigger = (value: string) => {
  if (value && (value === manualPlayTrigger.value || value === spellPlayTrigger.value)) {
    showToast.warn(t('triggerKeyConflict'));
    hintTrigger.value = hintTriggerSaved;
    return;
  }
  hintTriggerSaved = value;
  profiles.value[activeProfile.value].hintTrigger = value;
  setConfig("hintTrigger", value);
};
const setKeyMapping = (value: string) => {
  profiles.value[activeProfile.value].keyMapping = value;
  setConfig("keyMapping", value);
};

const setActiveProfile = async (index: number) => {
  overlayVisible.value = true;
  try {
    const req = new Request({
      path: Path.game,
      headers: {'jsMethod': 'Game.setActiveProfile'},
      data: index,
    });
    await client.node!.send(req);
    activeProfile.value = index;
    applyProfile(index);
  } finally {
    overlayVisible.value = false;
  }
};

const setProfileName = async (index: number, name: string) => {
  overlayVisible.value = true;
  try {
    const req = new Request({
      path: Path.game,
      headers: {'jsMethod': 'Game.setProfileName'},
      data: {index, name},
    });
    await client.node!.send(req);
    profileNames.value[index] = name;
  } finally {
    overlayVisible.value = false;
  }
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

// 触发键是空格时肉眼看不出来，需要额外提示；其它可见字符原样显示即可
const formatTriggerKey = (key: string) => key === ' ' ? t('spaceKey') : key;

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
  void tap('tapLeft');
};

const speakCurrentWord = () => {
  const word = typingRef.value?.getCurrentWord();
  if (word) speak(word, manualTtsRate.value);
};

const onManualPlay = (word: string) => {
  if (word) speak(word, manualTtsRate.value);
};

const onSpellPlay = (word: string) => {
  for (const ch of word) {
    if (isSpeakable(ch)) speak(ch, manualTtsRate.value);
  }
  if (spellClearWord.value) {
    typingRef.value?.clearCurrentWord();
  }
};

const onHintTrigger = () => {
  void tap('tapMiddle');
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