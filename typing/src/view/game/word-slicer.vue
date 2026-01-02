<template>
  <Lobby v-if="status.gameStep==GameStepEnum.selectRule"></Lobby>
  <Game v-if="status.gameStep==GameStepEnum.started || status.gameStep==GameStepEnum.finished"></Game>
</template>

<script setup lang="ts">

import {ref, inject, onMounted, Ref, nextTick} from "vue";
import {bus, EventName, RefreshGameType} from "../../api/bus.ts";
import {useI18n} from "vue-i18n";
import {useStore} from "vuex";
import {useRoute, useRouter} from "vue-router";
import {client, Request, Response} from "../../api/ws.ts";
import {Path} from "../../utils/constant.ts";
import {GameStepEnum, WordSlicerStatus} from "../../vo/WordSlicerStatus.ts";
import Lobby from './word-slicer/lobby.vue';
import Game from './word-slicer/game.vue';

const {t} = useI18n();
const store = useStore();
const route = useRoute();
const router = useRouter();

const overlayVisible = inject<Ref<boolean>>('overlayVisible')!
const tipDialogVisible = inject<Ref<boolean>>('tipDialogVisible')!
const tipDialogContent = inject<Ref<string>>('tipDialogContent')!
const status = ref<WordSlicerStatus>(new WordSlicerStatus());
let refreshGame: RefreshGameType;
onMounted(async () => {
  refreshGame = RefreshGameType.from(route.query);
  await refresh(refreshGame);
  client.controllers.set(Path.wordSlicerStatusUpdate, async (req: Request) => {
    status.value = WordSlicerStatus.fromJson(req.data);
    await nextTick(() => {
      bus().emit(EventName.WordSlicerStatusUpdate, status.value);
    });
    return new Response();
  });
  bus().on(EventName.RefreshGame, (data: RefreshGameType) => {
    refreshGame = data;
    refresh(data);
  });
});

const refresh = async (refreshGame: RefreshGameType) => {
  try {
    overlayVisible.value = true;
    await getGameStatus();
    await router.replace({
      query: {
        verseId: refreshGame.verseId,
      },
    });
  } catch (error) {
    console.error('Failed to refresh game:', error);
  } finally {
    overlayVisible.value = false;
  }
};

const getGameStatus = async () => {
  const req = new Request({path: Path.wordSlicerStatus});
  const res0 = await client.node!.send(req);
  status.value = WordSlicerStatus.fromJson(res0.data);
  await nextTick(() => {
    bus().emit(EventName.WordSlicerStatusUpdate, status.value);
  });
};
</script>
<style>

</style>