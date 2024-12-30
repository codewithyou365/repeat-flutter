<template>
  <nut-config-provider :theme="store.getters.currentTheme">
    <router-view/>
  </nut-config-provider>
</template>

<script setup>
import {useStore} from 'vuex';
import {onMounted} from 'vue';
import {useI18n} from "vue-i18n";

const {locale} = useI18n();
const store = useStore();
onMounted(() => {
  store.dispatch('updateTheme', store.getters.currentTheme);
  locale.value = store.getters.currentLanguage;
});
</script>