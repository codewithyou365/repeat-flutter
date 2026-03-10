<template>
  <div class="type-game-container">
    <div class="typing-content">
      <Typing
          :content="content"
          :disabled="false"
          :ignore-case="ignoreCase"
          :change-to-right-case-when-ignore-case="true"
          :ignore-punctuation="ignorePunctuation"
          :ignore-content-indexes="[]"
      />
    </div>

    <div class="actions">
      <nut-button shape="square" type="info" @click="tap('tapLeft')">
        {{ labels.left }}
      </nut-button>
      <nut-button shape="square" type="info" @click="tap('tapMiddle')">
        {{ labels.middle }}
      </nut-button>
      <nut-button shape="square" type="info" @click="tap('tapRight')">
        {{ labels.right }}
      </nut-button>
    </div>
  </div>
</template>
<script setup lang="ts">
import {onMounted, ref, onBeforeUnmount, inject, Ref, reactive} from 'vue';
import {bus, EventName} from '../../api/bus.ts';
import {client, Request} from '../../api/ws.ts';
import {Path} from '../../utils/constant.ts';
import Typing from '../../component/typing.vue';

const ignoreCase = ref(false);
const ignorePunctuation = ref(false);
const content = ref('');
const labels = reactive({
  left: '',
  middle: '',
  right: ''
});

const overlayVisible = inject<Ref<boolean>>('overlayVisible')!;

const getLabel = async () => {
  const req = new Request({
    path: Path.game,
    headers: {'jsMethod': 'TypeGame.label'},
  });
  const res = await client.node!.send(req);

  labels.left = res.data.left;
  labels.middle = res.data.middle;
  labels.right = res.data.right;
};

const getConfig = async () => {
  const req = new Request({
    path: Path.game,
    headers: {'jsMethod': 'TypeGame.getConfig'},
  });
  const res0 = await client.node!.send(req);
  const res = res0.data;
  ignorePunctuation.value = res['ignorePunctuation'];
  ignoreCase.value = res['ignoreCase'];
};
const tap = async (event: String) => {
  const req = new Request({
    path: Path.game,
    headers: {'jsMethod': 'TypeGame.tap'},
    data: event,
  });
  await client.node!.send(req);
  await refresh();
};
const refresh = async () => {
  try {
    overlayVisible.value = true;
    const req = new Request({
      path: Path.game,
      headers: {'jsMethod': 'TypeGame.answer'},
    });
    const res = await client.node!.send(req);
    content.value = res.data;

    await getLabel();
  } catch (error) {
    console.error('Failed to refresh game:', error);
  } finally {
    overlayVisible.value = false;
  }
};

onMounted(async () => {
  await getConfig();
  await refresh();
  bus().on(EventName.RefreshGame, () => {
    refresh();
  });
});

onBeforeUnmount(() => {
  bus().off(EventName.RefreshGame);
});
</script>
<style scoped>
.type-game-container {
  display: flex;
  flex-direction: column;
  flex: 1; /* 继承父级的高度占满 */
}

.typing-content {
  flex: 1; /* 自动撑开，把 actions 挤到最下面 */
  padding: 10px;
}

.actions {
  display: flex;
  justify-content: space-around;
  padding: 10px 0;
  padding-bottom: env(safe-area-inset-bottom); /* 适配手机底部安全区 */
  flex-shrink: 0; /* 确保按钮高度不被挤压 */
}

.actions .nut-button {
  width: 32%; /* 留一点空隙更美观 */
}
</style>