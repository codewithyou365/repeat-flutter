<template>
  <div class="container">
    <div v-for="(item, index) in record" :key="index" class="history-item">
      <div v-for="(element, subIndex) in item.input" :key="subIndex" class="history-word">
        <div v-for="(char, subCharIndex) in element" :key="subCharIndex" class="history-char">
          <span class="input-hit"
                v-if="char!==replaceChar && item.output[subIndex] && item.output[subIndex][subCharIndex] && item.output[subIndex][subCharIndex]===char">{{
              char
            }}</span>
          <span class="input-error" v-else-if="char!==replaceChar">{{ char }}</span>
          <span class="input" v-else>{{ char }}</span>
          <span class="output-finish"
                v-if="item.output[subIndex] && item.output[subIndex][subCharIndex] && finish(item.output[subIndex])">{{
              item.output[subIndex][subCharIndex]
            }}</span>
          <span class="output" v-else-if="item.output[subIndex] && item.output[subIndex][subCharIndex]">{{
              item.output[subIndex][subCharIndex]
            }}</span>
          <span class="output-error" v-else>{{ '×' }}</span>
        </div>
      </div>
    </div>
  </div>
  <dev v-if="inputEnable">
    <editor type="txt" :save="onGameInput" ref="editorComponent"/>
    <div class="container">
      <nut-button size="large" type="info" @click="onGameInput">{{ t('confirm') }}</nut-button>
    </div>
  </dev>

</template>

<script setup lang="ts">
import {bus, EventName, RefreshGameType} from "../../api/bus.ts";
import {GameUserHistoryReq, GameUserHistoryRes, MatchType, Path, SubmitReq, SubmitRes} from "../../utils/constant.ts";
import editor from '../../component/editor.vue';
import {useI18n} from 'vue-i18n';
import {onBeforeUnmount, onMounted, ref, nextTick, inject, computed, Ref} from 'vue';
import {client, Request} from "../../api/ws.ts";

type History = Array<
    {
      input: Array<string>;
      output: Array<string>;
    }
>;

const editorComponent = ref<InstanceType<typeof editor> | null>(null);
const record = ref<History>([]);
const replaceChar = '•';
const overlayVisible = inject<Ref<boolean>>('overlayVisible')!
const tipDialogVisible = inject<Ref<boolean>>('tipDialogVisible')!
const tipDialogContent = inject<Ref<string>>('tipDialogContent')!
const {t} = useI18n();
let refreshGame: RefreshGameType;
let lastGameUserId: number = 0;
const lastOutput = ref<Array<string>>([]);
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
});

onBeforeUnmount(() => {
  bus().off(EventName.RefreshGame);
});

const refresh = async (refreshGame: RefreshGameType) => {
  try {
    overlayVisible.value = true;
    const data: GameUserHistoryReq = {
      gameId: refreshGame.id,
      time: refreshGame.time,
    };

    const req = new Request({path: Path.gameUserHistory, data});
    const res0 = await client.node!.send(req);
    const res = GameUserHistoryRes.from(res0.data);

    record.value = res.list.map((element) => ({
      input: element.input,
      output: element.output,
    }));

    lastGameUserId = res.list.length ? res.list[res.list.length - 1].id : 0;
    lastOutput.value = res.list.length ? res.list[res.list.length - 1].output : [];

    await router.replace({
      query: {
        id: refreshGame.id,
        time: refreshGame.time,
      },
    });
    if (editorComponent.value && res.tips.length > 0) {
      const editorView = editorComponent.value.getEditorView();
      editorView?.dispatch({
        changes: {from: 0, to: editorView?.state.doc.length, insert: res.tips.join(" ")},
      });
    }
  } catch (error) {
    console.error('Failed to refresh game:', error);
  } finally {
    overlayVisible.value = false;
  }
}

const onGameInput = async () => {
  let gameInput = '';
  let editorView;
  if (editorComponent.value) {
    editorView = editorComponent.value.getEditorView();
    if (editorView) {
      gameInput = editorView.state.doc.toString();
    }
  }
  overlayVisible.value = true;
  const req = new SubmitReq();
  req.gameId = refreshGame.id;
  req.prevId = lastGameUserId;
  req.input = gameInput;
  const res0 = await client.node!.send(new Request({path: Path.submit, data: req}));
  if (res0.error) {
    tipDialogVisible.value = true;
    tipDialogContent.value = t(res0.error);
    return;
  }
  const res = res0.data as SubmitRes;
  lastGameUserId = res.id;
  record.value.push({
    input: res.input,
    output: res.output,
  });
  lastOutput.value = res.output;
  await nextTick(() => {
    window.scrollTo(0, document.body.scrollHeight);
  });
  let insert: string;
  if (res.matchType === MatchType.all) {
    insert = res.output.join(" ");
  } else {
    insert = "";
  }
  editorView?.dispatch({
    changes: {from: 0, to: editorView?.state.doc.length, insert: insert},
  });

  overlayVisible.value = false;
};
const inputEnable = computed(() => {
  const outputStr = lastOutput.value.join('');
  if (outputStr.length === 0) {
    return true;
  }
  return outputStr.indexOf(replaceChar) !== -1;
});
const finish = (word: string) => {
  for (const element of word) {
    if (element === replaceChar) {
      return false;
    }
  }
  return true;
};
</script>
<style>
.container {
  margin: 8px;
}

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