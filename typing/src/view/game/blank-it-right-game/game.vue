<template>
  <div class="top-bar">
    <Ask color="#888" size="22px" @click="onShowHelp" class="ask-icon"/>
  </div>


  <Player
      :user-ids="status.userIds"
      :user-id-to-user-name="status.userIdToUserName"
      :current-user-id="currentUserId"
      :curr-user-index="currUserIndex"
      :game-started="status.gameStatus == 'started'"
      :get-user-color="getUserColor">
  </Player>

  <div class="container">
    <Typing
        :content="answer || status.blankContent || ''"
        :disabled="typingDisabled"
        :ignore-case="ignoreCase"
        :change-to-right-case-when-ignore-case="false"
        :ignore-punctuation="false"
        :ignore-content-indexes="ignoreContentIndexes"
        :click-fill-char-when-disabled="''"
        ref="typingRef"
    />

    <div v-if="currUserIndex>=0 && step === 'blanking'" class="action-container">
      <nut-button
          :disabled="!isFilled"
          shape="square" type="info" @click="onSubmit" :loading="overlayVisible">
        {{ t('confirm') }}
      </nut-button>
    </div>

    <div v-else-if="currUserIndex>=0 && step === 'finished'" class="action-container">
      <nut-cell class="score-cell">
        {{ t('score') }}: <span class="score-num">+{{ score }}</span>
      </nut-cell>
      <nut-button shape="square" type="info" @click="onSwitchView">
        {{ showAnswer ? t('viewSubmit') : t('viewAnswer') }}
      </nut-button>
      <nut-button
          shape="square"
          type="info"
          @click="onNext"
          :disabled="nexted"
      >
        {{ nexted ? t('waitingForOthers') : t('nextGame') }}
      </nut-button>
    </div>
  </div>
</template>

<script setup lang="ts">
import {onMounted, ref, onBeforeUnmount, inject, Ref, nextTick, computed, watch} from 'vue';
import {useStore} from "vuex";
import {useI18n} from "vue-i18n";

import {bus, EventName} from '../../../api/bus.ts';
import {client, Request} from '../../../api/ws.ts';
import {Path} from '../../../utils/constant.ts';
import Typing from '../../../component/typing.vue';
import Player from "../widget/player.vue";
import {BlankItRightStatus} from "../../../vo/BlankItRightStatus.ts";
import {toNumber} from "../../../utils/convert.ts";
import {Ask} from "@nutui/icons-vue";

const {t} = useI18n();
const store = useStore();

// 1. 基础状态与 Props
const props = defineProps<{ status: BlankItRightStatus }>();
const status = ref<BlankItRightStatus>(props.status);

const typingDisabled = ref(false);
const ignoreCase = ref(true); // 默认开启忽略大小写
const score = ref(0);
const answer = ref('');
const showAnswer = ref(false);
let userSubmitContent = ''; // 暂存用户提交的文本内容

const ignoreContentIndexes = ref<number[]>([]);
const typingRef = ref<InstanceType<typeof Typing>>();

const step = ref('');
const nexted = ref(false);

// 2. 计算属性
const currentUserId = computed(() => toNumber(store.getters.currentUserId));
const currUserIndex = computed(() => status.value.userIds.indexOf(currentUserId.value));

const getUserColor = (userId: number) => {
  const player = status.value.players.find(p => p.userId === userId);

  if (player && player.nexted) {
    return '#22c55e';
  }
  if (player && player.step === 'finished') {
    return '#f1ac40';
  }
  return '#ef4444';
};

const isFilled = computed(() => {
  const input = typingRef.value?.getUserInput() || '';
  const target = status.value.blankContent || '';
  return input.length >= target.length && target.length > 0;
});

const updateIgnoreIndexes = (content: string) => {
  const indexes: number[] = [];
  for (let i = 0; i < content.length; i++) {
    if (content[i] !== '•') indexes.push(i);
  }
  ignoreContentIndexes.value = indexes;
};

