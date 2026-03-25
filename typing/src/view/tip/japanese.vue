<template>
  <div class="japan-game" :class="themeClass">
    <div class="answer-bar">
      <div class="answer-header">
        <div class="answer-label">{{ answerLabel }}</div>
        <button
            class="mute-button"
            type="button"
            :aria-pressed="isMuted"
            :aria-label="isMuted ? 'Muted' : 'Sound on'"
            @click="toggleMute"
        >
          <span class="mute-icon" aria-hidden="true">
            <svg v-if="isMuted" viewBox="0 0 24 24">
              <path d="M4 9h4l5-4v14l-5-4H4z"/>
              <path d="M16 9l5 6M21 9l-5 6" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
            </svg>
            <svg v-else viewBox="0 0 24 24">
              <path d="M4 9h4l5-4v14l-5-4H4z"/>
              <path d="M16.5 8.5a4.5 4.5 0 010 7" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
              <path d="M18.8 6.2a7.5 7.5 0 010 11.6" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
            </svg>
          </span>
        </button>
      </div>
      <div class="answer-text">
        <template v-for="(unit, idx) in answerUnits" :key="`${unit}-${idx}`">
          <br v-if="isNewlineUnit(unit)" class="answer-break" />
          <span
              v-else
              class="answer-char"
              :class="{ clickable: anchorByValue.has(unit), whitespace: isWhitespaceUnit(unit) }"
              @click="onAnswerCharClick(unit)"
          >{{ unit }}</span>
        </template>
      </div>
    </div>

    <div class="kana-scroll">
      <div
          v-for="section in sections"
          :key="section.title"
          class="kana-section"
      >
        <div class="section-title">{{ section.title }}</div>
        <div class="kana-table">
          <div
              v-for="row in section.rows"
              :key="row.label"
              class="kana-row"
          >
            <div class="row-label">{{ row.label }}</div>
            <div class="row-cells">
              <div
                  v-for="(cell, cellIndex) in row.cells"
                  :key="cell?.id || `${row.label}-empty-${cellIndex}`"
                  class="kana-cell"
                  :class="{ empty: !cell, flash: cell && flashingId === cell.id }"
                  :id="cell?.id"
                  @click="cell && onKanaCellClick(cell)"
              >
                <template v-if="cell">
                  <div class="kana-main">{{ cell.hira }}</div>
                  <div class="kana-sub">{{ cell.kata }}</div>
                  <div class="kana-romaji">{{ cell.romaji }}</div>
                </template>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import {computed, nextTick, onMounted, ref, watch} from 'vue';
import {client, Request, Response} from '../../api/ws.ts';
import {Path} from '../../utils/constant.ts';
import {useRoute} from 'vue-router';
import {useStore} from 'vuex';

type KanaCell = {
  id: string;
  hira: string;
  kata: string;
  romaji: string;
  match: string[];
};

type KanaRow = {
  label: string;
  cells: Array<KanaCell | null>;
};

type KanaSection = {
  title: string;
  rows: KanaRow[];
};

const answer = ref('');
const flashingId = ref<string | null>(null);
const isMuted = ref(true);
const route = useRoute();
const store = useStore();

const buildCell = (
    id: string,
    hira: string,
    kata: string,
    romaji: string,
    match: string[] = []
): KanaCell => ({
  id,
  hira,
  kata,
  romaji,
  match: match.length ? match : [hira, kata],
});

