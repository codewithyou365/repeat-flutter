<template>
  <div class="morse-panel">
    <!-- 顶上一行：左边是当前敲到哪（点划 + 这串现在对应的字符），右边切换两种图。
         手机屏幕放不下两张图，二选一 -->
    <div class="morse-head">
      <span class="morse-code">
        <template v-if="code">
          <span v-for="(s, i) in code" :key="i" :class="s === '.' ? 'sym-dot' : 'sym-dash'"></span>
          <span class="morse-guess">{{ guess }}</span>
        </template>
        <span v-else-if="lastCode" class="morse-last" :class="{ invalid: !lastChar }">{{ lastChar ? lastChar.toUpperCase() : '✕' }}</span>
      </span>
      <span class="morse-switch">
        <span :class="{ active: view === 'tree' }" @pointerdown.prevent="emit('update:view', 'tree')">{{ treeLabel }}</span>
        <span :class="{ active: view === 'letter' }" @pointerdown.prevent="emit('update:view', 'letter')">{{ letterLabel }}</span>
      </span>
    </div>
    <!-- 两根计时条并排，按下和松开永远二选一，所以同一时刻只有一根在走：
         左边按住条：按下开始涨，涨满 dashMs 变色表示松手会是划；一松手立刻清空。
         右边间隔条：松手开始从空涨起，涨满 gapMs 就把这串定成一个字母；一按下立刻清空。 -->
    <div class="morse-bars">
      <div class="morse-bar">
        <div v-if="pressing" :key="'p' + pressId" class="morse-bar-hold" :style="{ animationDuration: dashMs + 'ms' }"></div>
      </div>
      <div class="morse-bar">
        <div v-if="!pressing && code" :key="'r' + releaseId" class="morse-bar-gap" :style="{ animationDuration: gapMs + 'ms' }"></div>
      </div>
    </div>

    <svg v-if="view === 'tree'" class="morse-tree" :viewBox="`0 0 ${W} ${H}`" preserveAspectRatio="xMidYMid meet">
      <!-- 底图连线：点走左边用点线，划走右边用虚线，跟常见的摩斯树一个画法 -->
      <line v-for="n in nodes" :key="'e' + n.code"
            :x1="n.px" :y1="n.py" :x2="n.x" :y2="n.y"
            class="edge" :class="[edgeState(n), n.code.endsWith('.') ? 'edge-dot' : 'edge-dash']"/>
      <!-- 已经走过的路：每多敲一下就多画一段，key 跟着码走，新加的那段挂载时播一遍描线动画 -->
      <line v-for="n in pathNodes" :key="'t' + n.code"
            :x1="n.px" :y1="n.py" :x2="n.x" :y2="n.y"
            class="trail" pathLength="1"/>
      <g class="node" :class="nodeState(root)">
        <circle :cx="root.x" :cy="root.y" r="13"/>
        <text :x="root.x" :y="root.y">{{ startLabel }}</text>
      </g>
      <g v-for="n in nodes" :key="'n' + n.code" class="node" :class="nodeState(n)">
        <circle :cx="n.x" :cy="n.y" :r="n.r"/>
        <text :x="n.x" :y="n.y" :style="{ fontSize: n.r + 1 + 'px' }">{{ n.ch.toUpperCase() }}</text>
      </g>
    </svg>

    <div v-else class="morse-letters">
      <!-- 每格上面是记忆图形（字母轮廓 + 顺着笔画摆的点和杠），下面是码。
           已经敲对的那几位，图形里对应的点/杠和下面的码一起亮起来 -->
      <div v-for="item in letters" :key="item.ch" class="letter" :class="letterState(item.code)">
        <svg class="letter-glyph" viewBox="-1.5 -1.5 23 27">
          <path class="glyph-outline" :d="item.glyph.outline"/>
          <path v-if="item.glyph.hint" class="glyph-hint" :d="item.glyph.hint"/>
          <template v-for="(m, i) in item.glyph.marks" :key="i">
            <circle v-if="m.length === 2" class="glyph-mark glyph-dot" :class="{ hit: isHit(item.code, i) }"
                    :cx="m[0]" :cy="m[1]" r="2.3"/>
            <line v-else class="glyph-mark glyph-dash" :class="{ hit: isHit(item.code, i) }"
                  :x1="m[0]" :y1="m[1]" :x2="m[2]" :y2="m[3]"/>
          </template>
        </svg>
        <div class="letter-code">
          <span v-for="(s, i) in item.code" :key="i"
                :class="[s === '.' ? 'sym-dot' : 'sym-dash', { hit: isHit(item.code, i) }]"></span>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import {computed} from 'vue';
import {MORSE_TABLE} from '../utils/morse.ts';
import {MORSE_GLYPHS} from '../utils/morse-glyphs.ts';

