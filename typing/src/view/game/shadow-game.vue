<template>
  <Settings v-if="isAdmin" :status="status"></Settings>

  <nut-cell v-else-if="cantPlayForMaintain">
    {{ t('cantPlayForMaintain') }}
  </nut-cell>

  <div v-else-if="ready" class='container'>
    <Game :status="status"></Game>
  </div>
</template>


<script setup lang="ts">
import {onMounted, ref, onBeforeUnmount, inject, Ref, computed, nextTick} from 'vue';
import {bus, EventName} from '../../api/bus.ts';
import {client, Request, Response} from '../../api/ws.ts';
import {Path} from '../../utils/constant.ts';
import {useStore} from "vuex";
import {useI18n} from "vue-i18n";
import Game from "./shadow/game.vue";
import Settings from "./shadow/settings.vue";
import {ShadowStatus} from "../../vo/ShadowStatus.ts";

const {t} = useI18n();
const store = useStore();

const status = ref<ShadowStatus>(new ShadowStatus());
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

    status.value = new ShadowStatus(res.data);
    await nextTick(() => {
      bus().emit(EventName.ShadowStatusUpdate, status.value);
    });
  } catch (error) {
    console.error('Failed to refresh shadow game:', error);
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
      status.value = new ShadowStatus(req.data);
      await nextTick(() => {
        bus().emit(EventName.ShadowStatusUpdate, status.value);
      });
      return new Response();
    });
    bus().on(EventName.ShadowStatusUpdate, (data) => {
      status.value = new ShadowStatus(data);
    });
  }
});

onBeforeUnmount(() => {
  bus().off(EventName.ShadowStatusUpdate);
});
</script>

<style scoped>
.container {
  display: flex;
  flex-direction: column;
  flex: 1;
  min-height: 0;
}
</style>
