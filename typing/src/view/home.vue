<template>
  <nut-navbar :title="t('home')">
    <template #right>
      <router-link to="/settings">
        <Setting width="16px" to="/settings"></Setting>
      </router-link>
    </template>
  </nut-navbar>
  <reconnect/>
  <div style="margin: 8px">
    <nut-grid :column-num="2" square>
      <nut-grid-item text="entry game" clickable @click="onA">
        <PlayStart/>
      </nut-grid-item>
      <nut-grid-item text="history" clickable @click="onB">
        <Date/>
      </nut-grid-item>
    </nut-grid>
  </div>
</template>

<script setup lang="ts">
import reconnect from '../component/reconnect.vue';
import {Setting, PlayStart, Date} from "@nutui/icons-vue";
import {useI18n} from 'vue-i18n';
import {onMounted} from "vue";

const {t} = useI18n();

onMounted(() => {

});

const onA = () => {
}
const onB = () => {
}
</script>