const props = defineProps<{
  code: string;
  pressing: boolean;
  pressId: number;
  releaseId: number;
  dashMs: number;
  gapMs: number;
  lastChar: string;
  lastCode: string;
  view: 'tree' | 'letter';
  treeLabel: string;
  letterLabel: string;
  startLabel: string;
}>();

const emit = defineEmits<{
  (e: 'update:view', view: 'tree' | 'letter'): void;
}>();

// 这串点划此刻要是定下来会是什么；码表里没有就是 ?
const guess = computed(() => {
  const ch = MORSE_TABLE[props.code];
  return ch ? ch.toUpperCase() : '?';
});

// ---- 树形图 ----
// 只画四层（全部 26 个字母都在这四层里），再往下是数字标点，16 个格子已经是手机宽度的极限了。
// 走到第五层以后树上停在第四层那个节点，顶上那行照样显示完整的点划。
const W = 320;
const H = 206;
const LEVELS = 4;
const levelY = (d: number) => 16 + d * 46;
const radiusOf = (d: number) => (d === LEVELS ? 9 : 11);

type TreeNode = { code: string; ch: string; x: number; y: number; px: number; py: number; r: number };
const root = {code: '', x: W / 2, y: levelY(0)};
const nodes: TreeNode[] = [];
for (let d = 1; d <= LEVELS; d++) {
  const count = 1 << d;
  for (let i = 0; i < count; i++) {
    // i 的二进制从高位到低位就是从根往下每一步：0 往左是点，1 往右是划
    const code = i.toString(2).padStart(d, '0').replace(/0/g, '.').replace(/1/g, '-');
    const parentCount = count >> 1;
    const pi = i >> 1;
    nodes.push({
      code,
      ch: MORSE_TABLE[code] ?? '',
      x: (i + 0.5) * W / count,
      y: levelY(d),
      px: d === 1 ? root.x : (pi + 0.5) * W / parentCount,
      py: levelY(d - 1),
      r: radiusOf(d),
    });
  }
}

// 当前码在树上能走到的部分（超过四层截断）
const treeCode = computed(() => props.code.slice(0, LEVELS));
const pathNodes = computed(() => nodes.filter((n) => treeCode.value.startsWith(n.code)));

// current: 正停在这；path: 走过的；candidate: 往下还能走到的；impossible: 已经不可能了；empty: 码表里没有的空位
const nodeState = (n: { code: string; ch?: string }) => {
  const c = treeCode.value;
  if (n.code === c) return 'current';
  if (c.startsWith(n.code)) return 'path';
  if (n.ch === '') return n.code.startsWith(c) ? 'empty' : 'empty impossible';
  return n.code.startsWith(c) ? 'candidate' : 'impossible';
};
const edgeState = (n: TreeNode) => (n.code.startsWith(treeCode.value) || treeCode.value.startsWith(n.code) ? '' : 'impossible');

// ---- 字母图 ----
const letters = Object.entries(MORSE_TABLE)
    .filter(([, ch]) => /[a-z]/.test(ch))
    .map(([code, ch]) => ({code, ch, glyph: MORSE_GLYPHS[ch]}))
    .sort((a, b) => a.ch.localeCompare(b.ch));

// current: 现在松手停住就是它；candidate: 再敲几下还能到；impossible: 已经敲岔了
const letterState = (code: string) => {
  if (!props.code) return 'candidate';
  if (code === props.code) return 'current';
  return code.startsWith(props.code) ? 'candidate' : 'impossible';
};
// 这个字母码的第 i 位是不是已经敲对了（敲岔了的字母一位都不亮）
const isHit = (code: string, i: number) => i < props.code.length && code.startsWith(props.code);
</script>

<style scoped>
.morse-panel {
  --morse-accent: #1989fa;
  --morse-current: #ff7d00;
  --morse-line: #999;
  --morse-gap: #07c160;
  --morse-fg: #1a1a1a;
  --morse-bg: #fff;
  color: var(--morse-fg);
  padding: 4px 16px 6px;
  flex-shrink: 0;
  user-select: none;
  -webkit-user-select: none;
}

.nut-theme-dark .morse-panel {
  --morse-accent: #5ca8ff;
  --morse-line: #777;
  --morse-fg: #f5f5f5;
  --morse-bg: #1b1b1b;
}

.morse-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  min-height: 24px;
}

.morse-code {
  display: flex;
  align-items: center;
  gap: 4px;
}

.morse-guess,
.morse-last {
  margin-left: 6px;
  font-size: 18px;
  font-weight: bold;
}

.morse-guess {
  color: var(--morse-current);
}

.morse-last {
  opacity: 0.5;
}

.morse-last.invalid {
  color: #f56c6c;
  opacity: 1;
}

.morse-switch {
  display: flex;
  font-size: 12px;
  border: 1px solid var(--morse-accent);
  border-radius: 4px;
  overflow: hidden;
}

.morse-switch span {
  padding: 2px 8px;
  color: var(--morse-accent);
  cursor: pointer;
}

