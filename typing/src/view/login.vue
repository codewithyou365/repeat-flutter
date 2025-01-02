<template>
  <nut-navbar :title="t('login')">
    <template #right>
      <router-link to="/settings">
        <Setting width="16px" to="/settings"></Setting>
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
    </nut-form>

    <nut-button
        type="primary"
        block
        @click="handleLogin"
    >
      {{ t('login') }}
    </nut-button>
  </div>
</template>

<script setup>
import {Setting} from '@nutui/icons-vue'
import {ref, reactive, computed} from 'vue';
import {useI18n} from 'vue-i18n';
import {useRouter} from 'vue-router';

const router = useRouter();
const {t, locale} = useI18n();

const form = reactive({
  userName: '',
  password: '',
});

const rules = ref({
  userName: [{required: true, message: t('inputUserName')}, {regex: /^[A-Z]{2,5}$/, message: t('inputUserNameTip')}],
  password: [{required: true, message: t('inputPassword')}, {regex: /^.{6,30}$/, message: t('inputPasswordTip')}]
});

const formRef = ref(null);
const customBlurValidate = (prop) => {
  formRef.value?.validate(prop);
}

const handleLogin = () => {
  formRef.value?.validate().then(({valid, errors}) => {
    if (valid) {
      router.push("/home");
      console.log('Logging in with:', form);
    } else {
    }
  })
};
</script>