const sections: KanaSection[] = [
  {
    title: '五十音',
    rows: [
      {label: 'A', cells: [
          buildCell('a', 'あ', 'ア', 'a'),
          buildCell('i', 'い', 'イ', 'i'),
          buildCell('u', 'う', 'ウ', 'u'),
          buildCell('e', 'え', 'エ', 'e'),
          buildCell('o', 'お', 'オ', 'o'),
        ]},
      {label: 'K', cells: [
          buildCell('ka', 'か', 'カ', 'ka'),
          buildCell('ki', 'き', 'キ', 'ki'),
          buildCell('ku', 'く', 'ク', 'ku'),
          buildCell('ke', 'け', 'ケ', 'ke'),
          buildCell('ko', 'こ', 'コ', 'ko'),
        ]},
      {label: 'S', cells: [
          buildCell('sa', 'さ', 'サ', 'sa'),
          buildCell('shi', 'し', 'シ', 'shi'),
          buildCell('su', 'す', 'ス', 'su'),
          buildCell('se', 'せ', 'セ', 'se'),
          buildCell('so', 'そ', 'ソ', 'so'),
        ]},
      {label: 'T', cells: [
          buildCell('ta', 'た', 'タ', 'ta'),
          buildCell('chi', 'ち', 'チ', 'chi'),
          buildCell('tsu', 'つ', 'ツ', 'tsu', ['つ', 'ツ', 'っ', 'ッ']),
          buildCell('te', 'て', 'テ', 'te'),
          buildCell('to', 'と', 'ト', 'to'),
        ]},
      {label: 'N', cells: [
          buildCell('na', 'な', 'ナ', 'na'),
          buildCell('ni', 'に', 'ニ', 'ni'),
          buildCell('nu', 'ぬ', 'ヌ', 'nu'),
          buildCell('ne', 'ね', 'ネ', 'ne'),
          buildCell('no', 'の', 'ノ', 'no'),
        ]},
      {label: 'H', cells: [
          buildCell('ha', 'は', 'ハ', 'ha'),
          buildCell('hi', 'ひ', 'ヒ', 'hi'),
          buildCell('fu', 'ふ', 'フ', 'fu'),
          buildCell('he', 'へ', 'ヘ', 'he'),
          buildCell('ho', 'ほ', 'ホ', 'ho'),
        ]},
      {label: 'M', cells: [
          buildCell('ma', 'ま', 'マ', 'ma'),
          buildCell('mi', 'み', 'ミ', 'mi'),
          buildCell('mu', 'む', 'ム', 'mu'),
          buildCell('me', 'め', 'メ', 'me'),
          buildCell('mo', 'も', 'モ', 'mo'),
        ]},
      {label: 'Y', cells: [
          buildCell('ya', 'や', 'ヤ', 'ya'),
          null,
          buildCell('yu', 'ゆ', 'ユ', 'yu'),
          null,
          buildCell('yo', 'よ', 'ヨ', 'yo'),
        ]},
      {label: 'R', cells: [
          buildCell('ra', 'ら', 'ラ', 'ra'),
          buildCell('ri', 'り', 'リ', 'ri'),
          buildCell('ru', 'る', 'ル', 'ru'),
          buildCell('re', 'れ', 'レ', 're'),
          buildCell('ro', 'ろ', 'ロ', 'ro'),
        ]},
      {label: 'W', cells: [
          buildCell('wa', 'わ', 'ワ', 'wa'),
          null,
          null,
          null,
          buildCell('wo', 'を', 'ヲ', 'wo'),
        ]},
      {label: 'N', cells: [
          buildCell('n', 'ん', 'ン', 'n'),
          null,
          null,
          null,
          null,
        ]},
    ]
  },
  {
    title: '浊音/半浊音',
    rows: [
      {label: 'G', cells: [
          buildCell('ga', 'が', 'ガ', 'ga'),
          buildCell('gi', 'ぎ', 'ギ', 'gi'),
          buildCell('gu', 'ぐ', 'グ', 'gu'),
          buildCell('ge', 'げ', 'ゲ', 'ge'),
          buildCell('go', 'ご', 'ゴ', 'go'),
        ]},
      {label: 'Z', cells: [
          buildCell('za', 'ざ', 'ザ', 'za'),
          buildCell('ji', 'じ', 'ジ', 'ji'),
          buildCell('zu', 'ず', 'ズ', 'zu'),
          buildCell('ze', 'ぜ', 'ゼ', 'ze'),
          buildCell('zo', 'ぞ', 'ゾ', 'zo'),
        ]},
      {label: 'D', cells: [
          buildCell('da', 'だ', 'ダ', 'da'),
          buildCell('di', 'ぢ', 'ヂ', 'di'),
          buildCell('du', 'づ', 'ヅ', 'du'),
          buildCell('de', 'で', 'デ', 'de'),
          buildCell('do', 'ど', 'ド', 'do'),
        ]},
      {label: 'B', cells: [
          buildCell('ba', 'ば', 'バ', 'ba'),
          buildCell('bi', 'び', 'ビ', 'bi'),
          buildCell('bu', 'ぶ', 'ブ', 'bu'),
          buildCell('be', 'べ', 'ベ', 'be'),
          buildCell('bo', 'ぼ', 'ボ', 'bo'),
        ]},
      {label: 'P', cells: [
          buildCell('pa', 'ぱ', 'パ', 'pa'),
          buildCell('pi', 'ぴ', 'ピ', 'pi'),
          buildCell('pu', 'ぷ', 'プ', 'pu'),
          buildCell('pe', 'ぺ', 'ペ', 'pe'),
          buildCell('po', 'ぽ', 'ポ', 'po'),
        ]},
    ]
  },
  {
    title: '拗音',
    rows: [
      {label: 'K', cells: [
          buildCell('kya', 'きゃ', 'キャ', 'kya', ['きゃ', 'キャ', 'ゃ', 'ャ']),
          buildCell('kyu', 'きゅ', 'キュ', 'kyu', ['きゅ', 'キュ', 'ゅ', 'ュ']),
          buildCell('kyo', 'きょ', 'キョ', 'kyo', ['きょ', 'キョ', 'ょ', 'ョ']),
          null,
          null,
        ]},
      {label: 'S', cells: [
          buildCell('sha', 'しゃ', 'シャ', 'sha', ['しゃ', 'シャ', 'ゃ', 'ャ']),
          buildCell('shu', 'しゅ', 'シュ', 'shu', ['しゅ', 'シュ', 'ゅ', 'ュ']),
          buildCell('sho', 'しょ', 'ショ', 'sho', ['しょ', 'ショ', 'ょ', 'ョ']),
          null,
          null,
        ]},
      {label: 'T', cells: [
          buildCell('cha', 'ちゃ', 'チャ', 'cha', ['ちゃ', 'チャ', 'ゃ', 'ャ']),
          buildCell('chu', 'ちゅ', 'チュ', 'chu', ['ちゅ', 'チュ', 'ゅ', 'ュ']),
          buildCell('cho', 'ちょ', 'チョ', 'cho', ['ちょ', 'チョ', 'ょ', 'ョ']),
          null,
          null,
        ]},
      {label: 'N', cells: [
          buildCell('nya', 'にゃ', 'ニャ', 'nya', ['にゃ', 'ニャ', 'ゃ', 'ャ']),
          buildCell('nyu', 'にゅ', 'ニュ', 'nyu', ['にゅ', 'ニュ', 'ゅ', 'ュ']),
          buildCell('nyo', 'にょ', 'ニョ', 'nyo', ['にょ', 'ニョ', 'ょ', 'ョ']),
          null,
          null,
        ]},
      {label: 'H', cells: [
          buildCell('hya', 'ひゃ', 'ヒャ', 'hya', ['ひゃ', 'ヒャ', 'ゃ', 'ャ']),
          buildCell('hyu', 'ひゅ', 'ヒュ', 'hyu', ['ひゅ', 'ヒュ', 'ゅ', 'ュ']),
          buildCell('hyo', 'ひょ', 'ヒョ', 'hyo', ['ひょ', 'ヒョ', 'ょ', 'ョ']),
          null,
          null,
        ]},
      {label: 'M', cells: [
          buildCell('mya', 'みゃ', 'ミャ', 'mya', ['みゃ', 'ミャ', 'ゃ', 'ャ']),
          buildCell('myu', 'みゅ', 'ミュ', 'myu', ['みゅ', 'ミュ', 'ゅ', 'ュ']),
          buildCell('myo', 'みょ', 'ミョ', 'myo', ['みょ', 'ミョ', 'ょ', 'ョ']),
          null,
          null,
        ]},
      {label: 'R', cells: [
          buildCell('rya', 'りゃ', 'リャ', 'rya', ['りゃ', 'リャ', 'ゃ', 'ャ']),
          buildCell('ryu', 'りゅ', 'リュ', 'ryu', ['りゅ', 'リュ', 'ゅ', 'ュ']),
          buildCell('ryo', 'りょ', 'リョ', 'ryo', ['りょ', 'リョ', 'ょ', 'ョ']),
          null,
          null,
        ]},
      {label: 'G', cells: [
          buildCell('gya', 'ぎゃ', 'ギャ', 'gya', ['ぎゃ', 'ギャ', 'ゃ', 'ャ']),
          buildCell('gyu', 'ぎゅ', 'ギュ', 'gyu', ['ぎゅ', 'ギュ', 'ゅ', 'ュ']),
          buildCell('gyo', 'ぎょ', 'ギョ', 'gyo', ['ぎょ', 'ギョ', 'ょ', 'ョ']),
          null,
          null,
        ]},
      {label: 'J', cells: [
          buildCell('ja', 'じゃ', 'ジャ', 'ja', ['じゃ', 'ジャ', 'ゃ', 'ャ']),
          buildCell('ju', 'じゅ', 'ジュ', 'ju', ['じゅ', 'ジュ', 'ゅ', 'ュ']),
          buildCell('jo', 'じょ', 'ジョ', 'jo', ['じょ', 'ジョ', 'ょ', 'ョ']),
          null,
          null,
        ]},
      {label: 'B', cells: [
          buildCell('bya', 'びゃ', 'ビャ', 'bya', ['びゃ', 'ビャ', 'ゃ', 'ャ']),
          buildCell('byu', 'びゅ', 'ビュ', 'byu', ['びゅ', 'ビュ', 'ゅ', 'ュ']),
          buildCell('byo', 'びょ', 'ビョ', 'byo', ['びょ', 'ビョ', 'ょ', 'ョ']),
          null,
          null,
        ]},
      {label: 'P', cells: [
          buildCell('pya', 'ぴゃ', 'ピャ', 'pya', ['ぴゃ', 'ピャ', 'ゃ', 'ャ']),
          buildCell('pyu', 'ぴゅ', 'ピュ', 'pyu', ['ぴゅ', 'ピュ', 'ゅ', 'ュ']),
          buildCell('pyo', 'ぴょ', 'ピョ', 'pyo', ['ぴょ', 'ピョ', 'ょ', 'ョ']),
          null,
          null,
        ]},
    ]
  }
];

