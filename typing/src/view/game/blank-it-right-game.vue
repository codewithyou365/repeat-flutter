<template>
  <div class='container'>
    <nut-cell v-html='tips.replace(/\n/g, "<br>")'></nut-cell>
    <Typing
        :content="content"
        :disabled="typingDisabled"
        :ignore-case="ignoreCase"
        :change-to-right-case-when-ignore-case="false"
        :ignore-punctuation="ignorePunctuation && editorUserId == store.getters.currentUserId"
        :ignore-content-indexes="ignoreContentIndexes"
        :click-fill-char-when-disabled='clickFillCharWhenDisabled'
        ref="typingRef"
    />
    <div v-if="editorUserId == store.getters.currentUserId && step == StepName.blanking" class="container">
      <nut-row :gutter="10">
        <nut-col :span="12">
          <nut-button block type="info" @click="onBlank">{{ t('confirm') }}</nut-button>
        </nut-col>
        <nut-col :span="12">
          <nut-button block type="info" @click="onBlankReset">{{ t('reset') }}</nut-button>
        </nut-col>
      </nut-row>
    </div>
    <div v-else-if="editorUserId != store.getters.currentUserId && step == StepName.blanked" class="container">
      <nut-row :gutter="10">
        <nut-col :span="24">
          <nut-button block type="info" @click="onSubmit">{{ t('confirm') }}</nut-button>
        </nut-col>
      </nut-row>
    </div>
    <div v-else-if="editorUserId != store.getters.currentUserId && step == StepName.finished" class="container">
      <nut-cell>{{ t('score') + ': +' + score }}</nut-cell>
      <nut-row :gutter="10">
        <nut-col :span="24">
          <nut-button block type="info" @click="onSwitchView">{{
              showAnswer ? t('viewSubmit') : t('viewAnswer')
            }}
          </nut-button>
        </nut-col>
      </nut-row>
    </div>

  </div>
</template>

<script setup lang="ts">
import {onMounted, ref, onBeforeUnmount, inject, Ref, nextTick, computed} from 'vue';
import {bus, EventName, RefreshGameType} from '../../api/bus.ts';
import {client, Request} from '../../api/ws.ts';
import {Path} from '../../utils/constant.ts';
import {KvList} from '../../vo/KvList.ts';
import {BlankItRightBlankReq} from '../../vo/BlankItRightBlankReq.ts';
import {BlankItRightSubmitReq, BlankItRightSubmitRes} from "../../vo/BlankItRightSubmit.ts";
import {useRoute, useRouter} from 'vue-router';
import Typing from '../../component/typing.vue';
import {toNumber} from "../../utils/convert.ts";
import {useStore} from "vuex";
import {useI18n} from "vue-i18n";

const {t} = useI18n();
const store = useStore();
const route = useRoute();
const router = useRouter();
const typingDisabled = ref(false);
const ignoreCase = ref(false);
const ignorePunctuation = ref(false);
const editorUserId = ref(0);
const score = ref(0);
const content = ref('');
const answer = ref('');
const blankChar = '•';
const clickFillCharWhenDisabled = ref(blankChar);
let submit = '';
const ignoreContentIndexes = ref<number[]>([]);
const typingRef = ref<InstanceType<typeof Typing>>();

enum StepName {
  none = 0,
  blanking = 1,
  blanked = 2,
  finished = 3,
}

const step = ref<StepName>(StepName.blanking);
const tips = computed(() => {
  if (editorUserId.value == store.getters.currentUserId && step.value === StepName.blanking) {
    return t('editorBlankingTip')
  } else if (editorUserId.value == store.getters.currentUserId && step.value === StepName.blanked) {
    return t('editorBlankedTip')
  } else if (editorUserId.value != store.getters.currentUserId && step.value === StepName.blanking) {
    return t('blankingTip')
  } else if (editorUserId.value != store.getters.currentUserId && step.value === StepName.blanked) {
    return t('blankedTip')
  } else if (editorUserId.value != store.getters.currentUserId && step.value === StepName.finished) {
    return t('answer') + answer.value
  }
  return '??';

});
const overlayVisible = inject<Ref<boolean>>('overlayVisible')!
const tipDialogVisible = inject<Ref<boolean>>('tipDialogVisible')!
const tipDialogContent = inject<Ref<string>>('tipDialogContent')!
let refreshGame: RefreshGameType;

const getGameSettings = async () => {
  const req = new Request({path: Path.blankItRightSettings});
  const res0 = await client.node!.send(req);
  const res = KvList.fromJson(res0.data);
  const settings = res.convertMap();

  editorUserId.value = toNumber(settings.get('blockItRightGameForEditorUserId'));
  ignorePunctuation.value = settings.get('blockItRightGameForIgnorePunctuation') === 'true';
  ignoreCase.value = settings.get('blockItRightGameForIgnoreCase') === 'true';
};

