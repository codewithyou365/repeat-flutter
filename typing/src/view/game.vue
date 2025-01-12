<template>
  <nut-navbar left-show @click-back="onClickBack">
    <template #right>
      <router-link to="/settings">
        <Setting width="16px"></Setting>
      </router-link>
    </template>
  </nut-navbar>
  <reconnect/>
  <div style="margin: 8px">
    <div v-for="(item, index) in record" :key="index" class="history-item">
      <div v-for="(element, subIndex) in item.input" :key="subIndex" class="history-word">
        <div v-for="(char, subCharIndex) in element" :key="subCharIndex" class="history-char">
          <span class="input-hit" v-if="char!==replaceChar && item.output[subIndex] && item.output[subIndex][subCharIndex] && item.output[subIndex][subCharIndex]===char">{{ char }}</span>
          <span class="input-error" v-else-if="char!==replaceChar">{{ char }}</span>
          <span class="input" v-else>{{ char }}</span>
          <span class="output-finish" v-if="item.output[subIndex] && item.output[subIndex][subCharIndex] && finish(item.output[subIndex])">{{ item.output[subIndex][subCharIndex] }}</span>
          <span class="output" v-else-if="item.output[subIndex] && item.output[subIndex][subCharIndex]">{{ item.output[subIndex][subCharIndex] }}</span>
          <span class="output-error" v-else>{{ '×' }}</span>
        </div>
      </div>
    </div>
    <nut-input
        v-model="gameInput"
        clearable
        @keyup.enter="onGameInput"
        type="text"/>
  </div>

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
import {GameUserHistoryReq, GameUserHistoryRes, Path, SubmitReq, SubmitRes} from "../utils/constant.ts";

type History = Array<
    {
      input: Array<string>;
      output: Array<string>;
    }
>;

import reconnect from '../component/reconnect.vue';
import {Setting, Loading1} from '@nutui/icons-vue';
import {useI18n} from 'vue-i18n';
import {onBeforeUnmount, onMounted, ref, nextTick} from 'vue';
import {client, ClientStatus, Request} from "../api/ws.ts";
import {showDialog} from "@nutui/nutui";

const record = ref<History>([]);
const replaceChar = '•';
const gameInput = ref('');
const overlayVisible = ref(false);
const {t} = useI18n();
let refreshGame: RefreshGameType;
let lastGameUserId: number = 0;
import {useRoute, useRouter} from 'vue-router';

const route = useRoute();
const router = useRouter();

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
});

onBeforeUnmount(() => {
  bus().off(EventName.RefreshGame);
  bus().off(EventName.WsStatus);
});

const refresh = async (refreshGame: RefreshGameType) => {
  overlayVisible.value = true;
  const data: GameUserHistoryReq = {
    gameId: refreshGame.id,
    time: refreshGame.time,
  };
  lastGameUserId = 0;
  const req = new Request({path: Path.gameUserHistory, data: data});
  const res0 = await client.node!.send(req)
  const res = GameUserHistoryRes.from(res0.data);
  record.value.splice(0, record.value.length);
  for (const element of res.list) {
    record.value.push({
      input: element.input,
      output: element.output,
    });
    lastGameUserId = element.id;
  }
  await router.replace({
    query: {
      id: refreshGame.id,
      time: refreshGame.time,
    },
  });
  overlayVisible.value = false;
}

const onCancel = () => {
  console.log('event cancel')
}
const onOk = () => {
  router.push('/home');
}

const onGameInput = async () => {
  overlayVisible.value = true;
  const req = new SubmitReq();
  req.gameId = refreshGame.id;
  req.prevId = lastGameUserId;
  req.input = gameInput.value;
  const res0 = await client.node!.send(new Request({path: Path.submit, data: req}));
  if (res0.error) {
    showDialog({
      title: t('tips'),
      content: t(res0.error),
      noCancelBtn: true,
      okText: t('confirm'),
      onCancel,
      onOk
    })
    return;
  }
  const res = res0.data as SubmitRes;
  lastGameUserId = res.id;
  record.value.push({
    input: res.input,
    output: res.output,
  });
  await nextTick(() => {
    window.scrollTo(0, document.body.scrollHeight);
  });
  gameInput.value = '';
  overlayVisible.value = false;
};

const finish = (word: string) => {
  for (const element of word) {
    if (element === replaceChar) {
      return false;
    }
  }
  return true;
};
const onClickBack = () => history.back();
</script>
<style>
:root {
  --history-background-color: wheat;
  --history-finish-color: blue;
  --history-normal-color: black;
  --history-input-right-color: green;
}

.history-item {
  border: 1px solid var(--history-background-color);
  background-color: var(--history-background-color);
  padding: 10px;
  word-wrap: break-word;
  white-space: normal;
  margin-bottom: 10px;
}

.history-word {
  margin-bottom: 10px;
  padding: 10px;
  background-color: var(--history-background-color);
  display: inline-flex;
  justify-content: space-between;
  align-items: center;
}

.history-char {
  display: inline-grid;
  text-align: center;
}

.output {
  width: 20px;
  font-weight: bold;
  text-align: center;
  border-bottom: 1px solid #555;
  color: var(--history-normal-color);
}

.output-finish {
  color: var(--history-finish-color);
  font-weight: bold;
  text-align: center;
  border-bottom: 1px solid var(--history-finish-color);
}

.output-error {
  color: red;
  font-weight: bold;
  text-align: center;
  border-bottom: 1px solid red;
}

.input {
  width: 20px;
  text-align: center;
  color: #a1a1a1;
}

.input-error {
  width: 20px;
  color: red;
  text-align: center;
}

.input-hit {
  width: 20px;
  color: var(--history-input-right-color);
  text-align: center;
}

</style>