const anchorByValue = computed(() => {
  const map = new Map<string, string>();
  sections.forEach(section => {
    section.rows.forEach(row => {
      row.cells.forEach(cell => {
        if (!cell) return;
        cell.match.forEach(value => {
          if (!map.has(value)) {
            map.set(value, cell.id);
          }
        });
      });
    });
  });
  return map;
});

const smallKana = new Set([
  'ゃ', 'ゅ', 'ょ', 'ぁ', 'ぃ', 'ぅ', 'ぇ', 'ぉ', 'ゎ',
  'ャ', 'ュ', 'ョ', 'ァ', 'ィ', 'ゥ', 'ェ', 'ォ', 'ヮ',
]);

const buildAnswerUnits = (text: string) => {
  const units: string[] = [];
  Array.from(text).forEach(ch => {
    if (smallKana.has(ch) && units.length && units[units.length - 1] !== '\n' && units[units.length - 1].trim() !== '') {
      units[units.length - 1] += ch;
    } else {
      units.push(ch);
    }
  });
  return units;
};

const answerUnits = computed(() => buildAnswerUnits(answer.value || ''));
const isNewlineUnit = (unit: string) => unit === '\n';
const isWhitespaceUnit = (unit: string) => unit.trim() === '' && !isNewlineUnit(unit);

