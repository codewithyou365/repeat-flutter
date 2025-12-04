<template>
  <div class='container'>
    <nut-cell>{{ tips }}</nut-cell>
    <Typing
        :content="content"
        :disabled="typingDisabled"
        :ignore-case="ignoreCase"
        :ignore-punctuation="ignorePunctuation"
        :ignore-content-indexes=[]
        ref="typingRef"
    />
    <div v-if="step === StepName.blanking" class="container">
      <nut-row :gutter="10">
        <nut-col :span="12">
          <nut-button block type="info" @click="onBlank">{{ t('confirm') }}</nut-button>
        </nut-col>
        <nut-col :span="12">
          <nut-button block type="info" @click="onBlankReset">{{ t('reset') }}</nut-button>
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
const content = ref('');
const typingRef = ref<InstanceType<typeof Typing>>();

enum StepName {
  none = 0,
  blanking = 1,
  blanked = 2,
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
  }
  return xx;

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
  ignorePunctuation.value = settings.get('typeGameForIgnorePunctuation') === 'true';
  ignoreCase.value = settings.get('typeGameForIgnoreCase') === 'true';
};

const refresh = async (refreshGame: RefreshGameType) => {
  try {
    overlayVisible.value = true;
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
          if (contentJson.blankItRightList && contentJson.blankItRightList.length > 0) {
            typingRef.value?.initUserInput(contentJson.blankItRightList[0]);
          } else {
            typingRef.value?.initUserInput(content.value);
          }
        });
      }
    } else {
      content.value = res.data.content ?? '';
    }
    if (editorUserId.value == store.getters.currentUserId && step.value === StepName.blanking) {
      typingDisabled.value = false;
    } else if (editorUserId.value == store.getters.currentUserId && step.value === StepName.blanked) {
      typingDisabled.value = true;
    } else if (editorUserId.value != store.getters.currentUserId && step.value === StepName.blanking) {
      typingDisabled.value = true;
    } else if (editorUserId.value != store.getters.currentUserId && step.value === StepName.blanked) {
      typingDisabled.value = false;
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
  await getGameSettings();
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
  req.content = typingRef.value?.getUserInput();
  const res0 = await client.node!.send(new Request({path: Path.blankItRightBlank, data: req}));
  if (res0.error) {
    tipDialogVisible.value = true;
    tipDialogContent.value = t(res0.error);
    return;
  }
  overlayVisible.value = false;
}

const parseStep = (step: string): StepName => {
  switch (step) {
    case 'blanking':
      return StepName.blanking;
    case 'blanked':
      return StepName.blanked;
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