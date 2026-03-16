<template>
  <div class="game-layout">
    <nut-navbar>
      <template #right>
        <router-link to="/game_score">
          <Order width="16px"></Order>
        </router-link>
        <div style="width: 10px"></div>
        <router-link to="/settings">
          <Setting width="16px"></Setting>
        </router-link>
      </template>
    </nut-navbar>

    <reconnect/>
    <div class="game-main">
      <router-view/>
    </div>
    <nut-overlay v-model:visible="overlayVisible">
      <div class="overlay-body">
        <div class="overlay-content">
          <Loading1/>
        </div>
      </div>
    </nut-overlay>
    <MyDialog
        v-model:visible="tipDialogVisible"
        :title="t('tips')"
        :content="tipDialogContent"
        :ok-text="t('confirm')"
        @ok="onOk"
    />
  </div>
</template>

<script setup lang="ts">
import {bus, EventName} from "../api/bus.ts";
import reconnect from '../component/reconnect.vue';
import MyDialog from '../component/mydialog.vue';
import {Setting, Order, Loading1} from '@nutui/icons-vue';
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
<style scoped>
.game-layout {
  display: flex;
  flex-direction: column;
  height: 100vh; /* 撑满整个屏幕 */
  overflow: hidden; /* 防止父容器本身产生滚动 */
}

.nav-header {
  flex-shrink: 0; /* 导航栏高度固定，不被压缩 */
}

.game-main {
  flex: 1; /* 占据剩余的所有空间 */
  overflow-y: auto; /* 如果内容过长，允许内部滚动 */
  display: flex;
  flex-direction: column;
}
</style>