const tipMethodByPath: Record<string, string> = {
  '/tip/japanese/a': 'Tip.answer',
  '/tip/japanese/q': 'Tip.question',
  '/tip/japanese/t': 'Tip.tip',
  '/tip/japanese/n': 'Tip.note',
};

const tipMethod = computed(() => tipMethodByPath[route.path] || 'Tip.answer');
const tipTypeByPath: Record<string, string> = {
  '/tip/japanese/a': 'a',
  '/tip/japanese/q': 'q',
  '/tip/japanese/t': 't',
  '/tip/japanese/n': 'n',
};

const tipType = computed(() => tipTypeByPath[route.path] || 'a');
const answerLabelByPath: Record<string, string> = {
  '/tip/japanese/a': 'Answer',
  '/tip/japanese/q': 'Question',
  '/tip/japanese/t': 'Tip',
  '/tip/japanese/n': 'Note',
};

const answerLabel = computed(() => answerLabelByPath[route.path] || 'Answer');
const themeClass = computed(() => (store.getters.currentTheme === 'dark' ? 'theme-dark' : 'theme-light'));

const speak = async (text: string) => {
  if (isMuted.value) return;
  if (!client.node) return;
  try {
    const req = new Request({
      path: Path.tip,
      headers: {'jsMethod': 'Tip.tts'},
      data: {text, type: tipType.value},
    });
    await client.node.send(req);
  } catch (error) {
    console.error('Error sending tts:', error);
  }
};

