<template>
  <div v-if="isAdmin" style="margin: 8px">
    <nut-cell :title="t('ignoreCase')">
      <template #link>
        <nut-switch v-model="ignoreCase" @change="setIgnoreCase"/>
      </template>
    </nut-cell>
    <nut-cell :title="t('ignorePunctuation')">
      <template #link>
        <nut-switch v-model="ignorePunctuation" @change="setIgnorePunctuation"/>
      </template>
    </nut-cell>
  </div>
  <div v-else-if="ready" class="type-game-container">
    <div class="info-bar">
      <Ask class="info-icon" width="18px" height="18px" @click="showTips"/>
    </div>
    <div class="typing-content">
      <Typing
          :content="content"
          :disabled="false"
          :ignore-case="ignoreCase"
          :change-to-right-case-when-ignore-case="true"
          :ignore-punctuation="ignorePunctuation"
          :ignore-content-indexes="[]"
      />
    </div>

    <div class="actions">
      <nut-button shape="square" type="info" @click="tap('tapLeft')">
        {{ labels.left }}
      </nut-button>
      <nut-button shape="square" type="info" @click="tap('tapMiddle')">
        {{ labels.middle }}
      </nut-button>
      <nut-button shape="square" type="info" @click="tap('tapRight')">
        {{ labels.right }}
      </nut-button>
    </div>
  </div>
</template>
<script setup lang="ts">
import {onMounted, ref, onBeforeUnmount, inject, Ref, reactive, computed} from 'vue';
import {bus, EventName} from '../../api/bus.ts';
import {client, Request} from '../../api/ws.ts';
import {Path} from '../../utils/constant.ts';
import Typing from '../../component/typing.vue';
import {useStore} from "vuex";
import {useI18n} from "vue-i18n";
import {Ask} from '@nutui/icons-vue';

const {t} = useI18n();
const store = useStore();

const ignoreCase = ref(false);
const ignorePunctuation = ref(false);
const adminId = ref(0);
const content = ref('');
const labels = reactive({
  left: '',
  middle: '',
  right: ''
});

const overlayVisible = inject<Ref<boolean>>('overlayVisible')!;
const tipDialogVisible = inject<Ref<boolean>>('tipDialogVisible')!
const tipDialogContent = inject<Ref<string>>('tipDialogContent')!

const ready = computed(() => {
  return adminId.value !== 0;
});
const isAdmin = computed(() => {
  return adminId.value == store.getters.currentUserId;
});
const showTips = () => {
  const caseStatus = ignoreCase.value ? t('enabled') : t('disabled');
  const punctStatus = ignorePunctuation.value ? t('enabled') : t('disabled');
  tipDialogContent.value = `
    <b>${t('ignoreCase')}:</b> ${caseStatus}<br/>
    <b>${t('ignorePunctuation')}:</b> ${punctStatus}`;
  tipDialogVisible.value = true;
};
const getLabel = async () => {
  const req = new Request({
    path: Path.game,
    headers: {'jsMethod': 'TypeGame.label'},
  });
  const res = await client.node!.send(req);

  labels.left = res.data.left;
  labels.middle = res.data.middle;
  labels.right = res.data.right;
};

const getConfig = async () => {
  const req = new Request({
    path: Path.game,
    headers: {'jsMethod': 'TypeGame.getConfig'},
  });
  const res0 = await client.node!.send(req);
  const res = res0.data;
  ignorePunctuation.value = res['ignorePunctuation'];
  ignoreCase.value = res['ignoreCase'];
};
const getAdminId = async () => {
  const req = new Request({
    path: Path.gameAdminId,
  });
  const res0 = await client.node!.send(req);
  adminId.value = res0.data;
};
const tap = async (event: String) => {
  const req = new Request({
    path: Path.game,
    headers: {'jsMethod': 'TypeGame.tap'},
    data: event,
  });
  await client.node!.send(req);
  if (event == 'tapLeft') {
    await refresh();
  }
};

const setIgnoreCase = (value: boolean) => {
  setConfig("ignoreCase", value);
};
const setIgnorePunctuation = (value: boolean) => {
  setConfig("ignorePunctuation", value);
};
const setConfig = async (key: String, value: boolean) => {
  overlayVisible.value = true;
  const req = new Request({
    path: Path.game,
    headers: {'jsMethod': 'TypeGame.setConfig'},
    data: {key: key, value: value},
  });
  await client.node!.send(req);
  overlayVisible.value = false;
};
const refresh = async () => {
  try {
    overlayVisible.value = true;
    const req = new Request({
      path: Path.game,
      headers: {'jsMethod': 'TypeGame.answer'},
    });
    const res = await client.node!.send(req);
    content.value = res.data;

    await getLabel();
  } catch (error) {
    console.error('Failed to refresh game:', error);
  } finally {
    overlayVisible.value = false;
  }
};

onMounted(async () => {
  await getConfig();
  await refresh();
  await getAdminId();
  bus().on(EventName.RefreshGame, () => {
    refresh();
  });
});

onBeforeUnmount(() => {
  bus().off(EventName.RefreshGame);
});
</script>
<style scoped>
.type-game-container {
  display: flex;
  flex-direction: column;
  flex: 1; /* 继承父级的高度占满 */
}

.typing-content {
  flex: 1; /* 自动撑开，把 actions 挤到最下面 */
  padding: 10px;
  padding-top: 0;
}

.actions {
  display: flex;
  justify-content: space-around;
  padding: 10px 0;
  padding-bottom: env(safe-area-inset-bottom); /* 适配手机底部安全区 */
  flex-shrink: 0; /* 确保按钮高度不被挤压 */
}

.actions .nut-button {
  width: 32%; /* 留一点空隙更美观 */
}
.nut-theme-dark .info-icon {
  color: white;
}
.info-bar {
  display: flex;
  justify-content: flex-end;
  padding: 0 15px;
}
</style>