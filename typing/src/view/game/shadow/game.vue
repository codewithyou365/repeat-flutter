<template>
  <div class="shadow">
    <!-- 这一条没有英文原文，跟读不了 -->
    <nut-cell v-if="s.phase === 'noText'">{{ t('shadowNoText') }}</nut-cell>

    <template v-else>
      <!-- 句子。出结果前一律中性灰，出了结果才上色。 -->
      <div class="sentence">
        <span
            v-for="(w, i) in wordsToShow"
            :key="i"
            :class="['word', hasResult ? w.level : 'neutral', w.missed ? 'missed' : '']"
            @click="openPhones(w)"
        >{{ w.w }}<sub v-if="hasResult" class="ws">{{ w.score }}</sub></span>
      </div>

      <!-- 提示区 -->
      <div v-if="s.error" class="tip err">{{ t(s.error) || s.error }}</div>
      <div v-else-if="mismatch" class="tip err">{{ t('shadowMismatch') }}</div>
      <div v-if="hasResult && s.degraded" class="tip warn">{{ t('shadowDegraded') }}</div>
      <div v-if="hasResult && extraPhones > 0" class="tip">
        {{ t('shadowExtraPhones', {n: extraPhones}) }}
      </div>
      <div v-if="s.recorder.remoteDown" class="tip warn">{{ t('shadowServerDown') }}</div>

      <!-- 分数 -->
      <div v-if="hasResult" class="scores">
        <div class="overall">
          <div class="num">{{ s.result!.overall }}</div>
          <div class="stars">{{ starText }}</div>
        </div>
        <div class="bars">
          <div class="bar" v-for="b in bars" :key="b.k">
            <span class="bl">{{ t(b.k) }}</span>
            <div class="track">
              <div class="fill" :style="{width: b.v + '%'}"></div>
            </div>
            <span class="bv">{{ b.v }}</span>
          </div>
        </div>
      </div>

      <div class="spacer"></div>

      <!-- 录音中的电平和秒表 -->
      <div v-if="s.phase === 'recording'" class="meter">
        <div class="level"><div class="lfill" :style="{width: levelPct + '%'}"></div></div>
        <div class="elapsed">{{ (s.recorder.elapsedMs / 1000).toFixed(1) }}s</div>
      </div>
      <div v-else-if="s.phase === 'scoring'" class="meter">
        <nut-icon name="loading" class="spin"></nut-icon>
        <span>{{ t('shadowScoring') }}</span>
      </div>
      <div v-else class="meter">
        <span class="attempt">{{ t('shadowAttempt', {a: s.attempt, b: s.maxAttempts}) }}</span>
      </div>

      <!-- 操作区 -->
      <div class="actions">
        <nut-button size="small" @click="listen" :disabled="busy">
          ▶ {{ t('shadowListen') }}
        </nut-button>

        <button
            class="rec"
            :class="{on: s.phase === 'recording'}"
            :disabled="!canRecord"
            @click="toggleRecord"
        >{{ s.phase === 'recording' ? '■' : '●' }}</button>

        <nut-button size="small" v-if="s.phase === 'result'" @click="retry" :disabled="!canRetry">
          {{ t('shadowRetry') }}
        </nut-button>
        <nut-button size="small" v-else disabled>{{ t('shadowRetry') }}</nut-button>
      </div>

      <nut-button block type="primary" class="next" @click="next" :disabled="s.phase === 'recording'">
        {{ t('shadowNext') }}
      </nut-button>

      <!-- 只有在主机（App 内嵌 WebView）上才能录音：麦克风属于跑 App 的那台设备，
           局域网里另一个浏览器按录音，录的是手机旁边那个人。 -->
      <div v-if="!isHost" class="tip">{{ t('shadowRecordOnHost') }}</div>
    </template>

    <!-- 逐词音素明细。这才是真正的教学载荷，总分只是道闸。 -->
    <nut-popup v-model:visible="phoneVisible" position="bottom" round :style="{height: '46%'}">
      <div class="pp">
        <div class="pph">{{ picked?.w }} <span class="ppscore">{{ picked?.score }}</span></div>
        <div v-if="!picked?.phones?.length" class="tip">{{ t('shadowNoPhones') }}</div>
        <div v-else class="plist">
          <div v-for="(p, i) in picked!.phones" :key="i" class="prow">
            <span class="pipa">{{ p.p }}</span>
            <div class="track">
              <div class="fill" :class="pLevel(p.score)" :style="{width: p.score + '%'}"></div>
            </div>
            <span class="pnum">{{ p.score }}</span>
            <span v-if="p.status !== 'ok'" class="pst">{{ t('shadowPhone_' + p.status) }}</span>
          </div>
        </div>
      </div>
    </nut-popup>
  </div>
