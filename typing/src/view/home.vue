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
      :title="t('pleaseInputGameNumber')"
      :okText="t('confirm')"
      :cancelText="t('cancel')"
      :onOk="onEntryGameOk"
      :onCancel="onEntryGameCancel">
    <nut-input clearable
               type="number"
               v-model="gameNo"
    />
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
import {showDialog} from "@nutui/nutui";
import {LocationQueryRaw, useRouter} from "vue-router";
import {Path} from "../utils/constant.ts";

const router = useRouter();
const gameNo = ref('');
const dialogVisible = ref(false);
const overlayVisible = ref(false);
const {t} = useI18n();

onMounted(() => {
});
const onCancel = () => {
  console.log('event cancel')
}
const onOk = () => {
  console.log('event ok')
}
const onEntryGameCancel = () => {
  dialogVisible.value = false;
};

const onEntryGameOk = async () => {
  overlayVisible.value = true;
  console.log('Game Number:', gameNo.value);
  const req = new Request({path: Path.entryGame, data: parseInt(gameNo.value)});
  const res = await client.node!.send(req);
  overlayVisible.value = false;
  dialogVisible.value = false;
  if (res.error) {
    showDialog({
      title: t('tips'),
      content: t('gameEntryCodeError'),
      noCancelBtn: true,
      okText: t('confirm'),
      onCancel,
      onOk
    })
  } else {
    const refreshGame = res.data as LocationQueryRaw;
    await router.push({path: "/game", query: refreshGame});
  }
};

const onEntryGame = () => {
  dialogVisible.value = true;
};

</script>