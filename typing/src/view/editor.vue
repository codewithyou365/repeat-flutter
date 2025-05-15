<template>
  <nut-navbar :title="t('edit')" left-show @click-back="onClickBack">
    <template #right>
      <router-link to="/settings">
        <Setting width="16px"></Setting>
      </router-link>
    </template>
  </nut-navbar>
  <reconnect/>
  <editor type="json" :save="onStartSave" ref="editorComponent"/>
  <div class="container">
    <nut-button size="large" type="info" @click="onStartSave">{{ t('confirm') }}</nut-button>
  </div>
  <input class="hide-input" ref="noneEditorElement"/>
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
import {onBeforeUnmount, onMounted, nextTick, ref} from 'vue';
import {client, ClientStatus, Request} from "../api/ws.ts";

import editor from '../component/editor.vue';

import {useRoute, useRouter} from 'vue-router';

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
const route = useRoute();
const router = useRouter();

const editorComponent = ref<InstanceType<typeof editor> | null>(null);
const noneEditorElement = ref<HTMLElement | null>(null);
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
  window.addEventListener('keydown', handleKeyDown);
});

onBeforeUnmount(() => {
  bus().off(EventName.RefreshGame);
  bus().off(EventName.WsStatus);
  window.removeEventListener('keydown', handleKeyDown);
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
    const value = JSON.stringify(JSON.parse(res.content), null, 2);

    if (editorComponent.value) {
      const editorView = editorComponent.value.getEditorView();
      if (editorView) {
        editorView.dispatch({
          changes: {from: 0, to: editorView?.state.doc.length, insert: value},
        });
        console.log(editorView.state.doc.toString())
      }
    }

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
const handleKeyDown = (event: KeyboardEvent) => {
  let needFocusEditor = false;
  if (submitDialog.value) {
    if (event.key === "Escape") {
      submitDialog.value = false;
      needFocusEditor = true;
    } else if (event.key === "Enter") {
      submitDialog.value = false;
      onContentInput();
    }
  }
  if (dialog.value.visible) {
    if (event.key === "Escape") {
      dialog.value.visible = false;
      needFocusEditor = true;
    } else if (event.key === "Enter") {
      dialog.value.visible = false;
      needFocusEditor = true;
    }
  }
  if (needFocusEditor) {
    nextTick(() => {
      if (editorComponent.value) {
        editorComponent.value.focus();
      }
    });
  }
}
const onStartSave = () => {
  submitDialog.value = true;
  nextTick(() => {
    if (noneEditorElement.value) {
      noneEditorElement.value.focus();
    }
  });
}
const onContentInput = async () => {
  let segmentContent = '';
  if (editorComponent.value) {
    const editorView = editorComponent.value.getEditorView();
    if (editorView) {
      segmentContent = editorView.state.doc.toString();
    }
  }
  if (segmentContent === '') {
    dialog.value.visible = true;
    dialog.value.code = 'emptyContent';
    dialog.value.content = t('emptyContent');
    return;
  }
  try {
    overlayVisible.value = true;
    const data: SetSegmentContentReq = {
      gameId: refreshGame.id,
      content: segmentContent,
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

.hide-input {
  width: 0;
  height: 0;
  position: absolute;
  left: -99999px
}
</style>