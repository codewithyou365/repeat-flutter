<template>
  <div class="lobby">
    <Player
        :user-ids="status.userIds"
        :user-id-to-user-name="status.userIdToUserName"
        :current-user-id="currentUserId"
        :curr-user-index="status.currUserIndex"
        :game-step="status.gameStep"
        :get-user-color="getUserColor">
    </Player>

    <Typing
        ref="typingRef"
        :content="status.content"
        :disabled="true"
        :touch-color="getCurrUserColor"
        :ignore-case="false"
        :ignore-punctuation="false"
        :ignore-content-indexes="ignoreContentIndexes"/>

    <div class="actions" v-if="isMyTurn">
      <nut-button style="width: 50%" shape="square" type="primary" @click="submit">{{ t('submit') }}</nut-button>
      <nut-button style="width: 50%" shape="square" type="info" @click="refresh">{{ t('reset') }}</nut-button>
    </div>
    <div v-if="status.gameStep === GameStepEnum.started">
      <nut-cell> {{ t('wordSlicerEndDesc') }}</nut-cell>
    </div>
    <div v-if="status.gameStep === GameStepEnum.finished">
      <nut-cell-group :title="scoreDescription">
        <nut-cell
            v-for="(stat, index) in status.colorIndexToStat"
            :key="index"
        >
          <template #title>
        <span :style="{ color: colorHex[index], fontWeight: 'bold' }">
          {{ colorNames[index] }}
        </span>
          </template>
          <template #desc>
            {{ t('correctChar') }} {{ stat.rightCount }} <br/>
            {{ t('wrongChar') }} {{ stat.errorCount }} <br/>
            {{ t('scoreTitle') }} <strong>{{ stat.score }}</strong>
          </template>
        </nut-cell>
      </nut-cell-group>

      <nut-cell-group :title="t('playerScore')">
        <nut-cell
            v-for="(userId, index) in status.userIds"
            :key="index"
        >
          <template #title>
        <span :style="{ color: colorHex[getColorIndex(userId)], fontWeight: 'bold' }">
          {{ status.userIdToUserName[userId] }}
        </span>
          </template>
          <template #desc>
            {{ t('scoreTitle') }} {{ getUserScore(userId) }} <br/>
          </template>
        </nut-cell>
      </nut-cell-group>
    </div>
  </div>
</template>

<script setup lang="ts">
import {ref, computed, onMounted, onBeforeUnmount, inject, Ref, nextTick} from 'vue';
import {client, Request} from '../../../api/ws';
import {Path} from '../../../utils/constant.ts';
import {GameStepEnum, WordSlicerStatus, Word} from "../../../vo/WordSlicerStatus.ts";
import {bus, EventName} from "../../../api/bus.ts";
import {useI18n} from "vue-i18n";
import {useStore} from "vuex";
import {toNumber} from "../../../utils/convert.ts";
import Typing from "../../../component/typing.vue";
import Player from "./widget/player.vue";

const {t} = useI18n();
const store = useStore();
const status = ref<WordSlicerStatus>(new WordSlicerStatus());
const ignoreContentIndexes = ref<number[]>([]);
const typingRef = ref<InstanceType<typeof Typing>>();
const colorNames = [t('orange'), t('violet'), t('cyan')];
const colorHex = ['#f1ac40', '#e18be5', '#78fbfd'];

const overlayVisible = inject<Ref<boolean>>('overlayVisible')!;
const tipDialogVisible = inject<Ref<boolean>>('tipDialogVisible')!;
const tipDialogContent = inject<Ref<string>>('tipDialogContent')!;
const scoreDescription = computed(() =>
    t('eachCharScore', {score: status.value.scoreEachChar()})
);
const currentUserId = computed(() => toNumber(store.getters.currentUserId));

const isMyTurn = computed(() => {
  if (status.value.gameStep == GameStepEnum.finished) {
    return false;
  }
  return status.value.userIds[status.value.currUserIndex] === currentUserId.value;
});