const toggleMute = () => {
  isMuted.value = !isMuted.value;
};

const triggerFlash = async (id: string) => {
  if (flashingId.value === id) {
    flashingId.value = null;
    await nextTick();
  }
  flashingId.value = id;
  window.setTimeout(() => {
    if (flashingId.value === id) {
      flashingId.value = null;
    }
  }, 420);
};

const onAnswerCharClick = (ch: string) => {
  const anchor = anchorByValue.value.get(ch);
  if (!anchor) return;
  const target = document.getElementById(anchor);
  if (!target) return;
  target.scrollIntoView({behavior: 'smooth', block: 'center'});
  void triggerFlash(anchor);
  void speak(ch);
};

const onKanaCellClick = (cell: KanaCell) => {
  void speak(cell.hira);
};

const refresh = async () => {
  const req = new Request({
    path: Path.tip,
    headers: {'jsMethod': tipMethod.value},
  });
  const res = await client.node!.send(req);
  answer.value = res.data || '';
};

onMounted(async () => {
  await refresh();
  client.controllers.set('gameRefresh', async () => {
    await refresh();
    return new Response();
  });
});

watch(() => route.path, async () => {
  await refresh();
});
</script>

<style scoped>
.japan-game {
  display: flex;
  flex-direction: column;
  height: 100%;
}

.answer-bar {
  position: sticky;
  top: 0;
  z-index: 2;
  background: #f7f2e8;
  padding: 12px 16px;
  border-bottom: 1px solid rgba(0, 0, 0, 0.08);
}

.answer-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  margin-bottom: 6px;
}

.answer-label {
  font-size: 12px;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: #7a6b5b;
}

.mute-button {
  border: 1px solid rgba(120, 96, 70, 0.35);
  background: #fff9ef;
  color: #6b4f33;
  border-radius: 10px;
  width: 34px;
  height: 30px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: background 0.2s ease, transform 0.2s ease, box-shadow 0.2s ease;
}

.japan-game.theme-dark {
  background: #1f1b16;
}

.japan-game.theme-dark .answer-bar {
  background: #2a241d;
  border-bottom: 1px solid rgba(255, 255, 255, 0.08);
}

.japan-game.theme-dark .answer-label {
  color: #cdbda7;
}

.japan-game.theme-dark .answer-text {
  color: #f2e6d6;
}

.japan-game.theme-dark .answer-char.clickable {
  background: rgba(199, 147, 71, 0.18);
}

.japan-game.theme-dark .answer-char.clickable:hover {
  background: rgba(199, 147, 71, 0.32);
}

.japan-game.theme-dark .mute-button {
  background: #30281f;
  color: #e9dac6;
  border-color: rgba(233, 218, 198, 0.3);
}

.japan-game.theme-dark .mute-button:hover {
  background: #3a3025;
  box-shadow: 0 6px 10px rgba(0, 0, 0, 0.35);
}

