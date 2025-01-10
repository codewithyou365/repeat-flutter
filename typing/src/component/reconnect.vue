<template>
  <nut-divider v-if="!store.getters.currentWsConnected" :style="dividerStyle">
    {{ t('reconnect') }}
    <div :style="innerStyle"></div>
  </nut-divider>
  <div v-else :style="normalStyle"></div>
</template>

<script setup lang="ts">
import {computed, CSSProperties} from 'vue';
import {useI18n} from 'vue-i18n';
import {useStore} from 'vuex';

const store = useStore();
const {t} = useI18n();
const height = '18px';

const normalStyle = computed<CSSProperties>(() => ({
  height: height,
}));

const dividerStyle = computed<CSSProperties>(() => ({
  margin: '0',
  color: '#00488d',
  height: height,
  borderColor: 'transparent',
  backgroundImage:
      'var(--nut-progress-inner-background-color, linear-gradient(135deg, var(--nut-primary-color, #fa2c19) 0%, var(--nut-primary-color-end, #fa6419) 100%))',
}));

// Computed styles for the animated div
const innerStyle = computed<CSSProperties>(() => ({
  height: height,
  animation: '2s ease-in-out infinite progressActive',
  position: 'absolute',
}));
</script>