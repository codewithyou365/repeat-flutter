<template>
  <nut-navbar
      :title="t('shopping')"
      left-show
      @click-back="onClickBack"
  />
  <div class="form-container">
    <nut-cell-group title="">
      <nut-cell :title="t('gameType')" :desc="selectedGameTypeText" is-link @click="openGameTypePicker"/>
      <nut-popup v-model:visible="showGameTypePicker" position="bottom">
        <nut-picker
            :cancel-text="t('cancel')"
            :ok-text="t('confirm')"
            :model-value="tempGameType"
            :columns="gameTypeColumns"
            :title="t('selectGameType')"
            @confirm="confirmGameType"
            @cancel="cancelGameType"
        />
      </nut-popup>
      <nut-cell :title="t('customReason')">
        <template #link>
          <nut-switch v-model="form.customReason"/>
        </template>
      </nut-cell>
      <nut-cell v-if="!form.customReason" :title="t('reason')" :desc="selectedReasonText" is-link
                @click="openReasonPicker"/>
      <nut-popup v-if="!form.customReason" v-model:visible="showReasonPicker" position="bottom">
        <nut-picker
            :cancel-text="t('cancel')"
            :ok-text="t('confirm')"
            :model-value="tempReason"
            :columns="reasonColumns"
            :title="t('selectReason')"
            @confirm="confirmReason"
            @cancel="cancelReason"
        />
      </nut-popup>
      <nut-cell v-if="form.customReason" :title="t('customReasonText')">
        <template #desc>
          <nut-input v-model="form.reason" placeholder=""/>
        </template>
      </nut-cell>
      <nut-cell :title="t('score')">
        <template #desc>
          <nut-input v-model="form.score" type="digit" placeholder=""/>
        </template>
      </nut-cell>
      <nut-cell class="submit-button">
        <nut-button type="primary" block @click="submit">{{ t('submit') }}</nut-button>
      </nut-cell>
    </nut-cell-group>
  </div>

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
import {computed, onMounted, ref, watch} from 'vue'
import {useI18n} from 'vue-i18n'
import {client, Request} from "../api/ws.ts";
import {GameType, Path} from "../utils/constant.ts";
import {showToast} from '@nutui/nutui'

const tipDialogVisible = ref(false);
const tipDialogContent = ref('');
const {t} = useI18n()

const form = ref({
  customReason: false,
  gameType: 2,
  reason: 'watchTv',
  score: 10,
})

const showGameTypePicker = ref(false)
const tempGameType = ref<number[]>([])
const showReasonPicker = ref(false)
const tempReason = ref<string[]>([])

const reasonColumns = [
  {text: t('watchTv'), value: 'watchTv'},
  {text: t('changeCurrency'), value: 'changeCurrency'},
  {text: t('playGame'), value: 'playGame'},
  {text: t('buyGame'), value: 'buyGame'},
  {text: t('buyItem'), value: 'buyItem'},
  {text: t('purchaseSkin'), value: 'purchaseSkin'},
  {text: t('unlockFeature'), value: 'unlockFeature'},
]

const selectedGameTypeText = computed(() => {
  const selected = gameTypeColumns.value.find(item => item.value === form.value.gameType)
  return selected ? selected.text : ''
})

const selectedReasonText = computed(() => {
  const selected = reasonColumns.find(item => item.value === form.value.reason)
  return selected ? selected.text : ''
})

const previousReason = ref('watchTv')

watch(() => form.value.customReason, (newVal) => {
  if (newVal) {
    previousReason.value = form.value.reason;
    form.value.reason = '';
  } else {
    form.value.reason = previousReason.value;
  }
})

const scores = ref<{ [key: number]: number }>({})

const gameTypeColumns = computed(() => [
  {text: t('gameTypeBlankItRight') + ` (${scores.value[GameType.BLANK_IT_RIGHT.code] ?? 0})`, value: 2},
  {text: t('gameTypeWordSlicer') + ` (${scores.value[GameType.WORD_SLICER.code] ?? 0})`, value: 2},
])

onMounted(async () => {
  const req = new Request({
    path: Path.gameUserScore,
  });
  const res0 = await client.node!.send(req);
  if (res0.error) {
    tipDialogVisible.value = true;
    tipDialogContent.value = t(res0.error);
  } else {
    scores.value = res0.data.reduce((acc: any, item: any) => {
      acc[item.gameType] = item.score;
      return acc;
    }, {})
  }
});

const openGameTypePicker = () => {
  tempGameType.value = [form.value.gameType]
  showGameTypePicker.value = true
}

const openReasonPicker = () => {
  tempReason.value = [form.value.reason]
  showReasonPicker.value = true
}

const submit = async () => {
  const scoreNum = form.value.score;
  if (isNaN(scoreNum) || scoreNum <= 0) {
    tipDialogVisible.value = true;
    tipDialogContent.value = t('scoreMustBePositive');
    return;
  }
  const maxScore = scores.value[form.value.gameType] ?? 0;
  if (scoreNum > maxScore) {
    tipDialogVisible.value = true;
    tipDialogContent.value = t('scoreExceedsAvailable') + maxScore;
    return;
  }
  if (!form.value.reason.trim()) {
    tipDialogVisible.value = true;
    tipDialogContent.value = t('reasonRequired');
    return;
  }

  const reqData = {
    customReason: form.value.customReason,
    gameType: form.value.gameType,
    reason: form.value.reason,
    score: scoreNum,
  };

  const req = new Request({
    path: Path.gameUserScoreMinus,
    data: reqData
  });
  const res = await client.node!.send(req);
  if (res.error) {
    tipDialogVisible.value = true;
    tipDialogContent.value = t(res.error);
  } else {
    showToast.success(t('operationSuccess'));
    history.back();
  }
}
const confirmGameType = ({selectedValue, selectedOptions}) => {
  form.value.gameType = selectedValue[0]
  showGameTypePicker.value = false
}

const cancelGameType = () => {
  showGameTypePicker.value = false
}

const confirmReason = ({selectedValue, selectedOptions}) => {
  form.value.reason = selectedValue[0]
  showReasonPicker.value = false
}

const cancelReason = () => {
  showReasonPicker.value = false
}

const onClickBack = () => history.back()

</script>


<style>
:root {
  --background-color: white;
  --text-primary: #333;
  --text-secondary: #666;
  --text-tertiary: #999;
  --positive-color: #2ecc71;
  --negative-color: #e74c3c;
  --border-color: #e0e0e0;
  --box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
}

.nut-theme-dark {
  --background-color: #1a1a1a;
  --text-primary: #ddd;
  --text-secondary: #bbb;
  --text-tertiary: #888;
  --positive-color: #2ecc71;
  --negative-color: #e74c3c;
  --border-color: #444;
  --box-shadow: 0 4px 6px rgba(0, 0, 0, 0.6);
  --nut-picker-ok-color: var(--positive-color);
  --nut-overlay-bg: rgba(0, 0, 0, 0.7);
}

.nut-picker__bar {
  background-color: var(--background-color);
}

.nut-picker-roller {
  background-color: var(--background-color);
}

.nut-picker__list {
  background-color: var(--nut-overlay-bg);
}

.form-container {
  margin: 8px;
}

.submit-button {
  margin-top: 16px;
}
</style>