const onShowHelp = () => {
  const config = status.value.config;
  if (!config) return;

  const formatStatus = (val: boolean) => val ? t('enabled') : t('disabled');

  const rows = [
    {label: t('autoBlank'), value: formatStatus(config.autoBlank)},
    {label: t('blankPercent'), value: `${Math.round((config.blankContentPercent) * 100)}%`},
    {label: t('ignoreCase'), value: formatStatus(config.ignoreCase)},
    {label: t('ignorePunctuation'), value: formatStatus(config.ignorePunctuation)},
    {label: t('maxScore'), value: config.maxScore},
    {label: t('passingRate'), value: `${Math.round((config.shouldRememberIfPassingRate) * 100)}%`}
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
    `.replace(/\n/g, ''); // 依旧去掉换行符，确保在 pre-wrap 环境下也万无一失
  }).join('');

  html += `</div>`;

  tipDialogContent.value = html;
  tipDialogVisible.value = true;
};
const onSubmit = async () => {
  const userInput = typingRef.value?.getUserInput() || '';
  if (!userInput) return;

  overlayVisible.value = true;
  try {
    const res = await client.node!.send(new Request({
      path: Path.game,
      headers: {'jsMethod': 'Game.submit'},
      data: {
        userId: currentUserId.value,
        content: userInput
      }
    }));

    if (res.error) {
      tipDialogContent.value = t(res.error);
      tipDialogVisible.value = true;
    } else {
      // 提交成功后，本地先行进入“等待结算”状态，或者等待广播刷新
      typingDisabled.value = true;
    }
  } finally {
    overlayVisible.value = false;
  }
};
// 下一个游戏/下一题
const onNext = async () => {
  overlayVisible.value = true;
  try {
    const res = await client.node!.send(new Request({
      path: Path.game,
      headers: {'jsMethod': 'Game.next'},
      data: {
        userId: currentUserId.value
      }
    }));

    if (res.error) {
      tipDialogContent.value = t(res.error);
      tipDialogVisible.value = true;
    } else if (res.data === 'waiting_for_others') {
      const self = status.value.players.find(p => p.userId === currentUserId.value);
      if (self) {
        self.nexted = true;
      }
      nexted.value = true;
    }
    // 注意：如果全员达标，Dart 侧会直接切走页面，前端无需额外操作
  } finally {
    overlayVisible.value = false;
  }
};
// 切换查看“我的答案”和“标准答案”
const onSwitchView = () => {
  showAnswer.value = !showAnswer.value;
  const targetText = showAnswer.value ? answer.value : userSubmitContent;
  typingRef.value?.initUserInput(targetText);
};

// 4. 生命周期与监听
const overlayVisible = inject<Ref<boolean>>('overlayVisible')!;
const tipDialogVisible = inject<Ref<boolean>>('tipDialogVisible')!;
const tipDialogContent = inject<Ref<string>>('tipDialogContent')!;

onMounted(async () => {
  // 初始处理
  updateIgnoreIndexes(status.value.blankContent || '');

  // 监听后端广播的状态更新
  bus().on(EventName.BlankItRightStatusUpdate, async (newData: BlankItRightStatus) => {
    status.value = newData;
    answer.value = '';
    typingDisabled.value = false;
    updateIgnoreIndexes(newData.blankContent || '');

    // 获取当前玩家在服务器端的状态
    const selfStatus = newData.players.find(p => p.userId === currentUserId.value);
    step.value = selfStatus?.step ?? '';
    nexted.value = selfStatus?.nexted ?? false;
    if (selfStatus?.step === 'finished') {
      typingDisabled.value = true;
      const res = await client.node!.send(new Request({
        path: Path.game,
        headers: {'jsMethod': 'Game.myStatus'}
      }));
      score.value = res.data.score || 0;
      userSubmitContent = res.data.submit || '';
      answer.value = res.data.answer || '';
      showAnswer.value = false;
      await nextTick(() => {
        typingRef.value?.initUserInput(userSubmitContent);
      });
    }
  });
});

onBeforeUnmount(() => {
  bus().off(EventName.BlankItRightStatusUpdate);
});
</script>

<style scoped>
.container {
  margin: 12px;
}

.action-container {
  margin-top: 20px;
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.score-cell {
  text-align: center;
  font-weight: bold;
}

.score-num {
  color: #fa2c19;
  font-size: 18px;
}

.top-bar {
  display: flex;
  justify-content: flex-end;
  padding: 12px 16px 0 0;
}
</style>