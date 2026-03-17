<template>
  <Settings v-if="isAdmin">
  </Settings>
  <nut-cell v-else-if="cantPlayForMaintain">
    {{ t('cantPlayForMaintain') }}
  </nut-cell>
  <Lobby v-else-if="status.gameStep==GameStepEnum.selectRole"></Lobby>
  <Game v-else></Game>
</template>

<script setup lang="ts">

import {ref, onMounted, nextTick, computed, inject, Ref, onBeforeUnmount} from "vue";
import {bus, EventName} from "../../api/bus.ts";
import {client, Request, Response} from "../../api/ws.ts";
import {Path} from "../../utils/constant.ts";
import {GameStepEnum, WordSlicerStatus} from "../../vo/WordSlicerStatus.ts";
import Lobby from './word-slicer/lobby.vue';
import Game from './word-slicer/game.vue';
import Settings from "./word-slicer/settings.vue";
import {useStore} from "vuex";
import {useI18n} from "vue-i18n";

const {t} = useI18n();
const store = useStore();

const status = ref<WordSlicerStatus>(new WordSlicerStatus());
const adminEnable = ref(false);
const adminId = ref(0);

// Injects
const overlayVisible = inject<Ref<boolean>>('overlayVisible')!;
const tipDialogVisible = inject<Ref<boolean>>('tipDialogVisible')!;
const tipDialogContent = inject<Ref<string>>('tipDialogContent')!;
const currentUserId = computed(() => store.getters.currentUserId);
const isAdmin = computed(() => adminEnable.value && adminId.value == currentUserId.value);
const cantPlayForMaintain = computed(() => adminEnable.value && adminId.value != currentUserId.value);
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
    await getGameStatus();
    client.controllers.set('gameRefresh', async (req: Request) => {
      status.value = WordSlicerStatus.fromJson(req.data);
      await nextTick(() => {
        bus().emit(EventName.WordSlicerStatusUpdate, status.value);
      });
      return new Response();
    });
    bus().on(EventName.WordSlicerStatusUpdate, (data) => {
      status.value = WordSlicerStatus.fromJson(data);
    });
  }
});

onBeforeUnmount(() => {
  bus().off(EventName.WordSlicerStatusUpdate);
});

const getGameStatus = async () => {
  const req = new Request({
    path: Path.game,
    headers: {
      'jsMethod': 'Game.getStatus',
    },
  });
  const res = await client.node!.send(req);
  status.value = WordSlicerStatus.fromJson(res.data);
  await nextTick(() => {
    bus().emit(EventName.WordSlicerStatusUpdate, status.value);
  });
};
</script>
<style>

</style>