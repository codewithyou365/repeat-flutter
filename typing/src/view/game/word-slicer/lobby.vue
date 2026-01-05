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
import Player from "./widget/player.vue";

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

</style>