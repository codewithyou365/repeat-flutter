<template>
  <Settings v-if="isAdmin">
  </Settings>

  <nut-cell v-else-if="cantPlayForMaintain">
    {{ t('cantPlayForMaintain') }}
  </nut-cell>

  <div v-else-if="ready" class='container'>
    <Lobby v-if="status.gameStatus === 'init'" :status="status"></Lobby>
    <Game v-if="status.gameStatus !== 'init'" :status="status"></Game>
  </div>
</template>


<script setup lang="ts">
import {onMounted, ref, onBeforeUnmount, inject, Ref, computed, nextTick} from 'vue';
import {bus, EventName} from '../../api/bus.ts';
import {client, Request, Response} from '../../api/ws.ts';
import {Path} from '../../utils/constant.ts';
import {useStore} from "vuex";
import {useI18n} from "vue-i18n";
import Lobby from "./blank-it-right-game/lobby.vue";
import Game from "./blank-it-right-game/game.vue";
import Settings from "./blank-it-right-game/settings.vue";
import {BlankItRightStatus} from "../../vo/BlankItRightStatus.ts";

const {t} = useI18n();
const store = useStore();


const status = ref<BlankItRightStatus>(new BlankItRightStatus());
const adminEnable = ref(false);
const adminId = ref(0);

// Injects
const overlayVisible = inject<Ref<boolean>>('overlayVisible')!;
const tipDialogVisible = inject<Ref<boolean>>('tipDialogVisible')!;
const tipDialogContent = inject<Ref<string>>('tipDialogContent')!;

// Computed
const currentUserId = computed(() => store.getters.currentUserId);
const ready = computed(() => adminId.value !== 0);
const isAdmin = computed(() => adminEnable.value && adminId.value == currentUserId.value);
const cantPlayForMaintain = computed(() => adminEnable.value && adminId.value != currentUserId.value);


const refresh = async () => {
  try {
    overlayVisible.value = true;
    const req = new Request({
      path: Path.game,
      headers: {
        'jsMethod': 'Game.getStatus',
      },
    });

    const res = await client.node!.send(req);
    if (res.error) {
      tipDialogVisible.value = true;
      tipDialogContent.value = t(res.error);
      return;
    }

    let payload = res.data;
    status.value = new BlankItRightStatus(payload);
    await nextTick(() => {
      bus().emit(EventName.BlankItRightStatusUpdate, status.value);
    });
  } catch (error) {
    console.error('Failed to refresh game:', error);
  } finally {
    overlayVisible.value = false;
  }
};
const getAdmin = async () => {
  const req = new Request({path: Path.gameAdmin});
  const res0 = await client.node!.send(req);
  const admin = res0.data;
  adminEnable.value = admin.adminEnable;
  adminId.value = admin.adminId;
};

onMounted(async () => {
  await getAdmin();
  if (!adminEnable.value) {
    await refresh();
    client.controllers.set('gameRefresh', async (req: Request) => {
      status.value = new BlankItRightStatus(req.data);
      await nextTick(() => {
        bus().emit(EventName.BlankItRightStatusUpdate, status.value);
      });
      return new Response();
    });
    bus().on(EventName.BlankItRightStatusUpdate, (data) => {
      status.value = new BlankItRightStatus(data);
    });
  }
});

onBeforeUnmount(() => {
  bus().off(EventName.BlankItRightStatusUpdate);
});
</script>