.japan-game.theme-dark .kana-scroll {
  background: radial-gradient(circle at top, #2b231b 0%, #1b1612 100%);
}

.japan-game.theme-dark .section-title {
  color: #ccb59a;
}

.japan-game.theme-dark .row-label {
  color: #b9a48b;
}

.japan-game.theme-dark .kana-cell {
  background: #2a241d;
  border: 1px solid rgba(233, 218, 198, 0.18);
  box-shadow: 0 6px 12px rgba(0, 0, 0, 0.25);
}

.japan-game.theme-dark .kana-cell.flash {
  border-color: rgba(180, 140, 90, 0.6);
  animation: kana-flash-dark 0.42s ease;
}

.japan-game.theme-dark .kana-cell.empty {
  background: transparent;
  border: 1px dashed rgba(233, 218, 198, 0.2);
  box-shadow: none;
}

.japan-game.theme-dark .kana-main {
  color: #f4e7d7;
}

.japan-game.theme-dark .kana-sub {
  color: #d3c1ad;
}

.japan-game.theme-dark .kana-romaji {
  color: #bda88f;
}

@keyframes kana-flash-dark {
  0% {
    transform: scale(1);
    background: #2a241d;
    box-shadow: 0 0 0 rgba(180, 140, 90, 0);
  }
  40% {
    transform: scale(1.05);
    background: #3a2f24;
    box-shadow: 0 10px 18px rgba(180, 140, 90, 0.25);
  }
  100% {
    transform: scale(1);
    background: #2a241d;
    box-shadow: 0 6px 12px rgba(0, 0, 0, 0.25);
  }
}

.mute-icon svg {
  width: 18px;
  height: 18px;
  display: block;
  fill: currentColor;
}

.mute-button:hover {
  background: #fff1d8;
  transform: translateY(-1px);
  box-shadow: 0 6px 10px rgba(120, 90, 50, 0.15);
}

.answer-text {
  display: block;
  max-height: 140px;
  overflow-y: auto;
  padding-right: 6px;
  font-size: 20px;
  color: #2c2218;
  white-space: pre-wrap;
  line-height: 1.6;
}

.answer-char {
  display: inline-block;
  padding: 2px 4px;
  margin: 0 4px 6px 0;
  border-radius: 6px;
  transition: background 0.2s ease, transform 0.2s ease;
}

.answer-char.whitespace {
  padding: 0;
  margin: 0;
  background: transparent;
  border-radius: 0;
  pointer-events: none;
}

.answer-break {
  display: block;
  height: 0;
}

.answer-char.clickable {
  cursor: pointer;
  background: rgba(199, 147, 71, 0.12);
}

.answer-char.clickable:hover {
  background: rgba(199, 147, 71, 0.24);
  transform: translateY(-1px);
}

.kana-scroll {
  flex: 1;
  overflow-y: auto;
  padding: 16px;
  background: radial-gradient(circle at top, #fff8ee 0%, #f1e8dc 100%);
}

.kana-section + .kana-section {
  margin-top: 24px;
}

.section-title {
  font-size: 14px;
  color: #735b44;
  margin-bottom: 12px;
  font-weight: 600;
}

.kana-table {
  display: grid;
  gap: 10px;
}

.kana-row {
  display: grid;
  grid-template-columns: 40px 1fr;
  gap: 10px;
  align-items: center;
}

.row-label {
  font-size: 12px;
  color: #6c5b4b;
  text-transform: uppercase;
  letter-spacing: 0.12em;
}

.row-cells {
  display: grid;
  grid-template-columns: repeat(5, minmax(56px, 1fr));
  gap: 10px;
}

.kana-cell {
  background: #fffdf8;
  border: 1px solid rgba(86, 67, 47, 0.12);
  border-radius: 12px;
  padding: 10px 6px;
  text-align: center;
  min-height: 70px;
  box-shadow: 0 6px 12px rgba(90, 65, 40, 0.08);
}

.kana-cell.flash {
  animation: kana-flash 0.42s ease;
  border-color: rgba(199, 147, 71, 0.6);
}

.kana-cell.empty {
  background: transparent;
  border: 1px dashed rgba(120, 96, 70, 0.15);
  box-shadow: none;
}

.kana-main {
  font-size: 20px;
  color: #2d2218;
}

.kana-sub {
  font-size: 16px;
  color: #5c4b3a;
}

.kana-romaji {
  font-size: 11px;
  color: #927963;
  letter-spacing: 0.08em;
}

@keyframes kana-flash {
  0% {
    transform: scale(1);
    background: #fff7e1;
    box-shadow: 0 0 0 rgba(199, 147, 71, 0);
  }
  40% {
    transform: scale(1.06);
    background: #ffeac2;
    box-shadow: 0 12px 24px rgba(199, 147, 71, 0.28);
  }
  100% {
    transform: scale(1);
    background: #fffdf8;
    box-shadow: 0 6px 12px rgba(90, 65, 40, 0.08);
  }
}

@media (max-width: 720px) {
  .row-cells {
    grid-template-columns: repeat(5, minmax(48px, 1fr));
  }

  .kana-cell {
    min-height: 64px;
  }
}
</style>
