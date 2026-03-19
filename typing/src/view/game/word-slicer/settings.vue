<template>
  <div style="margin: 8px">
    <div class="manual-container">
      <div class="textarea-wrapper">
        <Ask
            color="#888"
            size="20px"
            class="ask-icon-absolute"
            @click="modifyWordSlicerContentTip"
        />
        <nut-textarea
            v-model="manualPreviewContent"
            :rows="3"
            autosize
            placeholder="请输入内容..."
        />
      </div>
      <div class="manual-actions">
        <nut-button size="small" shape="square" type="info" @click="onTap('tapLeft')">
          {{ labels.left }}
        </nut-button>
        <nut-button size="small" shape="square" type="info" @click="onTap('tapMiddle')">
          {{ labels.middle }}
        </nut-button>
        <nut-button size="small" shape="square" type="info" @click="onTap('tapRight')">
          {{ labels.right }}
        </nut-button>
      </div>
      <div class="manual-actions">
        <nut-button size="small" shape="square" type="primary" @click="updateVerse">
          {{ t('submit') }}
        </nut-button>
        <nut-button size="small" shape="square" type="info" @click="onReset">
          {{ t('reset') }}
        </nut-button>
      </div>
    </div>
    <nut-cell :title="t('hiddenPercent')">
      <template #link>
        <nut-input-number
            v-model="hiddenContentPercent"
            :step="10" min="0" max="100"
            @change="updateHiddenContentPercent"
        />
        <span style="margin-left: 8px;">%</span>
      </template>
    </nut-cell>

    <nut-cell :title="t('maxScore')">
      <template #link>
        <nut-input-number
            v-model="config.maxScore"
            :step="5" min="5" max="100"
            @change="val => update('maxScore', val)"
        />
      </template>
    </nut-cell>

    <nut-cell>
      <template #title>
        <div style="display: flex; align-items: center;">
          <span>{{ t('passingRate') }}</span>
          <Ask color="#999" size="16px" style="margin-left: 6px; cursor: pointer;" @click="showHelp"/>
        </div>
      </template>
      <template #link>
        <div style="display: flex; align-items: center">
          <nut-input-number
              v-model="passingRatePercent"
              :step="10" min="10" max="100"
              @change="updatePassingRate"
          />
          <span style="margin-left: 8px;">%</span>
        </div>
      </template>
    </nut-cell>
  </div>
</template>

<script setup lang="ts">
import {ref, onMounted, inject, Ref, nextTick, reactive, watch} from 'vue';
import {useI18n} from 'vue-i18n';
import {client, Request, Response} from '../../../api/ws.ts';
import {Path} from '../../../utils/constant.ts';
import {Ask} from "@nutui/icons-vue";
import {showToast} from "@nutui/nutui";

const {t} = useI18n();

const config = ref({
  autoBlank: true,
  hiddenContentPercent: 0.5,
  ignoreCase: true,
  ignorePunctuation: false,
  maxScore: 10,
  shouldRememberIfPassingRate: 0.8
});

const manualPreviewContent = ref('');
const labels = reactive({left: '', middle: '', right: ''});
const hiddenContentPercent = ref(50);
const passingRatePercent = ref(80);
const isInitializing = ref(false);

const tipDialogVisible = inject<Ref<boolean>>('tipDialogVisible')!;
const tipDialogContent = inject<Ref<string>>('tipDialogContent')!;

const fetchManualContent = async () => {
  try {
    const res = await client.node!.send(new Request({
      path: Path.game,
      headers: {'jsMethod': 'Game.getWordSlicerText'}
    }));

    if (res.data) {
      manualPreviewContent.value = res.data.answer;
      await nextTick();
    }
  } catch (e) {
    console.error("Fetch manual content failed:", e);
  }
};

watch(() => config.value.autoBlank, async (newVal) => {
  if (!newVal) {
    await fetchManualContent();
  }
});

