<template>
  <nut-navbar :title="t('settings')" left-show @click-back="onClickBack"></nut-navbar>
  <div style="margin: 8px">
    <nut-cell title="Language">
      <nut-radio-group v-model="language" direction="horizontal" @change="updateLanguage">
        <nut-radio label="en">English</nut-radio>
        <nut-radio label="zh">中文</nut-radio>
      </nut-radio-group>
    </nut-cell>
    <nut-cell :title="t('dartMode')">
      <template #link>
        <nut-switch v-model="theme" @change="changeTheme"/>
      </template>
    </nut-cell>
  </div>
</template>

<script setup>
import {ref} from 'vue';
import {useI18n} from 'vue-i18n';
import {useStore} from 'vuex';

const store = useStore();
const {t, locale} = useI18n();

const theme = ref(store.getters.currentTheme === 'dark');
const language = ref(store.getters.currentLanguage);

const changeTheme = (value) => {
  theme.value = value;
  const newTheme = value ? 'dark' : 'light';
  store.dispatch('updateTheme', newTheme);
};

const updateLanguage = (value) => {
  language.value = value;
  locale.value = value;
  store.dispatch('updateLanguage', value);
};
const onClickBack = () => history.back();
</script>