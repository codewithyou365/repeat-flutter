<template>
  <div>
    <Typing
        :content="content"
        :ignore-case="ignoreCase"
        :ignore-punctuation="ignorePunctuation"
        :ignore-content-indexes=[]
    />
  </div>
</template>

<script setup lang="ts">
import {onMounted, ref, onBeforeUnmount, inject, Ref} from 'vue';
import {bus, EventName, RefreshGameType} from '../../api/bus.ts';
import {client, Request} from '../../api/ws.ts';
import {Path} from '../../utils/constant.ts';
import {KvList} from '../../vo/KvList.ts';
import {useRoute, useRouter} from 'vue-router';
import Typing from '../../component/typing.vue';
import {toNumber} from "../../utils/convert.ts";
import {useStore} from "vuex";
import {useI18n} from "vue-i18n";

const {t} = useI18n();
const store = useStore();
const route = useRoute();
const router = useRouter();
const ignoreCase = ref(false);
const ignorePunctuation = ref(false);
const editorUserId = ref(0);
const content = ref('');
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
    if (editorUserId.value == store.getters.currentUserId) {
      const contentJson = JSON.parse(res.data);
      content.value = contentJson?.a ?? '';
    } else {
      content.value = res.data ?? '';
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
</script>