</template>

<script setup lang="ts">
import {computed, onBeforeUnmount, ref, watch} from 'vue';
import {useI18n} from 'vue-i18n';
import {client, Request} from '../../../api/ws.ts';
import {Path} from '../../../utils/constant.ts';
import {ShadowStatus, ShadowWord} from '../../../vo/ShadowStatus.ts';

const props = defineProps<{ status: ShadowStatus }>();
const {t} = useI18n();

const s = computed(() => props.status);
const hasResult = computed(() => s.value.phase === 'result' && s.value.result != null);
const mismatch = computed(() => hasResult.value && s.value.result!.mismatch);
const extraPhones = computed(() => (hasResult.value ? s.value.result!.insertions : 0));
const busy = computed(() => s.value.phase === 'recording' || s.value.phase === 'scoring');

// 局域网浏览器客户端不给录音。setBrightness 桥也依赖同一个判断。
const isHost = computed(() =>
    window.location.hostname === '127.0.0.1' || window.location.hostname === 'localhost');

const canRecord = computed(() =>
    isHost.value && (s.value.phase === 'ready' || s.value.phase === 'recording'));
const canRetry = computed(() => s.value.attempt < s.value.maxAttempts);

const starText = computed(() => '★'.repeat(s.value.stars) + '☆'.repeat(3 - s.value.stars));

// 电平条：-60..0 dB 映射到 0..100%
const levelPct = computed(() => {
  const db = s.value.recorder.levelDb;
  return Math.max(0, Math.min(100, ((db + 60) / 60) * 100));
});

const bars = computed(() => {
  const r = s.value.result;
  if (!r) return [];
  return [
    {k: 'shadowAccuracy', v: r.accuracy},
    {k: 'shadowCompleteness', v: r.completeness},
    {k: 'shadowFluency', v: r.fluency},
  ];
});

