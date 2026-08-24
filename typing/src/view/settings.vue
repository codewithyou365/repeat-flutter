<template>
  <nut-navbar :title="t('settings')" left-show @click-back="onClickBack"></nut-navbar>
  <div style="margin: 8px">
    <nut-cell title="Language">
      <template #link>
        <select class="lang-select" v-model="language" @change="updateLanguage(language)">
          <option v-for="l in LOCALES" :key="l.code" :value="l.code">{{ l.name }}</option>
        </select>
      </template>
    </nut-cell>
    <nut-cell :title="t('dartMode')">
      <template #link>
        <nut-switch v-model="theme" @change="changeTheme"/>
      </template>
    </nut-cell>
    <nut-cell :title="t('keyboardType')">
      <template #link>
        <nut-radio-group v-model="keyboardType" direction="horizontal" @change="updateKeyboardType">
          <nut-radio label="text">{{ t('keyboardTypeIme') }}</nut-radio>
          <nut-radio label="password">{{ t('keyboardTypeAscii') }}</nut-radio>
        </nut-radio-group>
      </template>
    </nut-cell>
  </div>
</template>

<script setup>
import {ref} from 'vue';
import {useI18n} from 'vue-i18n';
import {useStore} from 'vuex';
import {LOCALES} from '../i18n';

const store = useStore();
const {t, locale} = useI18n();

const theme = ref(store.getters.currentTheme === 'dark');
const enableVim = ref(store.getters.currentEnableVim);
const language = ref(store.getters.currentLanguage);
const keyboardType = ref(store.getters.currentKeyboardType);

const changeTheme = (value) => {
  theme.value = value;
  const newTheme = value ? 'dark' : 'light';
  store.dispatch('updateTheme', newTheme);
};

const changeEnableVim = (value) => {
  enableVim.value = value;
  store.dispatch('updateEnableVim', value);
};

const updateKeyboardType = (value) => {
  keyboardType.value = value;
  store.dispatch('updateKeyboardType', value);
};

const updateLanguage = (value) => {
  language.value = value;
  locale.value = value;
  store.dispatch('updateLanguage', value);
};
const onClickBack = () => history.back();
</script>

<style scoped>
.lang-select {
  max-width: 60vw;
  padding: 4px 8px;
  color: inherit;
  background: transparent;
  border: 1px solid currentColor;
  border-radius: 4px;
}

/* 展开的选项由系统绘制，不继承 transparent，得自己给底色 */
.lang-select option {
  color: initial;
  background: initial;
}
</style>
