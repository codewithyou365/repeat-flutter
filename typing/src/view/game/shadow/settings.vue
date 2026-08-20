<template>
  <div style="margin: 8px">
    <nut-cell :title="t('shadowAutoListen')">
      <template #link>
        <nut-switch v-model="cfg.autoListen" @change="val => update('autoListen', val)"/>
      </template>
    </nut-cell>

    <nut-cell :title="t('shadowShowPhones')">
      <template #link>
        <nut-switch v-model="cfg.showPhones" @change="val => update('showPhones', val)"/>
      </template>
    </nut-cell>

    <nut-cell :title="t('shadowAutoNextOnPass')">
      <template #link>
        <nut-switch v-model="cfg.autoNextOnPass" @change="val => update('autoNextOnPass', val)"/>
      </template>
    </nut-cell>

    <nut-cell :title="t('shadowMaxRecordMs')">
      <template #link>
        <nut-input-number v-model="maxRecordSec" :step="5" min="5" max="30"
                          @change="v => update('maxRecordMs', Number(v) * 1000)"/>
        <span style="margin-left: 8px;">s</span>
      </template>
    </nut-cell>

    <nut-cell :title="t('shadowMaxAttempts')">
      <template #link>
        <nut-input-number v-model="cfg.maxAttempts" :step="1" min="1" max="9"
                          @change="v => update('maxAttempts', Number(v))"/>
      </template>
    </nut-cell>

    <nut-cell :title="t('shadowPassThreshold')">
      <template #link>
        <nut-input-number v-model="cfg.passThreshold" :step="5" min="0" max="100"
                          @change="v => update('passThreshold', Number(v))"/>
      </template>
    </nut-cell>

    <nut-cell :title="t('shadowStar1')">
      <template #link>
        <nut-input-number v-model="cfg.star1" :step="5" min="0" max="100"
                          @change="v => update('star1', Number(v))"/>
      </template>
    </nut-cell>

    <nut-cell :title="t('shadowStar2')">
      <template #link>
        <nut-input-number v-model="cfg.star2" :step="5" min="0" max="100"
                          @change="v => update('star2', Number(v))"/>
      </template>
    </nut-cell>

    <nut-cell :title="t('shadowStar3')">
      <template #link>
        <nut-input-number v-model="cfg.star3" :step="5" min="0" max="100"
                          @change="v => update('star3', Number(v))"/>
      </template>
    </nut-cell>

    <nut-cell :title="t('shadowMaxScore')">
      <template #link>
        <nut-input-number v-model="cfg.maxScore" :step="1" min="0" max="100"
                          @change="v => update('maxScore', Number(v))"/>
      </template>
    </nut-cell>

    <!-- 服务端状态。红黄绿阈值和 GOP 压缩参数在服务端的 calib.json 里，
         那边支持热改（POST /v1/calib），不在这里重复一套。 -->
    <nut-cell :title="t('shadowServerStatus')" :desc="healthText" @click="loadHealth"/>
  </div>
</template>

<script setup lang="ts">
import {computed, onMounted, ref, watch} from 'vue';
import {useI18n} from 'vue-i18n';
import {client, Request} from '../../../api/ws.ts';
import {Path} from '../../../utils/constant.ts';
import {ShadowConfig, ShadowStatus} from '../../../vo/ShadowStatus.ts';

const props = defineProps<{ status: ShadowStatus }>();
const {t} = useI18n();

const cfg = ref<ShadowConfig>(new ShadowConfig());
const healthText = ref('');

const maxRecordSec = computed({
  get: () => Math.round(cfg.value.maxRecordMs / 1000),
  set: (v: number) => {
    cfg.value.maxRecordMs = Number(v) * 1000;
  },
});

const call = async (method: string, data: any = '') => {
  try {
    const req = new Request({path: Path.game, headers: {jsMethod: 'Game.' + method}, data});
    return await client.node!.send(req);
  } catch (e) {
    console.error('shadow settings ' + method + ' failed:', e);
    return null;
  }
};

const update = async (key: string, value: any) => {
  await call('setConfig', {key, value});
};

const loadConfig = async () => {
  const res = await call('getConfig');
  if (res && res.data) {
    cfg.value = new ShadowConfig(res.data);
  }
};

const loadHealth = async () => {
  healthText.value = t('shadowRemoteTesting');
  const res = await call('health');
  const h = res?.data;
  if (!h || h.enabled === false) {
    healthText.value = t('shadowServerOff');
    return;
  }
  if (h.ok !== true) {
    healthText.value = t('shadowRemoteFail', {e: h.error || ''});
    return;
  }
  if (h.modelInstalled !== true) {
    healthText.value = t('shadowRemoteModelMissing');
    return;
  }
  healthText.value = t('shadowServerOk', {
    ms: h.latencyMs ?? 0,
    device: h.device || '',
  });
};

watch(() => props.status.config, (c) => {
  if (c) cfg.value = new ShadowConfig(c);
}, {immediate: true});

onMounted(async () => {
  await loadConfig();
  await loadHealth();
});
</script>
