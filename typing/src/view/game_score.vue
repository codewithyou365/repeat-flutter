<template>
  <nut-navbar
      :title="t('settings')"
      left-show
      @click-back="onClickBack"
  />

  <nut-infinite-loading
      v-model="infinityValue"
      :has-more="hasMore"
      @load-more="loadMore"
  >
    <div
        class="test"
        v-for="item in historyList"
        :key="item.id"
    >
      <div>ID: {{ item.id }}</div>
      <div>Score: {{ item.score }}</div>
      <div>GameType: {{ item.gameType }}</div>
      <div class="time">{{ item.createdAt }}</div>
    </div>
  </nut-infinite-loading>
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
import {ref} from 'vue'
import {useI18n} from 'vue-i18n'
import {client, Request} from "../api/ws.ts";
import {Path} from "../utils/constant.ts";
import {GameUserScoreHistoryReq} from "../vo/GameUserScoreHistoryReq.ts";

const tipDialogVisible = ref(false);
const tipDialogContent = ref('');
const {t} = useI18n()

interface GameUserScoreHistory {
  id: number
  score: number
  gameType: number
  createdAt: string
}

const historyList = ref<GameUserScoreHistory[]>([])
const lastId = ref<number | undefined>(undefined)
const infinityValue = ref(false)
const hasMore = ref(true)

const PAGE_SIZE = 20;
const props = defineProps<{
  gameType: number;
}>();

const loadMore = async () => {
  const req = new Request({
    path: Path.gameUserScoreHistory, data: new GameUserScoreHistoryReq(
        props.gameType,
        PAGE_SIZE,
        lastId.value,
    )
  });
  const res0 = await client.node!.send(req);
  try {
    if (res0.error) {
      tipDialogVisible.value = true;
      tipDialogContent.value = t(res0.error);
      return;
    }
    const res = res0.data;
    const list: GameUserScoreHistory[] = res.history

    if (list.length < PAGE_SIZE) {
      hasMore.value = false
    }

    if (list.length > 0) {
      lastId.value = list[list.length - 1].id
      historyList.value.push(...list)
    }
  } finally {
    infinityValue.value = false
  }
}

const onClickBack = () => history.back()
const onCancel = () => {
  console.log('event cancel')
}
const onOk = () => {
  console.log('event ok')
}
</script>
<style>
.test {
  padding: 12px 0 12px 20px;
  border-top: 1px solid #eee;
}
</style>