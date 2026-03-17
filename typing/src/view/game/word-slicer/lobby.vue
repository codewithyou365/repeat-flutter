<template>
  <div class="lobby">
    <div class="top-bar">
      <Ask color="#888" size="22px" @click="onShowHelp" class="ask-icon"/>
    </div>
    <Player
        :user-ids="status.userIds"
        :user-id-to-user-name="status.userIdToUserName"
        :current-user-id="currentUserId"
        :curr-user-index="status.currUserIndex"
        :game-started="status.gameStep===GameStepEnum.started"
        :get-user-color="getUserColor">
    </Player>

    <nut-cell>{{ t('wordSlicerSelectRole') }}</nut-cell>

    <nut-cell>
      <nut-radio-group v-model="selectedOption">
        <nut-radio
            v-for="(colorName, index) in colorNames"
            :key="index"
            :label="index.toString()"
            @click.prevent="handleRadioClick(index.toString())"
        >
    <span :style="{ color: colorHex[index] }">
      {{ colorName }}
      {{ getOccupiedNames(index) }}
    </span>
        </nut-radio>
      </nut-radio-group>
    </nut-cell>

    <nut-cell v-if="!enoughUsers">
      {{ t('minPlayersRequired') }}
    </nut-cell>
    <nut-cell v-if="enoughUsers">
      <nut-button shape="square" type="primary"
                  @click="startGame"
                  :disabled="!enoughUsers">
        {{ t('startGame') }}
      </nut-button>
    </nut-cell>
  </div>
</template>

<script setup lang="ts">
import {computed, inject, onBeforeUnmount, onMounted, ref, Ref} from 'vue';
import {client, Request} from '../../../api/ws';
import {Path} from '../../../utils/constant.ts';
import {GameStepEnum, WordSlicerStatus} from "../../../vo/WordSlicerStatus.ts";
import {bus, EventName} from "../../../api/bus.ts";
import {useI18n} from "vue-i18n";
import {useStore} from "vuex";
import {toNumber} from "../../../utils/convert.ts";
import Player from "../widget/player.vue";
import {Ask} from "@nutui/icons-vue";

const {t} = useI18n();
const store = useStore();
const status = ref<WordSlicerStatus>(new WordSlicerStatus());
const selectedOption = ref<string>("");

const colorNames = [t('orange'), t('violet'), t('cyan')];
const colorHex = ['#f1ac40', '#e18be5', '#78fbfd'];

const overlayVisible = inject<Ref<boolean>>('overlayVisible')!
const tipDialogVisible = inject<Ref<boolean>>('tipDialogVisible')!
const tipDialogContent = inject<Ref<string>>('tipDialogContent')!

const currentUserId = computed(() => toNumber(store.getters.currentUserId));
const getOccupiedNames = (index: number) => {
  const ids = status.value.colorIndexToUserId[index] || [];
  if (ids.length === 0) return "";
  const names = ids.map(id => status.value.userIdToUserName[id] || `User:${id}`);
  return `(${names.join(', ')})`;
};

const enoughUsers = computed(() => {
  return status.value.userIds.length > 0
});

const onShowHelp = () => {
  const config = status.value.config;
  if (!config) return;

  const rows = [
    {label: t('hiddenPercent'), value: `${Math.round((config.hiddenContentPercent) * 100)}%`},
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
const handleRadioClick = (val: string) => {
  const targetIndex = parseInt(val);
  const userId = currentUserId.value;

  const isAlreadyInThisColor = status.value.colorIndexToUserId[targetIndex]?.includes(userId);

  if (isAlreadyInThisColor) {
    selectedOption.value = "";
    client.send(new Request({
      path: Path.game,
      headers: {
        'jsMethod': 'Game.leave',
      }
    }));
  } else {
    client.send(new Request({
      path: Path.game,
      headers: {
        'jsMethod': 'Game.selectRole',
      },
      data: {index: targetIndex}
    }));
  }
};
const startGame = async () => {
  overlayVisible.value = true;
  const res = await client.send(new Request({
    path: Path.game,
    headers: {
      'jsMethod': 'Game.start',
    },
  }));
  if (res!.error) {
    tipDialogVisible.value = true;
    tipDialogContent.value = t(res!.error);
  }
  overlayVisible.value = false;
};
const refresh = () => {
  const currentUserId = toNumber(store.getters.currentUserId);
  const colorIdx = status.value.colorIndexToUserId.findIndex(ids => ids.includes(currentUserId));
  if (colorIdx !== -1) selectedOption.value = colorIdx.toString();
}
onMounted(() => {
  bus().on(EventName.WordSlicerStatusUpdate, (data: WordSlicerStatus) => {
    status.value = data
    refresh();
  });
});
onBeforeUnmount(() => {
  bus().off(EventName.WordSlicerStatusUpdate);
});
const getUserColor = (userId: number) => {
  const colorIndex = status.value.colorIndexToUserId.findIndex(ids => ids.includes(userId));
  if (colorIndex !== -1) {
    return colorHex[colorIndex];
  }
  return '';
};
defineExpose({
  initUser(val: any) {
    status.value = WordSlicerStatus.fromJson(val);
    refresh();
  },
});
</script>

<style>
.nut-theme-light {
  --nut-radio-icon-disable-color2: #fa2c19;
}

.nut-theme-dark {
  --nut-radio-icon-disable-color2: #fa2c19;
}
</style>

<style scoped>
.lobby {
  margin: 12px;
}
.top-bar {
  display: flex;
  justify-content: flex-end;
  padding: 12px 16px 0 0;
}
</style>