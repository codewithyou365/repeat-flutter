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
    <nut-cell :title="t('ignoreNumber')">
      <template #link>
        <nut-switch v-model="ignoreNumber" @change="setIgnoreNumber"/>
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
    <nut-cell :title="t('spellResetLevel')">
      <template #link>
        <nut-switch v-model="spellResetLevel" @change="setSpellResetLevel"/>
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
    <nut-cell :title="t('maskTrigger')">
      <template #link>
        <span v-if="maskTrigger === ' '" style="margin-right: 8px; opacity: 0.6">{{ t('spaceKey') }}</span>
        <nut-input
            v-model="maskTrigger"
            maxlength="1"
            style="text-align: right"
            @blur="setMaskTrigger(maskTrigger)"
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
    <nut-cell
        v-for="(binding, i) in assistiveTouchBindings"
        :key="i"
        :title="t('assistiveTouchTrigger')"
    >
      <template #link>
        <div class="assist-binding">
          <span v-if="binding.key === ' '" style="opacity: 0.6">{{ t('spaceKey') }}</span>
          <nut-input
              v-model="binding.key"
              maxlength="1"
              class="assist-binding-key"
              @blur="setBindingKey(i, binding.key)"
          />
          <!-- direction="up": 这些行常年贴在设置页最下方，若按默认向下弹出，
               选项列表会被弹到屏幕可视区域之外（popup 是 position:fixed，页面滚动也救不回来），
               导致排在最后的选项（如"后退"）点不到。向上弹出则是在页面已展示的内容区域内展开，不会跑出屏幕。 -->
          <nut-menu class="assist-binding-action" direction="up">
            <nut-menu-item
                :model-value="binding.action"
                :options="bindingOptionList[i]"
                @change="(value: string) => setBindingAction(i, value)"
            />
          </nut-menu>
          <Del width="16px" height="16px" class="assist-binding-del" @click="removeBinding(i)"/>
        </div>
      </template>
    </nut-cell>
    <!-- 单词提问：一个键 + 一个自定义动作（约定只带一个参数 input1）。
         跟上面的辅助触控绑定用同一套样式，只是它是固定的一条，没有增删。 -->
    <nut-cell :title="t('wordAskTrigger')" :desc="t('wordAskTriggerDesc')">
      <template #link>
        <div class="assist-binding">
          <span v-if="wordAskTrigger.key === ' '" style="opacity: 0.6">{{ t('spaceKey') }}</span>
          <nut-input
              v-model="wordAskTrigger.key"
              maxlength="1"
              class="assist-binding-key"
              @blur="setWordAskKey(wordAskTrigger.key)"
          />
          <nut-menu class="assist-binding-action" direction="up">
            <nut-menu-item
                :model-value="wordAskTrigger.action"
                :options="wordAskOptionList"
                @change="(value: string) => setWordAskAction(value)"
            />
          </nut-menu>
        </div>
      </template>
    </nut-cell>
    <nut-cell>
      <nut-button size="small" type="info" @click="addBinding">
        {{ t('assistiveTouchAddBinding') }}
      </nut-button>
      <span v-if="assistiveTouchOptions.length === 0" style="margin-left: 8px; opacity: 0.6; font-size: 12px">
        {{ t('assistiveTouchNoAction') }}
      </span>
    </nut-cell>
  </div>
  <nut-cell v-else-if="cantPlayForMaintain">
    {{ t('cantPlayForMaintain') }}
  </nut-cell>
  <div v-else-if="ready" class="type-game-container">
    <div class="info-bar">
      <Voice class="info-icon" width="18px" height="18px" @click="speakCurrentWord"/>
      <Eye class="info-icon" width="18px" height="18px" @click="eyesClosedMaskVisible = true"/>
      <Ask class="info-icon" width="18px" height="18px" @click="showTips"/>
    </div>
    <div v-if="eyesClosedMaskVisible" class="eyes-closed-mask" @click="eyesClosedMaskVisible = false"></div>
    <div class="typing-content">
      <Typing
          ref="typingRef"
          :content="content"
          :disabled="false"
          :ignore-case="ignoreCase"
          :change-to-right-case-when-ignore-case="true"
          :ignore-punctuation="ignorePunctuation"
          :ignore-number="ignoreNumber"
          :ignore-content-indexes="ignoreContentIndexes"
          :ignore-space="true"
          :block-on-wrong="true"
          :manual-play-trigger="manualPlayTrigger"
          :spell-play-trigger="spellPlayTrigger"
          :hint-trigger="hintTrigger"
          :mask-trigger="maskTrigger"
          :assist-triggers="assistTriggerKeys"
          :key-mapping="keyMapping"
          @char-filled="onCharFilled"
          @completed="onCompleted"
          @manual-play="onManualPlay"
          @spell-play="onSpellPlay"
          @hint-trigger="onHintTrigger"
          @mask-trigger="onMaskTrigger"
          @assist-trigger="onAssistTrigger"
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
import {Ask, Voice, Eye, Del} from '@nutui/icons-vue';
import {showToast} from "@nutui/nutui";

