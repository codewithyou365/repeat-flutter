<template>
  <div style="margin: 8px">
    <nut-cell :title="t('autoBlank')">
      <template #link>
        <nut-switch v-model="config.autoBlank" @change="val => update('autoBlank', val)"/>
      </template>
    </nut-cell>


    <div v-if="!config.autoBlank" class="manual-container">
      <div class="preview-box">
        <Typing
            :content="manualPreviewContent"
            :disabled="true"
            :ignore-case="false"
            :change-to-right-case-when-ignore-case="false"
            :ignore-punctuation="false"
            :ignore-content-indexes="[]"
            :click-fill-char-when-disabled="'•'"
            ref="typingRef"
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
    <nut-cell :title="t('blankPercent')">
      <template #link>
        <nut-input-number
            v-model="blankContentPercent"
            :step="10" min="10" max="100"
            @change="updateBlankContentPercent"
        />
        <span style="margin-left: 8px;">%</span>
      </template>
    </nut-cell>

    <nut-cell :title="t('ignoreCase')">
      <template #link>
        <nut-switch v-model="config.ignoreCase" @change="val => update('ignoreCase', val)"/>
      </template>
    </nut-cell>

    <nut-cell :title="t('ignorePunctuation')">
      <template #link>
        <nut-switch v-model="config.ignorePunctuation" @change="val => update('ignorePunctuation', val)"/>
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
import Typing from "../../../component/typing.vue";
import {showToast} from "@nutui/nutui";

const typingRef = ref<InstanceType<typeof Typing>>();
const {t} = useI18n();

const config = ref({
  autoBlank: true,
  blankContentPercent: 0.5,
  ignoreCase: true,
  ignorePunctuation: false,
  maxScore: 10,
  shouldRememberIfPassingRate: 0.8
});

const manualPreviewContent = ref('');
const labels = reactive({left: '', middle: '', right: ''});
const blankContentPercent = ref(50);
const passingRatePercent = ref(80);
const isInitializing = ref(false);

const tipDialogVisible = inject<Ref<boolean>>('tipDialogVisible')!;
const tipDialogContent = inject<Ref<string>>('tipDialogContent')!;

const fetchManualContent = async () => {
  try {
    const res = await client.node!.send(new Request({
      path: Path.game,
      headers: {'jsMethod': 'Game.getBlankContent'}
    }));

    if (res.data) {
      manualPreviewContent.value = res.data.answer;
      await nextTick();
      typingRef.value?.initUserInput(res.data.blank);
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
    headers: {'jsMethod': 'Game.resetManualBlank'}
  }));
  await fetchManualContent();
};
const updateVerse = async () => {
  if (!typingRef.value) return;

  const currentContent = typingRef.value.getUserInput();

  try {
    const res = await client.node!.send(new Request({
      path: Path.game,
      headers: {'jsMethod': 'Game.setBlankContent'},
      data: currentContent,
    }));

    if (res.status === 200) {
      showToast.success(t('updateSuccess') || 'Success');
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
    passingRatePercent.value = Math.round((config.value.shouldRememberIfPassingRate || 0.8) * 100);
    blankContentPercent.value = Math.round((config.value.blankContentPercent || 0.5) * 100);
  }

  // 如果当前已经是手动模式，主动初始化内容
  if (!config.value.autoBlank) {
    await fetchManualContent();
  }

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

  if (!config.value.autoBlank) {
    await fetchManualContent();
  }
};
const updateBlankContentPercent = (val: number) => {
  update('blankContentPercent', val / 100);
};


const updatePassingRate = (val: number) => {
  update('shouldRememberIfPassingRate', val / 100);
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
  margin-bottom: 12px;
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