const refresh = async (refreshGame: RefreshGameType) => {
  try {
    overlayVisible.value = true;
    await getGameSettings();
    const req = new Request({path: Path.blankItRightContent, data: refreshGame.verseId});
    const res = await client.node!.send(req);
    if (res.error) {
      tipDialogVisible.value = true;
      tipDialogContent.value = t(res.error);
      return;
    }
    step.value = parseStep(res.data.step);
    if (editorUserId.value == store.getters.currentUserId) {
      const contentJson = JSON.parse(res.data.content);
      if (contentJson) {
        content.value = contentJson.a ?? '';
        await nextTick(() => {
          if (
              Array.isArray(contentJson.blankItRightList) &&
              contentJson.blankItRightList.length > 0
          ) {
            const source = content.value;
            const blankSource = contentJson.blankItRightList[0];
            const blankContent = [...blankSource];
            for (let i = 0; i < source.length; i++) {
              if (i >= blankContent.length) {
                blankContent.push(source[i]);
              } else if (ignorePunctuation.value && /\p{P}/u.test(source[i])) {
                blankContent[i] = source[i];
              } else if (blankContent[i] !== source[i]) {
                blankContent[i] = blankChar;
              }
            }
            typingRef.value?.initUserInput(blankContent.join(''));
          } else {
            typingRef.value?.initUserInput(content.value);
          }
        });
      }
    } else {
      ignoreContentIndexes.value = [];
      const currContent = res.data.content ?? '';
      for (let i = 0; i < currContent.length; i++) {
        if (currContent[i] !== '•') {
          ignoreContentIndexes.value.push(i);
        }
      }
      if (step.value === StepName.finished) {
        content.value = res.data.answer ?? '';
        submit = res.data.submit;
        answer.value = res.data.answer ?? '';
        score.value = res.data.score ?? 0;
        await nextTick(() => {
          typingRef.value?.initUserInput(res.data.submit);
        });
      } else {
        content.value = currContent;
      }
    }

    if (editorUserId.value == store.getters.currentUserId && step.value === StepName.blanking) {
      typingDisabled.value = true;
      clickFillCharWhenDisabled.value = '•';
    } else if (editorUserId.value != store.getters.currentUserId && step.value === StepName.blanked) {
      typingDisabled.value = false;
      clickFillCharWhenDisabled.value = '';
    } else {
      typingDisabled.value = true;
      clickFillCharWhenDisabled.value = '';
    }
    await router.replace({
      query: {
        verseId: refreshGame.verseId,
      },
    });
  } catch (error) {
    console.error('Failed to refresh game:', error);
  } finally {
    overlayVisible.value = false;
  }
};

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

const onBlankReset = async () => {
  typingRef.value?.initUserInput(content.value);
}
const onBlank = async () => {
  overlayVisible.value = true;
  const req = new BlankItRightBlankReq();
  req.verseId = refreshGame.verseId;
  req.content = typingRef.value?.getUserInput() ?? '';
  const res0 = await client.node!.send(new Request({path: Path.blankItRightBlank, data: req}));
  if (res0.error) {
    tipDialogVisible.value = true;
    tipDialogContent.value = t(res0.error);
    return;
  }
  overlayVisible.value = false;
}

const showAnswer = ref(false);
const onSwitchView = async () => {
  if (showAnswer.value) {
    typingRef.value?.initUserInput(submit);
  } else {
    typingRef.value?.initUserInput(answer.value);
  }
  showAnswer.value = !showAnswer.value;
}

const onSubmit = async () => {
  overlayVisible.value = true;
  const req = new BlankItRightSubmitReq();
  req.verseId = refreshGame.verseId;
  req.content = typingRef.value?.getUserInput() ?? '';
  const res = await client.node!.send(new Request({path: Path.blankItRightSubmit, data: req}));
  if (res.error) {
    tipDialogVisible.value = true;
    tipDialogContent.value = t(res.error);
    return;
  }
  const blankItRightSubmitRes = BlankItRightSubmitRes.fromJson(res.data);
  content.value = blankItRightSubmitRes.answer;
  answer.value = blankItRightSubmitRes.answer;
  submit = req.content;
  score.value = blankItRightSubmitRes.score;
  step.value = StepName.finished;
  await nextTick(() => {
    typingRef.value?.initUserInput(submit);
  });
  overlayVisible.value = false;
}
const parseStep = (step: string): StepName => {
  switch (step) {
    case 'blanking':
      return StepName.blanking;
    case 'blanked':
      return StepName.blanked;
    case 'finished':
      return StepName.finished;
    default:
      return StepName.none;
  }
};
</script>
<style>
.container {
  margin: 12px;
}
</style>