const {t} = useI18n();
const store = useStore();

type ProfileConfig = Record<string, any>;

// 一条"辅助触控触发键"绑定：按下 key 就执行 App 辅助触控里 action 对应的按钮。
// name 是选中那一刻的动作名快照，动作被删掉后拿不到真名时用它显示。
type AssistiveTouchBinding = {
  key: string;
  action: string;
  name: string;
};

const activeProfile = ref(0);
const profileNames = ref<string[]>(['1', '2', '3']);
const profiles = ref<ProfileConfig[]>([]); // 本地缓存全部槽位，切换 profile 时不用重新请求

const ignoreCase = ref(false);
const ignorePunctuation = ref(false);
const ignoreNumber = ref(true);
const intervalMode = ref<'none' | 'oddHidden' | 'evenHidden'>('none');
const ttsRate = ref(1);
const speakLetters = ref(false);
const manualTtsRate = ref(0.5);
const manualPlayTrigger = ref('.');
const spellPlayTrigger = ref(',');
const spellResetLevel = ref(false);
const hintTrigger = ref(' ');
const maskTrigger = ref('');
// 各触发键最后一次成功保存的值，用于校验失败时把输入框还原回去
let manualPlayTriggerSaved = '.';
let spellPlayTriggerSaved = ',';
let hintTriggerSaved = ' ';
let maskTriggerSaved = '';
const keyMapping = ref('');
const assistiveTouchBindings = ref<AssistiveTouchBinding[]>([]);
// 每条绑定最后一次成功保存的键，校验失败时用来还原对应的输入框
let bindingKeysSaved: string[] = [];
// 单词提问触发键：按下时把光标所在的词标上下划线，连同之前标过的词一起当 input1
// 去执行绑定的自定义动作（只有一个参数的那种）。key 为空即不启用。
const wordAskTrigger = ref<AssistiveTouchBinding>({key: '', action: '', name: ''});
let wordAskKeySaved = '';
// App 辅助触控当前显示的按钮，只有管理员打开设置面板时才会去拉
const assistiveTouchOptions = ref<{ id: string; name: string }[]>([]);
const ignoreContentIndexes = ref<number[]>([]);
const adminEnable = ref(false);
const adminId = ref(0);
const content = ref('');
const typingRef = ref<InstanceType<typeof Typing>>();
const eyesClosedMaskVisible = ref(false);
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
    {label: t('ignoreNumber'), value: formatStatus(ignoreNumber.value)},
    {label: t('intervalDisplay'), value: formatIntervalMode(intervalMode.value)},
    {label: t('ttsRate'), value: `${ttsRate.value}x`},
    {label: t('speakLetters'), value: formatStatus(speakLetters.value)},
    {label: t('manualTtsRate'), value: `${manualTtsRate.value}x`},
    {label: t('manualPlayTrigger'), value: formatTriggerKey(manualPlayTrigger.value)},
    {label: t('spellPlayTrigger'), value: formatTriggerKey(spellPlayTrigger.value)},
    {label: t('spellResetLevel'), value: formatStatus(spellResetLevel.value)},
    {label: t('hintTrigger'), value: formatTriggerKey(hintTrigger.value)},
    {label: t('maskTrigger'), value: maskTrigger.value ? formatTriggerKey(maskTrigger.value) : t('disabled')},
    {label: t('keyMapping'), value: keyMapping.value || t('disabled')}
  ];

  // 绑定是变长的，一条一行；一条都没配就显示"未启用"
  if (assistiveTouchBindings.value.length === 0) {
    rows.push({label: t('assistiveTouchTrigger'), value: t('disabled')});
  } else {
    for (const binding of assistiveTouchBindings.value) {
      const key = binding.key ? formatTriggerKey(binding.key) : t('disabled');
      rows.push({label: t('assistiveTouchTrigger'), value: `${key} → ${bindingActionName(binding)}`});
    }
  }

  const wordAskKey = wordAskTrigger.value.key ? formatTriggerKey(wordAskTrigger.value.key) : t('disabled');
  rows.push({
    label: t('wordAskTrigger'),
    value: wordAskTrigger.value.key ? `${wordAskKey} \u2192 ${bindingActionName(wordAskTrigger.value)}` : wordAskKey,
  });

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
  ignoreNumber.value = typeof res['ignoreNumber'] === 'boolean' ? res['ignoreNumber'] : true;
  ignoreCase.value = res['ignoreCase'];
  intervalMode.value = res['intervalMode'] || 'none';
  ttsRate.value = typeof res['ttsRate'] === 'number' ? res['ttsRate'] : 1;
  speakLetters.value = typeof res['speakLetters'] === 'boolean' ? res['speakLetters'] : false;
  manualTtsRate.value = typeof res['manualTtsRate'] === 'number' ? res['manualTtsRate'] : 0.5;
  manualPlayTrigger.value = typeof res['manualPlayTrigger'] === 'string' ? res['manualPlayTrigger'] : '.';
  spellPlayTrigger.value = typeof res['spellPlayTrigger'] === 'string' ? res['spellPlayTrigger'] : ',';
  spellResetLevel.value = typeof res['spellResetLevel'] === 'boolean' ? res['spellResetLevel'] : false;
  hintTrigger.value = typeof res['hintTrigger'] === 'string' ? res['hintTrigger'] : ' ';
  maskTrigger.value = typeof res['maskTrigger'] === 'string' ? res['maskTrigger'] : '';
  manualPlayTriggerSaved = manualPlayTrigger.value;
  spellPlayTriggerSaved = spellPlayTrigger.value;
  hintTriggerSaved = hintTrigger.value;
  maskTriggerSaved = maskTrigger.value;
  keyMapping.value = typeof res['keyMapping'] === 'string' ? res['keyMapping'] : '';
  const rawBindings = Array.isArray(res['assistiveTouchBindings']) ? res['assistiveTouchBindings'] : [];
  assistiveTouchBindings.value = rawBindings.map((b: any) => ({
    key: typeof b?.key === 'string' ? b.key : '',
    action: typeof b?.action === 'string' ? b.action : '',
    name: typeof b?.name === 'string' ? b.name : '',
  }));
  bindingKeysSaved = assistiveTouchBindings.value.map((b) => b.key);
  const rawWordAsk = res['wordAskTrigger'];
  wordAskTrigger.value = {
    key: typeof rawWordAsk?.key === 'string' ? rawWordAsk.key : '',
    action: typeof rawWordAsk?.action === 'string' ? rawWordAsk.action : '',
    name: typeof rawWordAsk?.name === 'string' ? rawWordAsk.name : '',
  };
  wordAskKeySaved = wordAskTrigger.value.key;
};

