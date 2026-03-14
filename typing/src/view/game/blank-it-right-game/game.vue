<template>
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
        :click-fill-char-when-disabled="clickFillCharWhenDisabled"
        ref="typingRef"
    />

    <div v-if="step === StepName.blanked" class="action-container">
      <nut-button block type="info" @click="onSubmit" :loading="overlayVisible">
        {{ t('confirm') }}
      </nut-button>
    </div>

    <div v-else-if="step === StepName.finished" class="action-container">
      <nut-cell class="score-cell">
        {{ t('score') }}: <span class="score-num">+{{ score }}</span>
      </nut-cell>
      <nut-button block type="info" @click="onSwitchView">
        {{ showAnswer ? t('viewSubmit') : t('viewAnswer') }}
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

enum StepName {
  none = 0,
  blanked = 2,
  finished = 3,
}

const step = ref<StepName>(StepName.blanked);

// 2. 计算属性
const currentUserId = computed(() => toNumber(store.getters.currentUserId));
const currUserIndex = computed(() => status.value.userIds.indexOf(currentUserId.value));
const clickFillCharWhenDisabled = computed(() => (step.value === StepName.finished ? '' : ''));

const getUserColor = (userId: number) => {
  const player = status.value.players.find(p => p.userId === userId);

  if (player && player.step === 'finished') {
    return '#22c55e';
  }
  return '#ef4444';
};

// 3. 核心逻辑方法
const updateIgnoreIndexes = (content: string) => {
  const indexes: number[] = [];
  for (let i = 0; i < content.length; i++) {
    if (content[i] !== '•') indexes.push(i);
  }
  ignoreContentIndexes.value = indexes;
};

// 提交答案
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
    updateIgnoreIndexes(newData.blankContent || '');

    // 获取当前玩家在服务器端的状态
    const selfStatus = newData.players.find(p => p.userId === currentUserId.value);

    if (selfStatus?.step === 'finished') {
      step.value = StepName.finished;
      typingDisabled.value = true;
      const res = await client.node!.send(new Request({
        path: Path.game,
        headers: {'jsMethod': 'Game.myStatus'}
      }));
      score.value = res.data.score || 0;
      userSubmitContent = res.data.submit || '';
      answer.value = res.data.answer || '';
      await nextTick(() => {
        typingRef.value?.initUserInput(answer.value);
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
</style>