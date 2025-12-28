<template>
  <nut-navbar :title="t('login')">
    <template #right>
      <router-link to="/settings">
        <Setting width="16px"></Setting>
      </router-link>
    </template>
  </nut-navbar>
  <div style="margin: 8px">
    <nut-form ref="formRef" :model-value="form" :rules="rules">
      <nut-form-item :label="t('userName')" prop="userName">
        <nut-input
            v-model="form.userName"
            clearable
            @blur="customBlurValidate('userName')"
            type="text"/>
      </nut-form-item>
      <nut-form-item :label="t('password')" prop="password">
        <nut-input
            v-model="form.password"
            clearable
            type="password"/>
      </nut-form-item>
      <nut-form-item v-if="showNewPasswordView" :label="t('newPassword')" prop="newPassword">
        <nut-input
            v-model="form.newPassword"
            clearable
            type="password"/>
      </nut-form-item>
      <nut-form-item v-if="showGamePasswordView" :label="t('gamePassword')" prop="gamePassword">
        <nut-input
            v-model="form.gamePassword"
            clearable
            type="password"/>
      </nut-form-item>
    </nut-form>

    <nut-button
        type="primary"
        block
        :loading="isLoading"
        @click="handleLogin">
      {{ t('login') }}
    </nut-button>
  </div>
  <nut-dialog
      v-model:visible="dialogVisible"
      :title="t('tips')"
      :content="dialogContent"
      :okText="t('confirm')"
      :no-cancel-btn="true"
      :cancelText="t('cancel')"
      :onOk="onOk"
      :onCancel="onCancel">
  </nut-dialog>
</template>

<script setup>
import {Setting} from '@nutui/icons-vue'
import {ref, reactive} from 'vue';
import {useI18n} from 'vue-i18n';
import {useRouter} from 'vue-router';
import http from '../api/http';
import {showDialog} from '@nutui/nutui';
import {useStore} from 'vuex';
import {Path} from "../utils/constant";

const store = useStore();

const router = useRouter();
const {t, locale} = useI18n();

const form = reactive({
  userName: '',
  password: '',
  newPassword: '',
  gamePassword: '',
});

const showNewPasswordView = ref(false);
const showGamePasswordView = ref(false);
const dialogVisible = ref(false);
const dialogContent = ref('');

const rules = ref({
  userName: [{required: true, message: t('inputUserName')}, {regex: /^[A-Z]{2,5}$/, message: t('inputUserNameTip')}],
  password: [{required: true, message: t('inputPassword')}, {regex: /^.{6,30}$/, message: t('inputPasswordTip')}],
  newPassword: [{required: true, message: t('inputPassword')}, {regex: /^.{6,30}$/, message: t('inputPasswordTip')}],
  gamePassword: [{required: true, message: t('inputPassword')}, {regex: /^.{6,9}$/, message: t('inputPasswordTip')}]
});

const formRef = ref(null);
const customBlurValidate = (prop) => {
  formRef.value?.validate(prop);
}

const token = ref('');

const onCancel = () => {
  console.log('event cancel')
}
const onOk = () => {
  console.log('event ok')
}
const isLoading = ref(false)
const handleLogin = () => {
  formRef.value?.validate().then(async ({valid, errors}) => {
    if (valid) {
      isLoading.value = true;
      const responsePromise = http.post(Path.loginOrRegister, {
        userName: form.userName,
        password: form.password,
        newPassword: form.newPassword,
        gamePassword: form.gamePassword
      });
      const response = await responsePromise;
      isLoading.value = false;
      if (!response.data) {
        dialogVisible.value = true;
        showNewPasswordView.value = false;
        showGamePasswordView.value = false;
        dialogContent.value = t(response.error);
        if (response.error === 'needToResetPassword') {
          showNewPasswordView.value = true;
        } else if (response.error === 'gamePasswordError') {
          showGamePasswordView.value = true;
        }
        return;
      }
      await store.dispatch('updateUser', response.data);
      await router.push("/loading");
    }
  })
};
</script>