const onReset = async () => {
  await client.node!.send(new Request({
    path: Path.game,
    headers: {'jsMethod': 'Game.resetWordSlicerText'}
  }));
  await fetchManualContent();
};
const updateVerse = async () => {

  const currentContent = manualPreviewContent.value;

  try {
    const res = await client.node!.send(new Request({
      path: Path.game,
      headers: {'jsMethod': 'Game.setWordSlicerText'},
      data: currentContent,
    }));

    if (res.status === 200) {
      showToast.text(t('success') || 'Success');
    } else {
      showToast.warn(res.error || 'Update Failed');
    }
  } catch (e) {
    console.error("Update Verse failed:", e);
  }
};

// 获取按钮标签
const refreshLabels = async () => {
  const resLabel = await client.node!.send(new Request({
    path: Path.game,
    headers: {'jsMethod': 'Game.label'}
  }));
  if (resLabel.data) {
    Object.assign(labels, resLabel.data);
  }
};

// 初始化拉取所有配置
const fetchAll = async () => {
  isInitializing.value = true;
  const resConfig = await client.node!.send(new Request({
    path: Path.game,
    headers: {'jsMethod': 'Game.getConfig'}
  }));

  if (resConfig.data) {
    config.value = {...config.value, ...resConfig.data};
    passingRatePercent.value = Math.round((config.value.shouldRememberIfPassingRate) * 100);
    hiddenContentPercent.value = Math.round((config.value.hiddenContentPercent) * 100);
  }

  await fetchManualContent();

  await refreshLabels();
  isInitializing.value = false;
};

const update = async (key: string, value: any) => {
  if (isInitializing.value) return;
  await client.node!.send(new Request({
    path: Path.game,
    headers: {'jsMethod': 'Game.setConfig'},
    data: {key, value}
  }));
};

const onTap = async (type: string) => {
  await client.node!.send(new Request({
    path: Path.game,
    headers: {'jsMethod': 'Game.tap'},
    data: type
  }));

  await refreshLabels();

  await fetchManualContent();
};
const updateHiddenContentPercent = (val: number) => {
  update('hiddenContentPercent', val / 100);
};


const updatePassingRate = (val: number) => {
  update('shouldRememberIfPassingRate', val / 100);
};
const modifyWordSlicerContentTip = () => {
  tipDialogContent.value = t('modifyWordSlicerContentTip');
  tipDialogVisible.value = true;
};
const showHelp = () => {
  tipDialogContent.value = t('passingRateTip');
  tipDialogVisible.value = true;
};

onMounted(async () => {
  await fetchAll();
  client.controllers.set('gameRefresh', async (_: Request) => {
    await fetchAll();
    return new Response();
  });
});

</script>

<style scoped>
.textarea-wrapper {
  position: relative;
  width: 100%;
}

/* 绝对定位的图标 */
.ask-icon-absolute {
  position: absolute;
  top: 8px; /* 距离顶部距离 */
  right: 8px; /* 距离右侧距离 */
  z-index: 10; /* 确保在输入框之上 */
  cursor: pointer;
  transition: opacity 0.2s;
}

.ask-icon-absolute:hover {
  opacity: 0.7;
}

.manual-container {
  padding: 12px;
  background: #f7f8fa;
  border-radius: 8px;
  margin: 0 8px 12px 8px;
}

.preview-box {
  min-height: 60px;
  margin-bottom: 12px;
  font-size: 18px;
  background: white;
  padding: 8px;
  border-radius: 4px;
}

.manual-actions {
  display: flex;
  gap: 8px;
  margin-top: 12px;
}

.manual-actions .nut-button {
  flex: 1;
  line-height: 1.1;
  height: 36px;
}

.nut-theme-dark .manual-container {
  background: #1d1d1d;
}

.nut-theme-dark .preview-box {
  background: #2d2d2d;
  color: #ccc;
}
</style>