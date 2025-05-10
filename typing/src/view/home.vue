<template>
  <nut-navbar :title="t('home')">
    <template #right>
      <router-link to="/settings">
        <Setting width="16px"></Setting>
      </router-link>
    </template>
  </nut-navbar>
  <reconnect/>
  <div style="margin: 8px">
    <nut-grid :column-num="1" square>
      <nut-grid-item text="entry game" clickable @click="onEntryGame">
        <PlayStart/>
      </nut-grid-item>
    </nut-grid>
  </div>

  <nut-dialog
      v-model:visible="dialogVisible"
      :title="t('tips')"
      :content="t('entryGameError')+gameNo"
      :okText="t('confirm')"
      :cancelText="t('cancel')"
      :onOk="onCloseDialog"
      :onCancel="onCloseDialog">
  </nut-dialog>
  <nut-overlay v-model:visible="overlayVisible">
    <div class="overlay-body">
      <div class="overlay-content">
        <Loading1/>
      </div>
    </div>
  </nut-overlay>
</template>

<script setup lang="ts">
import reconnect from '../component/reconnect.vue';
import {Setting, PlayStart, Loading1} from '@nutui/icons-vue';
import {useI18n} from 'vue-i18n';
import {onMounted, ref} from 'vue';
import {client, Request} from "../api/ws.ts";
import {LocationQueryRaw, useRouter} from "vue-router";
import {Path} from "../utils/constant.ts";

const router = useRouter();
const gameNo = ref('');
const dialogVisible = ref(false);
const overlayVisible = ref(false);
const {t} = useI18n();

onMounted(() => {
});

const onCloseDialog = () => {
  dialogVisible.value = false;
};

const onEntryGame = async () => {
  const req = new Request({path: Path.entryGame, data: 0});
  const res = await client.node!.send(req);
  overlayVisible.value = false;
  if (res.error) {
    gameNo.value = res.error;
    dialogVisible.value = true;
  } else {
    const refreshGame = res.data as LocationQueryRaw;
    await router.push({path: "/game", query: refreshGame});
  }
};

</script>