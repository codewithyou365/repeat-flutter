<template>
  <nut-navbar>
    <template #right>
      <router-link to="/settings">
        <Setting width="16px"></Setting>
      </router-link>
    </template>
  </nut-navbar>
  <reconnect/>
  <router-view/>
  <nut-overlay v-model:visible="overlayVisible">
    <div class="overlay-body">
      <div class="overlay-content">
        <Loading1/>
      </div>
    </div>
  </nut-overlay>
  <nut-dialog
      v-model:visible="tipDialogVisible"
      :title="t('tips')"
      :content="tipDialogContent"
      :okText="t('confirm')"
      :no-cancel-btn="true"
      :cancelText="t('cancel')"
      :onOk="onOk"
      :onCancel="onCancel">
  </nut-dialog>
</template>

<script setup lang="ts">
import {bus, EventName} from "../api/bus.ts";
import reconnect from '../component/reconnect.vue';
import {Setting, Loading1} from '@nutui/icons-vue';
import {onBeforeUnmount, onMounted, provide, ref} from 'vue';
import {ClientStatus} from "../api/ws.ts";
import {useRouter} from 'vue-router';
import {useI18n} from "vue-i18n";

const {t} = useI18n();

const overlayVisible = ref(false);
provide('overlayVisible', overlayVisible);
const tipDialogVisible = ref(false);
provide('tipDialogVisible', tipDialogVisible);
const tipDialogContent = ref('');
provide('tipDialogContent', tipDialogContent);

const router = useRouter();
onMounted(async () => {
  bus().on(EventName.WsStatus, (status: number) => {
    if (status === ClientStatus.CONNECT_CLOSE) {
      router.push('/loading');
    }
  });
});

onBeforeUnmount(() => {
  bus().off(EventName.WsStatus);
});

const onCancel = () => {
  console.log('event cancel')
}
const onOk = () => {
  console.log('event ok')
}
</script>
<style>

</style>