.morse-switch span.active {
  background: var(--morse-accent);
  color: #fff;
}

/* 点划符号：点是圆点，划是短横 */
.sym-dot,
.sym-dash {
  display: inline-block;
  height: 6px;
  border-radius: 3px;
  background: currentColor;
}

.sym-dot {
  width: 6px;
}

.sym-dash {
  width: 16px;
}

.morse-bars {
  display: flex;
  gap: 6px;
  margin: 3px 0;
}

.morse-bar {
  flex: 1;
  height: 4px;
  background: rgba(128, 128, 128, 0.15);
  border-radius: 2px;
  overflow: hidden;
}

.morse-bar-hold,
.morse-bar-gap {
  height: 100%;
  animation-timing-function: linear;
  animation-fill-mode: forwards;
}

.morse-bar-hold {
  animation-name: morse-hold;
}

.morse-bar-gap {
  background: var(--morse-gap);
  animation-name: morse-gap;
}

/* 涨满前是点的颜色，涨满那一刻变成划的颜色 */
@keyframes morse-hold {
  0% { width: 0; background: var(--morse-accent); }
  99.9% { background: var(--morse-accent); }
  100% { width: 100%; background: var(--morse-current); }
}

@keyframes morse-gap {
  from { width: 0; }
  to { width: 100%; }
}

/* ---- 树形图 ---- */
.morse-tree {
  display: block;
  width: 100%;
  max-height: 32vh;
}

.edge {
  stroke: var(--morse-line);
  stroke-width: 1.5;
  transition: opacity 0.2s;
}

.edge-dot {
  stroke-dasharray: 1.5 3;
  stroke-linecap: round;
}

.edge-dash {
  stroke-dasharray: 6 3;
}

.edge.impossible {
  opacity: 0.2;
}

.trail {
  stroke: var(--morse-current);
  stroke-width: 3;
  stroke-linecap: round;
  stroke-dasharray: 1;
  stroke-dashoffset: 0;
  animation: morse-trail 0.18s ease-out;
}

@keyframes morse-trail {
  from { stroke-dashoffset: 1; }
  to { stroke-dashoffset: 0; }
}

.node {
  transition: opacity 0.2s;
}

.node circle {
  fill: var(--morse-bg);
  stroke: var(--morse-fg);
  stroke-width: 1.2;
  transition: fill 0.15s, stroke 0.15s;
}

.node text {
  fill: var(--morse-fg);
  font-size: 11px;
  text-anchor: middle;
  dominant-baseline: central;
}

.node.empty circle {
  stroke: var(--morse-line);
  stroke-dasharray: 2 2;
}

.node.path circle {
  stroke: var(--morse-current);
  stroke-width: 2;
}

.node.current circle {
  fill: var(--morse-current);
  stroke: var(--morse-current);
}

.node.current text {
  fill: #fff;
  font-weight: bold;
}

.node.impossible {
  opacity: 0.2;
}

/* ---- 字母图 ---- */
.morse-letters {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 4px;
  max-height: 32vh;
  overflow-y: auto;
}

.letter {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 3px 0;
  border: 1px solid rgba(128, 128, 128, 0.3);
  border-radius: 4px;
  transition: opacity 0.2s, background 0.15s;
}

.letter-glyph {
  display: block;
  width: 17px;
  height: 20px;
  overflow: visible;
}

.glyph-outline {
  fill: none;
  stroke: var(--morse-line);
  stroke-width: 1.3;
  stroke-linecap: round;
  stroke-linejoin: round;
}

.glyph-hint {
  fill: none;
  stroke: var(--morse-fg);
  stroke-width: 1.2;
  stroke-linecap: round;
  stroke-linejoin: round;
}

.glyph-dot {
  fill: var(--morse-fg);
}

.glyph-dash {
  stroke: var(--morse-fg);
  stroke-width: 3.2;
  stroke-linecap: round;
}

.glyph-mark {
  transition: fill 0.15s, stroke 0.15s;
}

.glyph-dot.hit {
  fill: var(--morse-current);
}

.glyph-dash.hit {
  stroke: var(--morse-current);
}

.letter-code {
  display: flex;
  align-items: center;
  gap: 2px;
  height: 8px;
  color: var(--morse-line);
}

.letter-code .sym-dot {
  width: 4px;
  height: 4px;
}

.letter-code .sym-dash {
  width: 9px;
  height: 4px;
}

/* 已经敲对的前缀点亮 */
.letter-code .hit {
  color: var(--morse-current);
}

/* 当前字母只描边加浅底：图形里亮起来的点杠也是这个颜色，整格涂满就看不见了 */
.letter.current {
  background: rgba(255, 125, 0, 0.12);
  border-color: var(--morse-current);
  box-shadow: 0 0 0 1px var(--morse-current);
}

.letter.impossible {
  opacity: 0.2;
}
</style>
