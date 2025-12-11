<template>
  <nut-navbar
      :title="t('score')"
      left-show
      @click-back="onClickBack"
  />
  <nut-pull-refresh
      v-model="isRefreshing"
      :loading-txt="t('loading')"
      :pulling-txt="t('pullToRefresh')"
      :loosing-txt="t('looseToRefresh')"
      @refresh="refreshList">
    <nut-infinite-loading
        v-model="infinityValue"
        :has-more="hasMore"
        :load-txt="t('loading')"
        :load-more-txt="t('loadMoreTxt')"
        @load-more="loadMore">

      <div class="score-outline"
           v-for="item in historyList"
           :key="item.id">
        <div class="score-card">
          <div class="row">
            <div class="remark">
              {{ item.remark }}
            </div>
            <div
                class="score"
                :class="{ positive: item.inc > 0, negative: item.inc < 0 }"
            >
              {{ formatScore(item.inc) }}
            </div>
          </div>
          <div class="row">
            <div class="time">
              {{ item.createTime }}
            </div>
            <div class="balance">
              {{ t('balance') + item.after }}
            </div>
          </div>
        </div>
      </div>
    </nut-infinite-loading>
  </nut-pull-refresh>
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
import {onMounted, ref} from 'vue'
import {useI18n} from 'vue-i18n'
import {client, Request} from "../api/ws.ts";
import {Path} from "../utils/constant.ts";
import {GameUserScoreHistoryReq} from "../vo/GameUserScoreHistoryReq.ts";
import { showToast } from '@nutui/nutui'
const tipDialogVisible = ref(false);
const tipDialogContent = ref('');
const {t} = useI18n()

interface GameUserScoreHistory {
  id: number
  inc: number
  after: number
  remark: string
  gameType: number
  createTime: string
}

const historyList = ref<GameUserScoreHistory[]>([])
const lastId = ref<number | undefined>(undefined)
const infinityValue = ref(false)
const hasMore = ref(true)
const isRefreshing = ref(false)

const PAGE_SIZE = 20;

onMounted(async () => {
  infinityValue.value = true;
  isRefreshing.value = true;
  await loadMore();
});

const formatScore = (inc: number) => {
  return inc > 0 ? `+${inc}` : `${inc}`;
};

const loadMore = async () => {
  infinityValue.value = true;
  const req = new Request({
    path: Path.gameUserScoreHistory, data: new GameUserScoreHistoryReq(
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
      for (const item of list) {
        if (item.remark?.startsWith("i:")) {
          item.remark = t(item.remark.substring(2));
        }
      }
      historyList.value.push(...list)
    }
    if (historyList.value.length > 100) {
      hasMore.value = false;
    }
  } finally {
    isRefreshing.value = false;
    infinityValue.value = false
  }
}

const refreshList = async () => {
  isRefreshing.value = true;
  historyList.value = [];
  lastId.value = undefined;
  hasMore.value = true;
  await loadMore();
  showToast.text("", {
    title: t('loadingSuccess'),
  })
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
}

.score-outline {
  margin: 8px;
}

.score-card {
  padding: 8px;
  background: var(--background-color);
  border-radius: 8px;
  box-shadow: var(--box-shadow);
}

.row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 4px;
}

.score-card .remark {
  font-size: 14px;
  font-weight: 500;
  color: var(--text-primary);
  border-bottom: 1px solid var(--border-color);
}

.score-card .score {
  font-size: 14px;
  font-weight: 500;
}

.score-card .score.positive {
  color: var(--positive-color);
}

.score-card .score.negative {
  color: var(--negative-color);
}

.score-card .balance {
  font-size: 13px;
  color: var(--text-secondary);
  text-align: right;
}

.score-card .time {
  font-size: 12px;
  color: var(--text-tertiary);
}
</style>