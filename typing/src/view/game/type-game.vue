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
  <nut-cell v-else-if="cantPlayForMaintain">
    {{ t('cantPlayForMaintain') }}
  </nut-cell>
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
import {onMounted, ref, inject, Ref, reactive, computed} from 'vue';
import {client, Request, Response} from '../../api/ws.ts';
import {Path} from '../../utils/constant.ts';
import Typing from '../../component/typing.vue';
import {useStore} from "vuex";
import {useI18n} from "vue-i18n";
import {Ask} from '@nutui/icons-vue';

const {t} = useI18n();
const store = useStore();

const ignoreCase = ref(false);
const ignorePunctuation = ref(false);
const adminEnable = ref(false);
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
const cantPlayForMaintain = computed(() => {
  return adminEnable.value && adminId.value != store.getters.currentUserId;
});

const isAdmin = computed(() => {
  return adminEnable.value && adminId.value == store.getters.currentUserId;
});


const showTips = () => {

  const formatStatus = (val: boolean) => val ? t('enabled') : t('disabled');

  const rows = [
    {label: t('ignoreCase'), value: formatStatus(ignoreCase.value)},
    {label: t('ignorePunctuation'), value: formatStatus(ignorePunctuation.value)}
  ];

  let html = `<div style="display: flex; flex-direction: column; gap: 10px; text-align: left;">`;

  html += rows.map((row, index) => {
    const isLast = index === rows.length - 1;
    const borderStyle = isLast ? '' : 'border-bottom: 1px solid rgba(128,128,128,0.15);';

    return `
      <div style="display: flex; justify-content: space-between; align-items: center; padding-bottom: ${isLast ? '0' : '6px'}; ${borderStyle}">
        <b style="font-size: 14px;">${row.label}</b>
        <span style="font-size: 14px; opacity: 0.8;">${row.value}</span>
      </div>
    `.replace(/\n/g, '');
  }).join('');

  html += `</div>`;

  tipDialogContent.value = html;
  tipDialogVisible.value = true;
};
const getLabel = async () => {
  const req = new Request({
    path: Path.game,
    headers: {'jsMethod': 'Game.label'},
  });
  const res = await client.node!.send(req);

  labels.left = res.data.left;
  labels.middle = res.data.middle;
  labels.right = res.data.right;
};

const getConfig = async () => {
  const req = new Request({
    path: Path.game,
    headers: {'jsMethod': 'Game.getConfig'},
  });
  const res0 = await client.node!.send(req);
  const res = res0.data;
  ignorePunctuation.value = res['ignorePunctuation'];
  ignoreCase.value = res['ignoreCase'];
};
const getAdmin = async () => {
  const req = new Request({
    path: Path.gameAdmin,
  });
  const res0 = await client.node!.send(req);
  const admin = res0.data;
  adminEnable.value = admin.adminEnable;
  adminId.value = admin.adminId;
};

const tap = async (event: String) => {
  const req = new Request({
    path: Path.game,
    headers: {'jsMethod': 'Game.tap'},
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
    headers: {'jsMethod': 'Game.setConfig'},
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
      headers: {'jsMethod': 'Game.answer'},
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
  await getAdmin();
  await refresh();
  client.controllers.set('gameRefresh', async (_: Request) => {
    await refresh();
    return new Response();
  });
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
  flex-shrink: 0;
}

.actions .nut-button {
  line-height: 1.1;
  width: 32%;
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