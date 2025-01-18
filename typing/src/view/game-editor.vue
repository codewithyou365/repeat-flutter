<template>
  <nut-navbar :title="t('edit')" left-show @click-back="onClickBack">
    <template #right>
      <router-link to="/settings">
        <Setting width="16px"></Setting>
      </router-link>
    </template>
  </nut-navbar>
  <reconnect/>
  <div class="container">
    <nut-textarea
        v-model="segmentContent"
        clearable
        :rows="20"
        :placeholder="t('pleaseInput')"
        type="text"/>
    <nut-button size="large" type="info" @click="submitDialog=true">{{ t('confirm') }}</nut-button>
  </div>
  <nut-dialog
      v-model:visible="submitDialog"
      :title="t('tips')"
      :content="t('confirmSegmentContent')"
      :okText="t('confirm')"
      :cancelText="t('cancel')"
      :onOk="onContentInput">
  </nut-dialog>
  <nut-dialog
      v-model:visible="dialog.visible"
      :title="t('tips')"
      :content="dialog.content"
      :okText="t('confirm')"
      :cancelText="t('cancel')"
      :noCancelBtn="true"
      :onOk="onOk">
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
import {bus, EventName, RefreshGameType} from "../api/bus.ts";
import {GetSegmentContentReq, GetSegmentContentRes, Path, SetSegmentContentReq} from "../utils/constant.ts";


import reconnect from '../component/reconnect.vue';
import {Setting, Loading1} from '@nutui/icons-vue';
import {useI18n} from 'vue-i18n';
import {onBeforeUnmount, onMounted, ref} from 'vue';
import {client, ClientStatus, Request} from "../api/ws.ts";

const segmentContent = ref('');
const overlayVisible = ref(false);

class Dialog {
  content: string = '';
  visible: boolean = false;
  code: string = '';
}

const submitDialog = ref(false);
const dialog = ref<Dialog>(new Dialog());

const {t} = useI18n();
let refreshGame: RefreshGameType;
import {useRoute, useRouter} from 'vue-router';

const route = useRoute();
const router = useRouter();

onMounted(async () => {
  refreshGame = RefreshGameType.from(route.query);

  await refresh(refreshGame);
  bus().on(EventName.RefreshGame, (data: RefreshGameType) => {
    refreshGame = data;
    refresh(data);
  });
  bus().on(EventName.WsStatus, (status: number) => {
    if (status === ClientStatus.CONNECT_FINISH) {
      router.push('/loading');
    }
  });
});

onBeforeUnmount(() => {
  bus().off(EventName.RefreshGame);
  bus().off(EventName.WsStatus);
});

const refresh = async (refreshGame: RefreshGameType) => {
  try {
    overlayVisible.value = true;
    const data: GetSegmentContentReq = {
      gameId: refreshGame.id,
    };

    const req = new Request({path: Path.getSegmentContent, data});
    const res0 = await client.node!.send(req);
    const res = GetSegmentContentRes.from(res0.data);
    segmentContent.value = JSON.stringify(JSON.parse(res.content), null, 2);

    await router.replace({
      query: {
        id: refreshGame.id,
        time: refreshGame.time,
      },
    });
  } catch (error) {
    console.error('Failed to refresh game:', error);
  } finally {
    overlayVisible.value = false;
  }
}

const onOk = () => {
  dialog.value.visible = false;
  if (dialog.value.code === '') {
  } else if (dialog.value.code === 'editModeDisabled') {
    history.back();
  } else {
    router.push('/home');
  }
}

const onContentInput = async () => {
  try {
    overlayVisible.value = true;
    const data: SetSegmentContentReq = {
      gameId: refreshGame.id,
      content: segmentContent.value,
    };

    overlayVisible.value = true;
    const req = new Request({path: Path.setSegmentContent, data});
    const res = await client.node!.send(req);
    dialog.value.visible = true;
    dialog.value.code = res.error;
    if (res.error) {
      dialog.value.content = t(res.error);
    } else {
      dialog.value.content = t('success');
    }
  } catch (error) {
    console.error('Failed to refresh game:', error);
  } finally {
    overlayVisible.value = false;
  }
}

const onClickBack = () => history.back();
</script>
<style>
.container {
  margin: 8px;
}
</style>