// 找出绑定当前对应的按钮。返回 undefined 说明这个按钮已经不在辅助触控里了
// （自定义预设被删、内置动作被移出悬浮球、或当前复习模式下不可用）。
const findOption = (action: string) => assistiveTouchOptions.value.find((o) => o.id === action);

// 绑定行上显示的动作名：按钮还在就用 App 返回的真名，不在就用快照并标记已失效。
// 玩家端不拉按钮列表（options 为空），此时不做失效判断，直接显示快照。
const bindingActionName = (binding: AssistiveTouchBinding) => {
  if (assistiveTouchOptions.value.length === 0) {
    return binding.name;
  }
  const option = findOption(binding.action);
  return option ? option.name : `${t('assistiveTouchActionMissing')} ${binding.name}`;
};

// 每条绑定的下拉候选项。绑定的按钮已经不在列表里时，额外插一条"已失效"占位，
// 否则下拉会显示成空白，用户看不出原来绑的是什么。
// 必须用 computed 缓存出稳定的数组引用，不能在模板里现算：nut-menu 的标题依赖 nut-menu-item
// 的 props，每次渲染都传一个新数组会让两者互相触发更新，直接抛 Maximum recursive updates 把页面刷黑。
const bindingOptionList = computed(() => assistiveTouchBindings.value.map((binding) => {
  const options = assistiveTouchOptions.value.map((o) => ({text: o.name, value: o.id}));
  if (binding.action && !findOption(binding.action)) {
    options.unshift({text: bindingActionName(binding), value: binding.action});
  }
  return options;
}));