// 出结果前按参考文本拆词显示；出了结果用服务端返回的分词（它才知道哪些词
// 被 g2p 丢掉了）。
const wordsToShow = computed<ShadowWord[]>(() => {
  if (hasResult.value) {
    return s.value.result!.words;
  }
  return (s.value.text.match(/[A-Za-z0-9'-]+/g) || [])
      .map((w) => new ShadowWord({w}));
});

const phoneVisible = ref(false);
const picked = ref<ShadowWord | null>(null);

const openPhones = (w: ShadowWord) => {
  if (!hasResult.value || !s.value.config.showPhones) return;
  picked.value = w;
  phoneVisible.value = true;
};

const pLevel = (score: number) => (score >= 80 ? 'good' : score >= 60 ? 'fair' : 'bad');

const call = async (method: string, data: any = '') => {
  try {
    const req = new Request({path: Path.game, headers: {jsMethod: 'Game.' + method}, data});
    return await client.node!.send(req);
  } catch (e) {
    console.error('shadow ' + method + ' failed:', e);
    return null;
  }
};

const listen = () => call('listen');
const retry = () => call('retry');
const next = () => call('next');

const toggleRecord = () => {
  if (s.value.phase === 'recording') {
    call('stopRecord');
  } else {
    call('startRecord');
  }
};

// ---- 轮询 ----
// 只在 recording/scoring 期间开。Game.* 有 5 秒上限、ws 有 10 秒上限，
// 所以进度只能这样拿，不能让某个调用一直挂着等结果。
let timer: number | null = null;

const stopPoll = () => {
  if (timer !== null) {
    clearInterval(timer);
    timer = null;
  }
};

const startPoll = () => {
  if (timer !== null) return;
  timer = window.setInterval(() => {
    call('poll');
  }, 300);
};

watch(
    () => s.value.phase,
    (p) => {
      if (p === 'recording' || p === 'scoring') {
        startPoll();
      } else {
        stopPoll();
      }
    },
    {immediate: true},
);

// 进入新一轮时自动播一遍参考音
watch(
    () => s.value.roundId,
    () => {
      if (s.value.config.autoListen && s.value.phase === 'ready') {
        listen();
      }
    },
);

onBeforeUnmount(() => {
  stopPoll();
  // 中途离开页面必须释放麦克风和前台服务，否则通知栏会一直挂着"正在录音"。
  // Dart 那边还有 maxRecordMs 自动停和 JsRuntime.dispose 两道保险。
  call('cancelRecord');
});
</script>

<style scoped>
.shadow {
  display: flex;
  flex-direction: column;
  flex: 1;
  min-height: 0;
  padding: 12px 14px calc(12px + env(safe-area-inset-bottom));
  gap: 8px;
}

.sentence {
  font-size: 20px;
  line-height: 2;
  word-break: break-word;
}

.word {
  display: inline-block;
  padding: 2px 6px;
  margin: 2px 3px;
  border-radius: 6px;
  background: #f0f0f0;
  color: #333;
}

.word.neutral {
  background: #f0f0f0;
}

.word.good {
  background: #d8f3dc;
  color: #1b4332;
}

.word.fair {
  background: #ffeeba;
  color: #7a5901;
}

.word.bad {
  background: #ffd6d6;
  color: #7a1616;
}

.word.missed {
  text-decoration: line-through;
  opacity: .6;
}

.ws {
  font-size: 10px;
  opacity: .7;
  margin-left: 3px;
}

.tip {
  font-size: 12px;
  color: #888;
}

.tip.err {
  color: #d33;
}

.tip.warn {
  color: #b8860b;
}

.scores {
  display: flex;
  align-items: center;
  gap: 16px;
}

.overall {
  text-align: center;
  min-width: 72px;
}

.overall .num {
  font-size: 34px;
  font-weight: 600;
  line-height: 1.1;
}

.stars {
  font-size: 14px;
  color: #f0a500;
}

.bars {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.bar {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 11px;
}

.bl {
  width: 48px;
  color: #888;
}

.bv {
  width: 24px;
  text-align: right;
  color: #888;
}

.track {
  flex: 1;
  height: 6px;
  background: #eee;
  border-radius: 3px;
  overflow: hidden;
}

.fill {
  height: 100%;
  background: #3b6ef5;
}

.fill.good {
  background: #52b788;
}

.fill.fair {
  background: #e0a500;
}

.fill.bad {
  background: #e05252;
}

.spacer {
  flex: 1;
  min-height: 0;
}

.meter {
  display: flex;
  align-items: center;
  gap: 10px;
  min-height: 22px;
  font-size: 12px;
  color: #888;
}

.level {
  flex: 1;
  height: 8px;
  background: #eee;
  border-radius: 4px;
  overflow: hidden;
}

.lfill {
  height: 100%;
  background: #e05252;
  transition: width .1s linear;
}

.spin {
  animation: sp 1s linear infinite;
}

@keyframes sp {
  to {
    transform: rotate(360deg);
  }
}

.actions {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
}

.rec {
  width: 62px;
  height: 62px;
  border-radius: 50%;
  border: 0;
  background: #e05252;
  color: #fff;
  font-size: 22px;
}

.rec.on {
  background: #333;
}

.rec:disabled {
  background: #ccc;
}

.next {
  margin-top: 4px;
}

.pp {
  padding: 16px;
  overflow-y: auto;
  height: 100%;
}

.pph {
  font-size: 18px;
  font-weight: 600;
  margin-bottom: 10px;
}

.ppscore {
  font-size: 13px;
  color: #888;
  margin-left: 6px;
}

.plist {
  display: flex;
  flex-direction: column;
  gap: 7px;
}

.prow {
  display: flex;
  align-items: center;
  gap: 8px;
}

.pipa {
  width: 40px;
  font-size: 16px;
}

.pnum {
  width: 28px;
  text-align: right;
  font-size: 12px;
  color: #888;
}

.pst {
  font-size: 11px;
  color: #d33;
}

/* 深色主题 */
.nut-theme-dark .word.neutral {
  background: #333;
  color: #ddd;
}

.nut-theme-dark .track,
.nut-theme-dark .level {
  background: #333;
}
</style>
