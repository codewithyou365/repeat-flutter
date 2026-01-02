<template>
  <div class="lobby">
    <nut-cell>
      <div class="player-order">
        <template v-for="(userId, index) in status.userIds" :key="userId">
      <span
          class="player-tag"
          :class="{ 'is-me': userId === toNumber(store.getters.currentUserId) }"
          :style="{
          borderLeft: getUserColor(userId) ? `8px solid ${getUserColor(userId)}` : 'none',
          paddingLeft: getUserColor(userId) ? '6px' : '8px'
        }"
      >
        {{ index + 1 }}. {{ status.userIdToUserName[userId] }}
      </span>
          <span v-if="index < status.userIds.length - 1" class="separator">➡️</span>
        </template>
      </div>
    </nut-cell>

    <nut-cell>{{ t('wordSlicerSelectRole') }}</nut-cell>

    <nut-cell>
      <nut-radio-group v-model="selectedOption" @change="handleSelectionChange">
        <nut-radio v-for="(colorName, index) in colorNames"
                   :key="index"
                   :label="index.toString()">
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
import {ref, computed, onMounted, onBeforeUnmount, inject, Ref} from 'vue';
import {client, Request} from '../../../api/ws';
import {Path} from '../../../utils/constant.ts';
import {WordSlicerStatus} from "../../../vo/WordSlicerStatus.ts";
import {bus, EventName} from "../../../api/bus.ts";
import {useI18n} from "vue-i18n";
import {useStore} from "vuex";
import {toNumber} from "../../../utils/convert.ts";

const {t} = useI18n();
const store = useStore();
const status = ref<WordSlicerStatus>(new WordSlicerStatus());
const selectedOption = ref<string>("");

const colorNames = [t('orange'), t('violet'), t('cyan')];
const colorHex = ['#f1ac40', '#e18be5', '#78fbfd'];

const overlayVisible = inject<Ref<boolean>>('overlayVisible')!
const tipDialogVisible = inject<Ref<boolean>>('tipDialogVisible')!
const tipDialogContent = inject<Ref<string>>('tipDialogContent')!
const getOccupiedNames = (index: number) => {
  const ids = status.value.colorIndexToUserId[index] || [];
  if (ids.length === 0) return "";
  const names = ids.map(id => status.value.userIdToUserName[id] || `User:${id}`);
  return `(${names.join(', ')})`;
};

const enoughUsers = computed(() => {
  let count = 0;
  for (let i = 0; i < 3; i++) {
    if (status.value.colorIndexToUserId[i].length > 0) {
      count++;
    }
  }
  return count >= 2;
});

const handleSelectionChange = (val: string) => {
  client.send(new Request({path: Path.wordSlicerSelectRole, data: {index: parseInt(val)}}));
};

const startGame = async () => {
  overlayVisible.value = true;
  const res = await client.send(new Request({path: Path.wordSlicerStartGame}));
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

.player-order {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 8px;
  font-size: 14px;
}

.player-tag {
  padding: 2px 8px;
  background: #f0f0f0;
  border-radius: 4px;
  color: #666;
  transition: all 0.2s;
}

.player-tag.is-me {
  background: #f0f0f0;
  color: black;
  font-weight: bold;
}

.separator {
  color: #ccc;
  font-size: 12px;
}

.nut-theme-dark .player-tag {
  background: #333333;
  color: #bbbbbb;
  border: 1px solid #444444;
}

.nut-theme-dark .player-tag.is-me {
  background: #333333;
  color: #ffffff;
  border-color: transparent;
}

.nut-theme-dark .separator {
  color: #666666;
}

.nut-theme-dark .player-tag b {
  color: #ffd700;
}
</style>