// 单词提问那一行的下拉候选，跟 bindingOptionList 同理（同样必须 computed 缓存）
const wordAskOptionList = computed(() => {
  const options = assistiveTouchOptions.value.map((o) => ({text: o.name, value: o.id}));
  const binding = wordAskTrigger.value;
  if (binding.action && !findOption(binding.action)) {
    options.unshift({text: bindingActionName(binding), value: binding.action});
  }
  return options;
});

const getAssistiveTouchActions = async () => {
  try {
    const req = new Request({
      path: Path.game,
      headers: {'jsMethod': 'Game.assistiveTouchActions'},
    });
    const res = await client.node!.send(req);
    assistiveTouchOptions.value = Array.isArray(res.data) ? res.data : [];
    // 自定义预设改名后 id 不变，绑定仍然有效，顺手把快照刷新成新名字
    let changed = false;
    for (const binding of assistiveTouchBindings.value) {
      const option = findOption(binding.action);
      if (option && option.name !== binding.name) {
        binding.name = option.name;
        changed = true;
      }
    }
    if (changed) {
      saveAssistiveTouchBindings();
    }
  } catch (error) {
    console.error('Failed to get assistive touch actions:', error);
  }
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
const setIgnoreNumber = (value: boolean) => {
  profiles.value[activeProfile.value].ignoreNumber = value;
  setConfig("ignoreNumber", value);
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
// 所有触发键（四个固定的 + 任意条辅助触控绑定）不能互相重复，比如手动播放和逐字母朗读不能都设成 '.'。
// exclude 是"正在改的那一个"（固定键用名字，绑定用下标），要排除掉，否则改成原值也会判成冲突。
type TriggerOwner = 'manualPlay' | 'spellPlay' | 'hint' | 'mask' | 'wordAsk' | number;
const isKeyTaken = (value: string, exclude: TriggerOwner) => {
  if (!value) {
    return false; // 空值表示不启用，不参与冲突判断
  }
  const keys: string[] = [];
  if (exclude !== 'manualPlay') keys.push(manualPlayTrigger.value);
  if (exclude !== 'spellPlay') keys.push(spellPlayTrigger.value);
  if (exclude !== 'hint') keys.push(hintTrigger.value);
  if (exclude !== 'mask') keys.push(maskTrigger.value);
  if (exclude !== 'wordAsk') keys.push(wordAskTrigger.value.key);
  assistiveTouchBindings.value.forEach((b, i) => {
    if (exclude !== i) keys.push(b.key);
  });
  return keys.includes(value);
};

// 冲突时提示并把输入框还原成上一次成功保存的值
const setManualPlayTrigger = (value: string) => {
  if (isKeyTaken(value, 'manualPlay')) {
    showToast.warn(t('triggerKeyConflict'));
    manualPlayTrigger.value = manualPlayTriggerSaved;
    return;
  }
  manualPlayTriggerSaved = value;
  profiles.value[activeProfile.value].manualPlayTrigger = value;
  setConfig("manualPlayTrigger", value);
};
const setSpellPlayTrigger = (value: string) => {
  if (isKeyTaken(value, 'spellPlay')) {
    showToast.warn(t('triggerKeyConflict'));
    spellPlayTrigger.value = spellPlayTriggerSaved;
    return;
  }
  spellPlayTriggerSaved = value;
  profiles.value[activeProfile.value].spellPlayTrigger = value;
  setConfig("spellPlayTrigger", value);
};
const setSpellResetLevel = (value: boolean) => {
  profiles.value[activeProfile.value].spellResetLevel = value;
  setConfig("spellResetLevel", value);
};
const setHintTrigger = (value: string) => {
  if (isKeyTaken(value, 'hint')) {
    showToast.warn(t('triggerKeyConflict'));
    hintTrigger.value = hintTriggerSaved;
    return;
  }
  hintTriggerSaved = value;
  profiles.value[activeProfile.value].hintTrigger = value;
  setConfig("hintTrigger", value);
};
const setMaskTrigger = (value: string) => {
  if (isKeyTaken(value, 'mask')) {
    showToast.warn(t('triggerKeyConflict'));
    maskTrigger.value = maskTriggerSaved;
    return;
  }
  maskTriggerSaved = value;
  profiles.value[activeProfile.value].maskTrigger = value;
  setConfig("maskTrigger", value);
};
const setKeyMapping = (value: string) => {
  profiles.value[activeProfile.value].keyMapping = value;
  setConfig("keyMapping", value);
};

// 绑定是变长数组，没法像其它设置那样一个字段一个 setter，统一整份存
const saveAssistiveTouchBindings = () => {
  const value = assistiveTouchBindings.value.map((b) => ({key: b.key, action: b.action, name: b.name}));
  bindingKeysSaved = value.map((b) => b.key);
  profiles.value[activeProfile.value].assistiveTouchBindings = value;
  setConfig("assistiveTouchBindings", value);
};

const setBindingKey = (index: number, value: string) => {
  const binding = assistiveTouchBindings.value[index];
  if (!binding) {
    return;
  }
  if (isKeyTaken(value, index)) {
    showToast.warn(t('triggerKeyConflict'));
    binding.key = bindingKeysSaved[index] ?? '';
    return;
  }
  binding.key = value;
  saveAssistiveTouchBindings();
};

const setBindingAction = (index: number, action: string) => {
  const binding = assistiveTouchBindings.value[index];
  if (!binding) {
    return;
  }
  binding.action = action;
  const option = findOption(action);
  if (option) {
    binding.name = option.name;
  }
  saveAssistiveTouchBindings();
};

const addBinding = () => {
  const first = assistiveTouchOptions.value[0];
  assistiveTouchBindings.value.push({key: '', action: first ? first.id : '', name: first ? first.name : ''});
  saveAssistiveTouchBindings();
};

// 单词提问是单独一条（不是变长数组），整份存，跟绑定一样只存 key/action/name
const saveWordAskTrigger = () => {
  const value = {key: wordAskTrigger.value.key, action: wordAskTrigger.value.action, name: wordAskTrigger.value.name};
  wordAskKeySaved = value.key;
  profiles.value[activeProfile.value].wordAskTrigger = value;
  setConfig("wordAskTrigger", value);
};

const setWordAskKey = (value: string) => {
  if (isKeyTaken(value, 'wordAsk')) {
    showToast.warn(t('triggerKeyConflict'));
    wordAskTrigger.value.key = wordAskKeySaved;
    return;
  }
  wordAskTrigger.value.key = value;
  saveWordAskTrigger();
};

const setWordAskAction = (action: string) => {
  wordAskTrigger.value.action = action;
  const option = findOption(action);
  if (option) {
    wordAskTrigger.value.name = option.name;
  }
  saveWordAskTrigger();
};

const removeBinding = (index: number) => {
  assistiveTouchBindings.value.splice(index, 1);
  saveAssistiveTouchBindings();
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
const setConfig = async (key: String, value: any) => {
  overlayVisible.value = true;
  const req = new Request({
    path: Path.game,
    headers: {'jsMethod': 'Game.setConfig'},
    data: {key: key, value: value},
  });
  await client.node!.send(req);
  overlayVisible.value = false;
};
// 错误提示音：交给 Dart 原生播放（走系统音频路由，能跟随蓝牙耳机），而不是 WebView 自己的 Web Audio
const playWrongSound = async () => {
  try {
    const req = new Request({
      path: Path.game,
      headers: {'jsMethod': 'Game.playWrong'},
      data: {url: `${window.location.origin}/sounds/wrong.wav`},
    });
    const res = await client.node!.send(req);
    console.log('playWrongSound response:', res);
  } catch (error) {
    console.error('Failed to play wrong sound:', error);
  }
};

// TTS 朗读：串行播放，避免间隔模式下一次自动补全多个字母时同时开口
let speakQueue: Promise<void> = Promise.resolve();
const speak = (text: string, rate?: number, manual?: boolean) => {
  if (!text) return speakQueue;
  speakQueue = speakQueue.then(async () => {
    try {
      const req = new Request({
        path: Path.game,
        headers: {'jsMethod': 'Game.tts'},
        data: {text, type: 'a', rate, manual},
      });
      await client.node!.send(req);
    } catch (error) {
      console.error('Failed to send tts:', error);
    }
  });
  return speakQueue;
};
const isSpeakable = (ch: string) => /[\p{L}\p{N}]/u.test(ch);

// 触发键是空格时肉眼看不出来，需要额外提示；其它可见字符原样显示即可
const formatTriggerKey = (key: string) => key === ' ' ? t('spaceKey') : key;

// 整词朗读：非字母/数字（空格、撇号、标点等）都当作词与词之间的分界
let currentWord = '';
const flushWord = () => {
  let p: Promise<void> = Promise.resolve();
  if (currentWord.length > 0) {
    p = speak(currentWord);
  }
  currentWord = '';
  return p;
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
    playWrongSound();
  }
};

const onCompleted = async () => {
  await flushWord();
  await new Promise((resolve) => setTimeout(resolve, 500));
  await tap('tapLeft');
};

const speakCurrentWord = () => {
  const word = typingRef.value?.getCurrentWord();
  if (word) speak(word, manualTtsRate.value, true);
};

const onManualPlay = (word: string) => {
  if (word) speak(word, manualTtsRate.value, true);
  typingRef.value?.clearCurrentWord();
};

const resetLevel = async () => {
  try {
    const req = new Request({
      path: Path.game,
      headers: {'jsMethod': 'Game.resetLevel'},
    });
    await client.node!.send(req);
  } catch (error) {
    console.error('Failed to reset level:', error);
  }
};

const onSpellPlay = (word: string) => {
  for (const ch of word) {
    if (isSpeakable(ch)) speak(ch, manualTtsRate.value);
  }
  if (spellResetLevel.value) {
    void resetLevel();
  }
  typingRef.value?.clearCurrentWord();
};

const onHintTrigger = () => {
  void tap('tapMiddle');
};

const onMaskTrigger = () => {
  eyesClosedMaskVisible.value = !eyesClosedMaskVisible.value;
};

// 空键不算触发键，过滤掉，免得用户还没填键的那一行把普通输入吃掉
const assistTriggerKeys = computed(() => {
  const keys = assistiveTouchBindings.value.map((b) => b.key);
  keys.push(wordAskTrigger.value.key);
  return keys.filter((k) => k !== '');
});

// 按下绑定键：让 App 执行对应的辅助触控按钮。这里不开 overlay，避免打断打字节奏；
// 但按钮已经被删掉/当前模式用不了时要给个提示，不然用户只会觉得"这个键没反应"。
const onAssistTrigger = async (key: string, bounds: { start: number; end: number } | null) => {
  if (wordAskTrigger.value.key && key === wordAskTrigger.value.key) {
    await onWordAsk(bounds);
    return;
  }
  const binding = assistiveTouchBindings.value.find((b) => b.key === key);
  if (!binding || !binding.action) {
    return;
  }
  try {
    const req = new Request({
      path: Path.game,
      headers: {'jsMethod': 'Game.assistiveTouchTap'},
      data: binding.action,
    });
    const res = await client.node!.send(req);
    if (res.data !== 'ok') {
      showToast.warn(`${t('assistiveTouchActionMissing')} ${binding.name}`);
    }
  } catch (error) {
    console.error('Failed to tap assistive touch:', error);
  }
};

// 单词提问：把光标所在的词交给 App，让它在上次那版 input1 的基础上再给这个词标上下划线，
// 然后执行绑定的自定义动作。跟普通绑定一样不开 overlay，避免打断打字节奏。
const onWordAsk = async (bounds: { start: number; end: number } | null) => {
  const binding = wordAskTrigger.value;
  if (!binding.action || !bounds || !content.value) {
    return; // 没绑动作，或者按键时光标不在任何词上
  }
  try {
    const req = new Request({
      path: Path.game,
      headers: {'jsMethod': 'Game.wordAsk'},
      data: {id: binding.action, sentence: content.value, start: bounds.start, end: bounds.end},
    });
    const res = await client.node!.send(req);
    if (res.data !== 'ok') {
      showToast.warn(`${t('assistiveTouchActionMissing')} ${binding.name}`);
    }
  } catch (error) {
    console.error('Failed to ask word:', error);
  }
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
  // 按钮列表只有设置面板的下拉要用，玩家端不拉，省一次请求
  if (isAdmin.value) {
    await getAssistiveTouchActions();
  }
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

/* 一行绑定：键输入框固定窄宽，动作下拉占满剩余空间，删除图标贴右 */
.assist-binding {
  display: flex;
  align-items: center;
  gap: 4px;
  width: 100%;
}

/* nut-input 自带 padding:10px 25px 且 box-sizing:border-box，宽度只给 40px 的话
   左右内边距就把里面真正的 <input> 挤成 0 宽，点上去既不聚焦也弹不出键盘。
   所以这里必须把左右内边距清掉，并留出够点的宽度。 */
.assist-binding-key {
  width: 48px;
  flex-shrink: 0;
  padding: 10px 0;
  text-align: center;
}

.assist-binding-action {
  flex: 1;
  min-width: 0;
}

.assist-binding-del {
  flex-shrink: 0;
  opacity: 0.6;
}

.eyes-closed-mask {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: #000;
  z-index: 3000;
}
</style>