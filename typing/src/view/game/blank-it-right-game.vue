<template>
  <!--  <div v-if="isAdmin" style="margin: 8px">-->
  <!--    <nut-cell :title="t('ignoreCase')">-->
  <!--      <template #link>-->
  <!--        <nut-switch v-model="status.config.ignoreCase" @change="(val) => updateConfig('ignoreCase', val)"/>-->
  <!--      </template>-->
  <!--    </nut-cell>-->
  <!--    <nut-cell :title="t('ignorePunctuation')">-->
  <!--      <template #link>-->
  <!--        <nut-switch v-model="status.config.ignorePunctuation"-->
  <!--                    @change="(val) => updateConfig('ignorePunctuation', val)"/>-->
  <!--      </template>-->
  <!--    </nut-cell>-->
  <!--  </div>-->

  <nut-cell v-if="cantPlayForMaintain">
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

/**
 * Fetch game status and map it to the local 'status' ref
 */
const refresh = async () => {
  try {
    overlayVisible.value = true;
    const req = new Request({
      path: Path.game,
      headers: {
        'jsMethod': 'Game.getStatus',
        // 建议把当前用户ID传过去，这样 JS 端的 currUserIndex 才能算对
        'userId': store.getters.currentUserId
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

const updateConfig = async (key: string, value: any) => {
  await client.node!.send(new Request({
    path: Path.game,
    headers: {'jsMethod': 'Game.setConfig'},
    data: {key, value}
  }));
  refresh(); // Refresh to sync the _config cache in JS
};

onMounted(async () => {
  await getAdmin();
  await refresh();

  // Listen for broadcast updates from other players
  bus().on(EventName.RefreshGame, () => refresh());
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
});

onBeforeUnmount(() => {
  bus().off(EventName.RefreshGame);
  bus().off(EventName.BlankItRightStatusUpdate);
});
</script>

