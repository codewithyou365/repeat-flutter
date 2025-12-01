<!-- Parent Component, e.g., TypingGamePage.vue -->
<template>
  <div>
    <Typing
        :content="content"
        :ignore-case="ignoreCase"
        :ignore-punctuation="ignorePunctuation"
    />
  </div>
</template>

<script setup lang="ts">
import {onMounted, ref, onBeforeUnmount, inject, Ref} from 'vue';
import {bus, EventName, RefreshGameType} from '../../api/bus.ts';
import {client, Request} from '../../api/ws.ts';
import {GetVerseContentReq, GetVerseContentRes, Path} from '../../utils/constant.ts';
import {GetGameSettingsRes} from '../../vo/GetGameSettingsRes.ts';
import {useRoute, useRouter} from 'vue-router';
import Typing from '../../component/typing.vue';

const route = useRoute();
const router = useRouter();
const ignoreCase = ref(false);
const ignorePunctuation = ref(false);
const content = ref('');
const overlayVisible = inject<Ref<boolean>>('overlayVisible')!
let refreshGame: RefreshGameType;

const getGameSettings = async () => {
  const req = new Request({path: Path.getGameSettings});
  const res0 = await client.node!.send(req);
  const res = GetGameSettingsRes.fromJson(res0.data);
  const settings = res.convertMap();

  ignorePunctuation.value = settings.get('typeGameForIgnorePunctuation') === 'true';
  ignoreCase.value = settings.get('typeGameForIgnoreCase') === 'true';
};

const refresh = async (refreshGame: RefreshGameType) => {
  try {
    overlayVisible.value = true;
    const data: GetVerseContentReq = {
      verseId: refreshGame.verseId,
    };

    const req = new Request({path: Path.getVerseContent, data});
    const res0 = await client.node!.send(req);
    const res = GetVerseContentRes.from(res0.data);
    const contentJson = JSON.parse(res.content);
    content.value = contentJson?.a ?? '';
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