const getColorIndex = (userId: number) => {
  return status.value.colorIndexToUserId.findIndex(ids => ids.includes(userId));
};

const getUserColor = (userId: number) => {
  const idx = getColorIndex(userId);
  return idx !== -1 ? colorHex[idx] : '#999';
};

const getUserScore = (userId: number) => {
  return status.value.userIdToScore[userId];
};

const getCurrUserColor = computed(() => {
  if (isMyTurn.value) {
    return getUserColor(status.value.userIds[status.value.currUserIndex]);
  } else {
    return '';
  }
});

const submit = async () => {
  if (!typingRef.value) return;

  overlayVisible.value = true;
  let res = null;
  try {
    const contentIndexToColor: Record<number, string> = typingRef.value.getContentIndexToColor();
    if (!contentIndexToColor) return;

    const allIndexes = Object.keys(contentIndexToColor).map(Number);
    const selectedContentIndexes = allIndexes
        .filter(idx => !ignoreContentIndexes.value.includes(idx))
        .sort((a, b) => a - b);

    if (selectedContentIndexes.length === 0) {
      res = await client.send(new Request({
        path: Path.wordSlicerSubmit,
        data: []
      }));
      return;
    }

    const isConsecutive = selectedContentIndexes.every((val, i) => {
      if (i === 0) return true;
      return val === selectedContentIndexes[i - 1] + 1;
    });

    if (!isConsecutive) {
      tipDialogVisible.value = true;
      tipDialogContent.value = t('wordSlicerConsecutiveError');
      return;
    }

    res = await client.send(new Request({
      path: Path.wordSlicerSubmit,
      data: selectedContentIndexes
    }));

  } catch (e) {
    tipDialogVisible.value = true;
    tipDialogContent.value = String(e);
  } finally {
    if (res != null && res.error) {
      tipDialogVisible.value = true;
      tipDialogContent.value = t(res!.error);
    }
    overlayVisible.value = false;
  }
};

const refresh = async () => {
  const ignoreIndexes: number[] = [];
  const contentIndexToColor: Record<number, string> = {};
  if (status.value.gameStep == GameStepEnum.finished) {
    const words: Word[] = status.value.getResult();
    for (const word of words) {
      const baseColor = colorHex[word.colorIndex];
      const resultColor = word.right ? '#0f0' : '#f00';

      for (let i = word.start; i <= word.end; i++) {
        contentIndexToColor[i] = `${baseColor},${resultColor}`;
        ignoreIndexes.push(i);
      }
    }
  } else {
    for (let i = 0; i < colorHex.length; i++) {
      const selectedContentIndex = i < status.value.colorIndexToSelectedContentIndex.length ? status.value.colorIndexToSelectedContentIndex[i] : null;
      if (!selectedContentIndex) {
        continue;
      }
      for (let j = 0; j < selectedContentIndex.length; j++) {
        contentIndexToColor[selectedContentIndex[j]] = colorHex[i];
        ignoreIndexes.push(selectedContentIndex[j]);
      }
    }
  }
  ignoreContentIndexes.value = ignoreIndexes.sort();
  await nextTick(() => {
    typingRef.value?.initContentIndexToColor(contentIndexToColor);
    typingRef.value?.initUserInput(status.value.content);
  });
};

onMounted(() => {
  bus().on(EventName.WordSlicerStatusUpdate, (data: WordSlicerStatus) => {
    status.value = data;
    refresh();
  });
});

onBeforeUnmount(() => {
  bus().off(EventName.WordSlicerStatusUpdate);
});
</script>
<style>
.nut-theme-light {
  --nut-cell-desc-color: black;
}
</style>
<style scoped>
.lobby {
  margin: 12px;
}

:deep(.correct) {
  color: #999;
  border-bottom-color: #999;
}

.player-order {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 8px;
  font-size: 14px;
}


.separator {
  color: #ccc;
  font-size: 12px;
}

.actions {
  margin-top: 20px;
  margin-bottom: 20px;
}

.nut-theme-dark {
  background: #1e1e1e;
}

</style>