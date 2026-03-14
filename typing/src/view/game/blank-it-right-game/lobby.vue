<template>
  <div class="lobby">
    <Player
        :user-ids="status.userIds"
        :user-id-to-user-name="status.userIdToUserName"
        :current-user-id="currentUserId"
        :curr-user-index="currUserIndex"
        :game-started="status.gameStatus == 'started'"
        :get-user-color="getUserColor">
    </Player>


    <nut-cell>
      <div class="lobby-actions">
        <div class="button-group">
          <nut-button
              shape="square"
              type="primary"
              @click="join"
              :disabled="status.gameStatus === 'started'">
            {{ joined ? t('leave') : t('join') }}
          </nut-button>

          <nut-button
              shape="square"
              type="info"
              @click="startGame"
              :disabled="!enoughUsers">
            {{ t('startGame') }}
          </nut-button>
        </div>

        <div v-if="!enoughUsers" class="min-players-tip">
          {{ t('minPlayersRequired') }}
        </div>
      </div>
    </nut-cell>
  </div>
</template>

<script setup lang="ts">
import {ref, computed, onMounted, onBeforeUnmount, inject, Ref} from 'vue';
import {client, Request} from '../../../api/ws';
import {Path} from '../../../utils/constant.ts';
import {bus, EventName} from "../../../api/bus.ts";
import {useI18n} from "vue-i18n";
import {useStore} from "vuex";
import {toNumber} from "../../../utils/convert.ts";
import Player from "../widget/player.vue";
import {BlankItRightStatus} from "../../../vo/BlankItRightStatus.ts";

const {t} = useI18n();
const store = useStore();
const status = ref<BlankItRightStatus>(new BlankItRightStatus());

const overlayVisible = inject<Ref<boolean>>('overlayVisible')!
const tipDialogVisible = inject<Ref<boolean>>('tipDialogVisible')!
const tipDialogContent = inject<Ref<string>>('tipDialogContent')!

const currentUserId = computed(() => toNumber(store.getters.currentUserId));
const currUserIndex = computed(() => {
  return status.value.userIds.indexOf(currentUserId.value);
});

const enoughUsers = computed(() => {
  return status.value.userIds.length > 0
});


const joined = computed(() => {
  return status.value.userIds.includes(currentUserId.value);
});

const join = async () => {
  if (joined.value) {
    await leaveGame();
  } else {
    await joinGame();
  }
};

const joinGame = async () => {
  overlayVisible.value = true;
  try {
    const res = await client.send(new Request({
      path: Path.game,
      headers: {'jsMethod': 'Game.join'},
      data: {userId: currentUserId.value}
    }));

    if (res?.error) {
      tipDialogVisible.value = true;
      tipDialogContent.value = t(res.error);
    }
  } finally {
    overlayVisible.value = false;
  }
};

const leaveGame = async () => {
  overlayVisible.value = true;
  try {
    const res = await client.send(new Request({
      path: Path.game,
      headers: {'jsMethod': 'Game.leave'},
      data: {userId: currentUserId.value}
    }));

    if (res?.error) {
      tipDialogVisible.value = true;
      tipDialogContent.value = t(res.error);
    }
  } finally {
    overlayVisible.value = false;
  }
};
const startGame = async () => {
  overlayVisible.value = true;
  const res = await client.send(new Request({
    path: Path.game,
    headers: {'jsMethod': 'Game.start'},
  }));
  if (res!.error) {
    tipDialogVisible.value = true;
    tipDialogContent.value = t(res!.error);
  }
  overlayVisible.value = false;
};


onMounted(() => {
  bus().on(EventName.BlankItRightStatusUpdate, (data: BlankItRightStatus) => {
    status.value = data
  });
});
onBeforeUnmount(() => {
  bus().off(EventName.BlankItRightStatusUpdate);
});
const getUserColor = (_: number) => {
  return '#f1ac40';
};
defineExpose({
  init(val: any) {
    status.value = val;
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
.lobby-actions {
  display: flex;
  flex-direction: column; /* 纵向排列 */
  width: 100%;
  gap: 12px; /* 元素间距 */
  align-items: center;
}

.button-group {
  display: flex;
  gap: 10px; /* 两个按钮之间的间距 */
  justify-content: center;
}

.min-players-tip {
  font-size: 12px;
  color: #fa2c19; /* 红色警告色 */
  margin-top: 4px;
  text-align: center;
}
</style>