<template>
  <div v-if="editorEnable">
    <nut-textarea v-model="editorContent" :rows="3" autosize/>
    <nut-button shape="square" type="primary" block @click="submit">
      {{ t('refreshAfterModify') }}
    </nut-button>
  </div>
  <nut-cell>
    <div class="player-order">
      <template v-for="(userId, index) in userIds" :key="userId">
        <span
            class="player-tag"
            :class="{
            'is-me': userId === currentUserId,
            'is-active': isActive(index)
        }"
            :style="playerStyle(userId)"
        >
          {{ index + 1 }}. {{ userIdToUserName[userId] }}
        </span>

        <span
            v-if="index < userIds.length - 1"
            class="separator"
        >
          ➡️
        </span>
      </template>
    </div>
  </nut-cell>
</template>

<script setup lang="ts">
import {GameStepEnum} from '../../../../vo/WordSlicerStatus';
import {inject, Ref} from "vue";
import {useI18n} from "vue-i18n";
import {client, Request} from "../../../../api/ws.ts";
import {Path} from "../../../../utils/constant.ts";

const {t} = useI18n();

interface Props {
  userIds: number[]
  userIdToUserName: Record<number, string>
  currentUserId: number
  currUserIndex: number
  gameStep: GameStepEnum
  getUserColor: (userId: number) => string
}

const props = defineProps<Props>()

const editorContent = inject<Ref<string>>('editorContent')!
const editorEnable = inject<Ref<boolean>>('editorEnable')!

const overlayVisible = inject<Ref<boolean>>('overlayVisible')!;
const tipDialogVisible = inject<Ref<boolean>>('tipDialogVisible')!;
const tipDialogContent = inject<Ref<string>>('tipDialogContent')!;
const isActive = (index: number) =>
    index === props.currUserIndex &&
    props.gameStep === GameStepEnum.started

const submit = async () => {
  let res = null;
  try {
    overlayVisible.value = true;
    res = await client.send(new Request({
      path: Path.wordSlicerEdit,
      data: editorContent.value
    }));
  } catch (e) {
    tipDialogVisible.value = true;
    tipDialogContent.value = String(e);
  } finally {
    if (res != null && res.error) {
      tipDialogVisible.value = true;
      tipDialogContent.value = t(res!.error);
    }
    overlayVisible.value = false;
  }
}
const playerStyle = (userId: number) => {
  const color = props.getUserColor(userId)
  return {
    borderLeft: color ? `8px solid ${color}` : 'none',
    paddingLeft: color ? '6px' : '8px'
  }
}
</script>

<style scoped>
.player-order {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 8px;
  font-size: 14px;
}

.separator {
  color: #ccc;
  font-size: 12px;
}

.player-tag {
  padding: 2px 8px;
  background: #f0f0f0;
  border-radius: 4px;
  transition: all 0.2s;
  border: 1px solid transparent;
}

.player-tag.is-me {
  color: black;
  font-weight: bold;
}

.player-tag.is-active {
  border-right-width: 3px;
  border-right-color: #fa2c19;
}


.nut-theme-dark .player-tag.is-me {
  color: white;
}

.nut-theme-dark .player-tag {
  color: #e5e5e5;
  background: #333;
  border-top-color: #444;
  border-bottom-color: #444;
}
</style>