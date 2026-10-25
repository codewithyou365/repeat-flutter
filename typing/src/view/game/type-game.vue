<template>
  <div v-if="isAdmin" class="settings-panel" style="margin: 8px">
    <!-- 熟词库整台设备共用一份，有效期也是全局的，不跟 profile 走，所以放在 profile 选择上面 -->
    <nut-cell :title="t('familiarExpireDays')">
      <template #link>
        <nut-radio-group v-model="familiarExpireDays" direction="horizontal" @change="setFamiliarExpireDays">
          <nut-radio :label="0">{{ t('familiarExpireNever') }}</nut-radio>
          <nut-radio :label="3">3</nut-radio>
          <nut-radio :label="5">5</nut-radio>
          <nut-radio :label="7">7</nut-radio>
        </nut-radio-group>
        <Ask color="#999" width="16px" height="16px" class="cell-help" @click="showHelp(t('familiarExpireDaysDesc'))"/>
      </template>
    </nut-cell>
    <nut-cell :title="t('profile')">
      <template #link>
        <nut-radio-group v-model="activeProfile" direction="horizontal" @change="setActiveProfile">
          <nut-radio v-for="(name, i) in profileNames" :key="i" :label="i">{{ name }}</nut-radio>
        </nut-radio-group>
      </template>
    </nut-cell>
    <nut-cell :title="t('profileName')" class="stacked-cell">
      <template #link>
        <nut-input
            v-model="profileNames[activeProfile]"
            class="stacked-key"
            @blur="setProfileName(activeProfile, profileNames[activeProfile])"
        />
      </template>
    </nut-cell>
    <nut-cell :title="t('ignoreCase')">
      <template #link>
        <nut-switch v-model="ignoreCase" @change="setIgnoreCase"/>
      </template>
    </nut-cell>
    <nut-cell :title="t('ignorePunctuation')">
      <template #link>
        <nut-switch v-model="ignorePunctuation" @change="setIgnorePunctuation"/>
      </template>
    </nut-cell>
    <nut-cell :title="t('ignoreNumber')">
      <template #link>
        <nut-switch v-model="ignoreNumber" @change="setIgnoreNumber"/>
      </template>
    </nut-cell>
    <nut-cell :title="t('familiarMs')" class="stacked-cell">
      <template #link>
        <nut-input
            v-model="familiarMsInput"
            type="number"
            class="stacked-key"
            @blur="setFamiliarMs(familiarMsInput)"
        />
        <Ask color="#999" width="16px" height="16px" class="cell-help" @click="showHelp(t('familiarMsDesc'))"/>
      </template>
    </nut-cell>
    <!-- 会出声的几行：第一行照旧是标题 + 触发键/开关，第二行是链接样式的小字，列出这一行用的音色
         （生词/熟词/字母各用哪个「朗读」动作的 TTS 配置），点它在底部弹层里改。
         手动播放、打完整词分生词/熟词两套：词在熟词库里就用熟词那套；熟词跳过成功念整词单独一套。 -->
    <nut-cell :title="t('manualPlayTrigger')" class="stacked-cell">
      <template #link>
        <span v-if="hasSpaceKey(manualPlayTrigger)" class="stacked-space">{{ t('spaceKey') }}</span>
        <nut-input
            v-model="manualPlayTrigger"
            class="stacked-key"
            @blur="setManualPlayTrigger(manualPlayTrigger)"
        />
        <nut-button size="mini" type="info" plain class="stacked-add" @click="openKeyPicker('manualPlay')">+</nut-button>
        <Ask color="#999" width="16px" height="16px" class="cell-help"
             @click="showHelp(t('familiarVoiceDesc') + '<br/><br/>' + t('ttsActionDesc') + '<br/><br/>' + t('multiKeyDesc'))"/>
        <div class="voice-line" :class="voiceLinkClass('manualPlay')" @click="openVoicePicker('manualPlay')">{{ voiceSummary('manualPlay') }}</div>
      </template>
    </nut-cell>
    <nut-cell :title="t('familiarSkipTrigger')" class="stacked-cell">
      <template #link>
        <span v-if="hasSpaceKey(familiarSkipTrigger)" class="stacked-space">{{ t('spaceKey') }}</span>
        <nut-input
            v-model="familiarSkipTrigger"
            class="stacked-key"
            @blur="setFamiliarSkipTrigger(familiarSkipTrigger)"
        />
        <nut-button size="mini" type="info" plain class="stacked-add" @click="openKeyPicker('familiarSkip')">+</nut-button>
        <Ask color="#999" width="16px" height="16px" class="cell-help"
             @click="showHelp(t('familiarSkipTriggerDesc') + '<br/><br/>' + t('ttsActionDesc') + '<br/><br/>' + t('multiKeyDesc'))"/>
        <div class="voice-line" :class="voiceLinkClass('familiarSkip')" @click="openVoicePicker('familiarSkip')">{{ voiceSummary('familiarSkip') }}</div>
      </template>
    </nut-cell>
    <nut-cell :title="t('skipTrigger')" class="stacked-cell">
      <template #link>
        <span v-if="hasSpaceKey(skipTrigger)" class="stacked-space">{{ t('spaceKey') }}</span>
        <nut-input
            v-model="skipTrigger"
            class="stacked-key"
            @blur="setSkipTrigger(skipTrigger)"
        />
        <nut-button size="mini" type="info" plain class="stacked-add" @click="openKeyPicker('skip')">+</nut-button>
        <Ask color="#999" width="16px" height="16px" class="cell-help"
             @click="showHelp(t('skipTriggerDesc') + '<br/><br/>' + t('familiarVoiceDesc') + '<br/><br/>' + t('ttsActionDesc') + '<br/><br/>' + t('multiKeyDesc'))"/>
        <div class="voice-line" :class="voiceLinkClass('skip')" @click="openVoicePicker('skip')">{{ voiceSummary('skip') }}</div>
      </template>
    </nut-cell>
    <nut-cell :title="t('spellPlayTrigger')" class="stacked-cell">
      <template #link>
        <span v-if="hasSpaceKey(spellPlayTrigger)" class="stacked-space">{{ t('spaceKey') }}</span>
        <nut-input
            v-model="spellPlayTrigger"
            class="stacked-key"
            @blur="setSpellPlayTrigger(spellPlayTrigger)"
        />
        <nut-button size="mini" type="info" plain class="stacked-add" @click="openKeyPicker('spellPlay')">+</nut-button>
        <Ask color="#999" width="16px" height="16px" class="cell-help"
             @click="showHelp(t('ttsActionDesc') + '<br/><br/>' + t('multiKeyDesc'))"/>
        <div class="voice-line" :class="voiceLinkClass('spellPlay')" @click="openVoicePicker('spellPlay')">{{ voiceSummary('spellPlay') }}</div>
      </template>
    </nut-cell>
    <nut-cell :title="t('spellResetLevel')">
      <template #link>
        <nut-switch v-model="spellResetLevel" @change="setSpellResetLevel"/>
      </template>
    </nut-cell>
    <nut-cell :title="t('speakLetters')" class="voice-cell">
      <template #link>
        <nut-switch v-model="speakLetters" @change="setSpeakLetters"/>
        <Ask color="#999" width="16px" height="16px" class="cell-help"
             @click="showHelp(t('ttsActionDesc'))"/>
        <div class="voice-line" :class="voiceLinkClass('speakLetters')" @click="openVoicePicker('speakLetters')">{{ voiceSummary('speakLetters') }}</div>
      </template>
    </nut-cell>
    <nut-cell :title="t('speakWord')" class="voice-cell">
      <template #link>
        <nut-switch v-model="speakWord" @change="setSpeakWord"/>
        <Ask color="#999" width="16px" height="16px" class="cell-help"
             @click="showHelp(t('speakWordDesc') + '<br/><br/>' + t('familiarVoiceDesc') + '<br/><br/>' + t('ttsActionDesc'))"/>
        <div class="voice-line" :class="voiceLinkClass('speakWord')" @click="openVoicePicker('speakWord')">{{ voiceSummary('speakWord') }}</div>
      </template>
    </nut-cell>
    <nut-cell :title="t('hintTrigger')" class="stacked-cell">
      <template #link>
        <span v-if="hasSpaceKey(hintTrigger)" class="stacked-space">{{ t('spaceKey') }}</span>
        <nut-input
            v-model="hintTrigger"
            class="stacked-key"
            @blur="setHintTrigger(hintTrigger)"
        />
        <nut-button size="mini" type="info" plain class="stacked-add" @click="openKeyPicker('hint')">+</nut-button>
        <Ask color="#999" width="16px" height="16px" class="cell-help" @click="showHelp(t('multiKeyDesc'))"/>
      </template>
    </nut-cell>
    <nut-cell :title="t('maskTrigger')" class="stacked-cell">
      <template #link>
        <span v-if="hasSpaceKey(maskTrigger)" class="stacked-space">{{ t('spaceKey') }}</span>
        <nut-input
            v-model="maskTrigger"
            class="stacked-key"
            @blur="setMaskTrigger(maskTrigger)"
        />
        <nut-button size="mini" type="info" plain class="stacked-add" @click="openKeyPicker('mask')">+</nut-button>
        <Ask color="#999" width="16px" height="16px" class="cell-help"
             @click="showHelp(t('maskTriggerDesc') + '<br/><br/>' + t('multiKeyDesc'))"/>
      </template>
    </nut-cell>
    <nut-cell :title="t('dimOnMask')">
      <template #link>
        <nut-switch v-model="dimOnMask" @change="setDimOnMask"/>
        <Ask color="#999" width="16px" height="16px" class="cell-help" @click="showHelp(t('dimOnMaskDesc'))"/>
      </template>
    </nut-cell>
    <nut-cell :title="t('immersiveOnMask')">
      <template #link>
        <nut-switch v-model="immersiveOnMask" @change="setImmersiveOnMask"/>
        <Ask color="#999" width="16px" height="16px" class="cell-help" @click="showHelp(t('immersiveOnMaskDesc'))"/>
      </template>
    </nut-cell>
    <nut-cell :title="t('deleteTrigger')" class="stacked-cell">
      <template #link>
        <span v-if="hasSpaceKey(deleteTrigger)" class="stacked-space">{{ t('spaceKey') }}</span>
        <nut-input
            v-model="deleteTrigger"
            class="stacked-key"
            @blur="setDeleteTrigger(deleteTrigger)"
        />
        <nut-button size="mini" type="info" plain class="stacked-add" @click="openKeyPicker('delete')">+</nut-button>
        <Ask color="#999" width="16px" height="16px" class="cell-help" @click="showHelp(`${t('deleteTriggerDesc')}; ${t('multiKeyDesc')}`)"/>
      </template>
    </nut-cell>
    <nut-cell :title="t('keyMapping')" class="stacked-cell">
      <template #link>
        <nut-input
            v-model="keyMapping"
            placeholder="a:abc•q:def"
            class="stacked-key"
            @blur="setKeyMapping(keyMapping)"
        />
        <Ask color="#999" width="16px" height="16px" class="cell-help" @click="showHelp(t('keyMappingDesc'))"/>
      </template>
    </nut-cell>
    <!-- 一条绑定：普通的按下就执行动作；wordAsk 的额外把光标所在的词当 input1 传过去。
         两种类型共用同一份数据结构和这一行 UI，只有标题/说明不同。
         排版跟上面的触发键行一样分三行：标题 + 删除/问号 / 输入框 + 加号 / 绑的动作（链接，点开在底部弹层里改）。 -->
    <nut-cell
        v-for="(binding, i) in assistiveTouchBindings"
        :key="i"
        :title="binding.wordAsk ? t('wordAskTrigger') : t('assistiveTouchTrigger')"
        class="stacked-cell stacked-cell-binding"
    >
      <template #link>
        <span v-if="hasSpaceKey(binding.key)" class="stacked-space">{{ t('spaceKey') }}</span>
        <nut-input
            v-model="binding.key"
            class="stacked-key"
            @blur="setBindingKey(i, binding.key)"
        />
        <nut-button size="mini" type="info" plain class="stacked-add" @click="openKeyPicker(i)">+</nut-button>
        <Del width="16px" height="16px" class="assist-binding-del" @click="removeBinding(i)"/>
        <Ask
            v-if="binding.wordAsk"
            color="#999"
            width="16px"
            height="16px"
            class="cell-help"
            @click="showHelp(t('wordAskTriggerDesc'))"
        />
        <div class="voice-line" :class="bindingPickable(i) ? 'voice-link' : 'voice-text'" @click="openBindingPicker(i)">
          {{ binding.wordAsk ? t('wordAskNet') + ': ' : '' }}{{ binding.action ? bindingActionName(binding) : t('assistiveTouchNoAction') }}
        </div>
        <!-- 单词提问并朗读多一条：问到的结果用哪个朗读动作读 -->
        <div v-if="binding.wordAsk" class="voice-line" :class="readPickable(i) ? 'voice-link' : 'voice-text'" @click="openReadPicker(i)">
          {{ t('wordAskRead') }}: {{ readActionName(binding) }}
        </div>
      </template>
    </nut-cell>
    <nut-cell>
      <nut-button size="small" type="info" @click="addBinding">
        {{ t('assistiveTouchAddBinding') }}
      </nut-button>
      <span v-if="assistiveTouchOptions.length === 0" style="margin-left: 8px; opacity: 0.6; font-size: 12px">
        {{ t('assistiveTouchNoAction') }}
      </span>
    </nut-cell>
    <!-- 新增绑定时先问是哪一类：普通辅助触控键，还是单词提问键 -->
    <nut-action-sheet
        v-model:visible="bindingTypeVisible"
        :title="t('bindingTypeTitle')"
        :menu-items="bindingTypeItems"
        @choose="onChooseBindingType"
    />
    <!-- 各触发键输入框旁的"+"：先选是加键盘按键还是手柄按键 -->
    <nut-action-sheet
        v-model:visible="keySourceVisible"
        :title="t('addSpecialKey')"
        :menu-items="keySourceItems"
        @choose="onChooseKeySource"
    />
    <!-- 键盘：给不方便直接打出来的特殊按键（Enter、NumLock 等）一个可选列表，
         选中后追加成 \enter 这样的写法，多个按键用 • 分隔 -->
    <nut-action-sheet
        v-model:visible="keyPickerVisible"
        :title="t('addSpecialKey')"
        :menu-items="specialKeyItems"
        @choose="onChooseSpecialKey"
    />
    <!-- 音色二级设置：一组一个单选列表，点一下就存 -->
    <nut-popup v-model:visible="voicePickerVisible" position="bottom" round closeable>
      <div class="voice-picker">
        <div class="voice-picker-title">{{ voicePickerRow ? t(voiceRows[voicePickerRow].title) : '' }}</div>
        <div v-for="group in voicePickerGroups" :key="group.slot.key" class="voice-picker-group">
          <div class="voice-picker-tag">{{ t(group.tag) }}</div>
          <nut-radio-group :model-value="group.slot.action.value" @update:model-value="(value: string) => setTtsAction(group.slot, value)">
            <nut-radio v-for="option in group.options"
                       :key="option.value" :label="option.value" class="voice-picker-option">
              {{ option.text }}
            </nut-radio>
          </nut-radio-group>
        </div>
        <div class="voice-picker-desc">{{ voicePickerGroups.length > 1 ? t('familiarVoiceDesc') + '. ' : '' }}{{ t('ttsActionDesc') }}</div>
      </div>
    </nut-popup>
    <!-- 辅助触控绑定的动作二级选择，样式跟音色弹层共用 -->
    <nut-popup v-model:visible="bindingPickerVisible" position="bottom" round closeable>
      <div class="voice-picker">
        <div class="voice-picker-title">{{ bindingPickerTitle }}</div>
        <div class="voice-picker-group">
          <nut-radio-group :model-value="bindingPickerAction" @update:model-value="(value: string) => onPickBinding(value)">
            <nut-radio v-for="option in bindingPickerOptions"
                       :key="option.value" :label="option.value" class="voice-picker-option">
              {{ option.text }}
            </nut-radio>
          </nut-radio-group>
        </div>
      </div>
    </nut-popup>
    <!-- 手柄：弹窗期间轮询手柄，按下的第一个键追加成 \pad0 这样的写法 -->
    <nut-dialog
        v-model:visible="gamepadCaptureVisible"
        :title="t('addGamepadKey')"
        :no-ok-btn="true"
        :cancelText="t('cancel')">
      <div style="white-space: pre-line">{{ gamepadCaptureTip }}</div>
    </nut-dialog>
  </div>
  <nut-cell v-else-if="cantPlayForMaintain">
    {{ t('cantPlayForMaintain') }}
  </nut-cell>
  <div v-else-if="ready" class="type-game-container">
    <div class="info-bar">
      <span v-if="waitingNames.length > 0" class="info-waiting">{{ t('waitingOthers', {names: waitingNames.join(', ')}) }}</span>
      <!-- 每个玩家自己挑用哪套 profile，只影响自己这台设备的打字体验。按槽位序号显示成 ①②③，跟图标排在一起 -->
      <span class="info-profile" @click="playerProfilePickerVisible = true">{{ circledNumber(playerProfile + 1) }}</span>
      <Voice class="info-icon" width="18px" height="18px" @click="speakCurrentWord"/>
      <Eye class="info-icon" width="18px" height="18px" @click="cycleMaskMode()"/>
      <Ask class="info-icon" width="18px" height="18px" @click="showTips"/>
    </div>
    <nut-action-sheet
        v-model:visible="playerProfilePickerVisible"
        :title="t('profile')"
        :menu-items="playerProfileItems"
        @choose="onChoosePlayerProfile"
    />
    <div v-if="eyesClosedMaskVisible" class="eyes-closed-mask" @pointerdown.prevent="onMaskPointerDown"></div>
    <div class="typing-content">
      <Typing
          ref="typingRef"
          :content="content"
          :disabled="false"
          :ignore-case="ignoreCase"
          :change-to-right-case-when-ignore-case="true"
          :ignore-punctuation="ignorePunctuation"
          :ignore-number="ignoreNumber"
          :ignore-content-indexes="ignoreContentIndexes"
          :ignore-space="true"
          :block-on-wrong="true"
          :manual-play-trigger="manualPlayTrigger"
          :spell-play-trigger="spellPlayTrigger"
          :hint-trigger="hintTrigger"
          :mask-trigger="maskTrigger"
          :hide-pending="maskMode === 'typed'"
          :delete-trigger="deleteTrigger"
          :assist-triggers="assistTriggerKeys"
          :key-mapping="keyMapping"
          :familiar-ranges="familiarRanges"
          :familiar-skip-trigger="familiarSkipTrigger"
          :skip-trigger="skipTrigger"
          @char-filled="onCharFilled"
          @completed="onCompleted"
          @manual-play="onManualPlay"
          @spell-play="onSpellPlay"
          @hint-trigger="onHintTrigger"
          @mask-trigger="onMaskTrigger"
          @assist-trigger="onAssistTrigger"
          @user-input-change="onUserInputChange"
          @familiar-skip="onFamiliarSkip"
          @skip="onSkip"
      />
    </div>

    <div class="actions">
      <nut-button shape="square" type="info" @pointerdown.prevent="tap('tapLeft')">
        {{ labels.left }}
      </nut-button>
      <nut-button shape="square" type="info" @pointerdown.prevent="tap('tapMiddle')">
        {{ labels.middle }}
      </nut-button>
      <nut-button shape="square" type="info" @pointerdown.prevent="tap('tapRight')">
        {{ labels.right }}
      </nut-button>
    </div>
  </div>
</template>
<script setup lang="ts">
import {onMounted, onUnmounted, ref, inject, Ref, reactive, computed, nextTick, watch} from 'vue';
import {client, Request, Response} from '../../api/ws.ts';
import {Path} from '../../utils/constant.ts';
import {raiseSoftKeyboard} from '../../utils/keyboard.ts';
import Typing from '../../component/typing.vue';
import {useStore} from "vuex";
import {useI18n} from "vue-i18n";
import {Ask, Voice, Eye, Del} from '@nutui/icons-vue';
import {showToast} from "@nutui/nutui";
import {parseKeySpecs, specsHaveChar, specsOverlap, formatKeySpecsDisplay} from '../../utils/keyTrigger.ts';
import {connectedGamepadIds, gamepadAvailability, gamepadKeyName, watchGamepadPress} from '../../utils/gamepad.ts';

const {t} = useI18n();
const store = useStore();

type ProfileConfig = Record<string, any>;

// 一条"辅助触控触发键"绑定：按下 key 就执行 App 辅助触控里 action 对应的按钮。
// name 是选中那一刻的动作名快照，动作被删掉后拿不到真名时用它显示。
// wordAsk=true 的那种是"单词提问并朗读"：action 只能挑联网动作，把光标所在的词标上下划线当 input1 去问，
// 问到的结果再用 read 那个朗读动作读出来（read 为空就只存不读），readName 是它的名字快照。
// 除此之外跟普通绑定完全一样（同一个列表、同一行 UI）。
type AssistiveTouchBinding = {
  key: string;
  action: string;
  name: string;
  wordAsk: boolean;
  read: string;
  readName: string;
};

const activeProfile = ref(0);
const profileNames = ref<string[]>(['1', '2', '3']);
const profiles = ref<ProfileConfig[]>([]); // 本地缓存全部槽位，切换 profile 时不用重新请求
// 玩家端实际在用的槽位（服务端按 userId 记的，没挑过就是 activeProfile）。
// activeProfile 只是管理员面板正在编辑的那套，两者各管各的。
const playerProfile = ref(0);
const playerProfilePickerVisible = ref(false);

const ignoreCase = ref(false);
const ignorePunctuation = ref(false);
const ignoreNumber = ref(true);
const speakLetters = ref(false);
const speakWord = ref(true);
const manualPlayTrigger = ref('.');
const spellPlayTrigger = ref(',');
// 手动播放/逐字母朗读用哪个「朗读」动作的 TTS 配置（'custom:<动作id>'，空串 = 默认音色）。
// name 是选中那一刻的动作名快照，动作被删掉后拿不到真名时用它显示，跟辅助触控绑定一个套路。
const manualPlayAction = ref('');
const manualPlayActionName = ref('');
const spellPlayAction = ref('');
const spellPlayActionName = ref('');
// 自动朗读那两处（逐字母、打完整词）也各挑一套，存法跟上面两个一样
const speakLettersAction = ref('');
const speakLettersActionName = ref('');
const speakWordAction = ref('');
const speakWordActionName = ref('');
// 熟词的手动播放用哪一套（跟其它几行一样，空串 = 默认音色）
const familiarPlayAction = ref('');
const familiarPlayActionName = ref('');
// 熟词的打完整词朗读用哪一套
const speakWordFamiliarAction = ref('');
const speakWordFamiliarActionName = ref('');
// 熟词跳过成功时念整词用哪一套
const familiarSkipAction = ref('');
const familiarSkipActionName = ref('');
// 跳过键成功时念整词用哪一套，生词、熟词各一套
const skipAction = ref('');
const skipActionName = ref('');
const skipFamiliarAction = ref('');
const skipFamiliarActionName = ref('');
// 各处朗读设置的统一描述：key 是存进 profile 的字段名，读配置/存配置/刷新名字快照都按它走
type TtsActionSlot = { key: string; action: Ref<string>; name: Ref<string> };
const ttsActionSlots: TtsActionSlot[] = [
  {key: 'manualPlayAction', action: manualPlayAction, name: manualPlayActionName},
  {key: 'spellPlayAction', action: spellPlayAction, name: spellPlayActionName},
  {key: 'speakLettersAction', action: speakLettersAction, name: speakLettersActionName},
  {key: 'speakWordAction', action: speakWordAction, name: speakWordActionName},
  {key: 'familiarPlayAction', action: familiarPlayAction, name: familiarPlayActionName},
  {key: 'speakWordFamiliarAction', action: speakWordFamiliarAction, name: speakWordFamiliarActionName},
  {key: 'familiarSkipAction', action: familiarSkipAction, name: familiarSkipActionName},
  {key: 'skipAction', action: skipAction, name: skipActionName},
  {key: 'skipFamiliarAction', action: skipFamiliarAction, name: skipFamiliarActionName},
];
const spellResetLevel = ref(false);
const hintTrigger = ref(' ');
const maskTrigger = ref('');
const dimOnMask = ref(false);
const immersiveOnMask = ref(true);
const deleteTrigger = ref('');
// 熟词跳过键：空串 = 不启用
const familiarSkipTrigger = ref('');
// 跳过键：空串 = 不启用
const skipTrigger = ref('');
// 各触发键最后一次成功保存的值，用于校验失败时把输入框还原回去
let manualPlayTriggerSaved = '.';
let spellPlayTriggerSaved = ',';
let hintTriggerSaved = ' ';
let maskTriggerSaved = '';
let deleteTriggerSaved = '';
let familiarSkipTriggerSaved = '';
let skipTriggerSaved = '';
const keyMapping = ref('');
// 熟词阈值：每个字母允许的毫秒数，0 = 关闭。familiarMsInput 是输入框里的字符串，familiarMs 是判定用的数值
const familiarMs = ref(0);
const familiarMsInput = ref('0');
// 熟词有效期（天）：0 = 不过期。全局一份，不跟 profile 走。过期判定在服务端 familiarQuery 里做（进库时间就是 kv 的值）
const familiarExpireDays = ref(0);
const assistiveTouchBindings = ref<AssistiveTouchBinding[]>([]);
// 每条绑定最后一次成功保存的键，校验失败时用来还原对应的输入框
let bindingKeysSaved: string[] = [];
// 单词提问以前是独立的一条配置（profile.wordAskTrigger），现在并进了 assistiveTouchBindings。
// 这里记住哪些 profile 是从老配置迁上来的，等它们下次真的保存绑定时顺手把老字段清掉。
const legacyWordAskProfiles = new Set<number>();
// 新增绑定时的类型选择弹层
const bindingTypeVisible = ref(false);
// App 辅助触控当前显示的按钮，只有管理员打开设置面板时才会去拉
const assistiveTouchOptions = ref<{ id: string; name: string; type?: string }[]>([]);
const ignoreContentIndexes = ref<number[]>([]);
const adminEnable = ref(false);
const adminId = ref(0);
const content = ref('');
const typingRef = ref<InstanceType<typeof Typing>>();
// 遮挡有三档，maskTrigger（或 Eye 图标）按一下往下轮转一档：
// black = 整屏全黑；typed = 只显示已经打出来的内容（下面的按钮、信息栏照常可见）；off = 不遮。
type MaskMode = 'black' | 'typed' | 'off';
const maskModeOrder: MaskMode[] = ['black', 'typed', 'off'];
const maskMode = ref<MaskMode>('off');
// 全黑那一档才铺遮罩层，另外两档屏幕是能看见的
const eyesClosedMaskVisible = computed(() => maskMode.value === 'black');
const labels = reactive({
  left: '',
  middle: '',
  right: ''
});

const overlayVisible = inject<Ref<boolean>>('overlayVisible')!;
const tipDialogVisible = inject<Ref<boolean>>('tipDialogVisible')!
const tipDialogContent = inject<Ref<string>>('tipDialogContent')!

const ready = computed(() => {
  return adminId.value !== 0;
});
const cantPlayForMaintain = computed(() => {
  return adminEnable.value && adminId.value != store.getters.currentUserId;
});

const isAdmin = computed(() => {
  return adminEnable.value && adminId.value == store.getters.currentUserId;
});

// ---- 多人：各打各的，全都打完才换下一句 ----
// 每个人只在自己设备上打，互相不同步进度。打完一句就告诉服务端，服务端等在线玩家都打完了
// 才换下一句（换句后广播 gameRefresh，大家一起 refresh）。单人时打完立刻换，零等待。
// roundId: 当前这一句的轮次（Game.answer 带回来），打完上报时带上，服务端据此丢掉迟到的请求
let roundId = -1;
// 自己打完了、还在等的人的名字；空数组 = 没在等
const waitingNames = ref<string[]>([]);
let waitingTimer: ReturnType<typeof setTimeout> | null = null;
// 等人时隔多久再问一次服务端：有人掉线了就不用再等他，名单也顺便刷新
const WAITING_POLL_MS = 3000;

const stopWaiting = () => {
  if (waitingTimer !== null) {
    clearTimeout(waitingTimer);
    waitingTimer = null;
  }
  waitingNames.value = [];
};

// sentRoundId 是"打完的是哪一句"，必须在打完那一刻取，不能等发请求时再读 roundId：
// 中间要是已经换句，读到的就是新一句，等于把还没打的新句报成打完了。
const reportComplete = async (sentRoundId: number) => {
  waitingTimer = null;
  const req = new Request({
    path: Path.game,
    headers: {'jsMethod': 'Game.complete'},
    data: {roundId: sentRoundId},
  });
  const res = await client.node!.send(req);
  // 等的这段时间里已经换句了（gameRefresh 先到），这条回包作废
  if (sentRoundId !== roundId) return;
  if (res.error) {
    showToast.fail(res.error);
    return;
  }
  if (res.data?.stale) {
    // 服务端已经在下一句了，只是 gameRefresh 没收到（比如锁屏期间），自己拉一次
    await refresh();
    return;
  }
  const waiting: string[] = Array.isArray(res.data?.waiting) ? res.data.waiting : [];
  waitingNames.value = waiting;
  if (waiting.length > 0) {
    waitingTimer = setTimeout(() => void reportComplete(sentRoundId), WAITING_POLL_MS);
  }
  // waiting 为空说明服务端已经换句，等 gameRefresh 推过来就行
};

// 打字进度上报给服务端落盘，退出 App 再进来能接着打。后台动作：同一时刻最多一条在路上，
// 敲字期间的中间态被合并成最新那一份，敲字链路上不 await。
let savingInput = false;
let pendingSave: { roundId: number; userInput: string } | null = null;

const saveInput = async () => {
  if (savingInput || !pendingSave) return;
  savingInput = true;
  const payload = pendingSave;
  pendingSave = null;
  try {
    const req = new Request({
      path: Path.game,
      headers: {'jsMethod': 'Game.saveInput'},
      data: payload,
    });
    await client.node!.send(req);
  } catch (error) {
    console.error('Failed to save typing input:', error);
  } finally {
    savingInput = false;
    if (pendingSave) void saveInput();
  }
};

const onUserInputChange = (userInput: string, changedIndexes: number[]) => {
  // 退格 / 清词（changedIndexes 为空）：正在计时的这个词重来一遍不算数
  if (changedIndexes.length === 0) {
    familiarTrack = null;
  }
  pendingSave = {roundId, userInput};
  void saveInput();
};


// 设置项的说明塞在 cell 的 desc 里会把整行撑得很高，
// 统一改成标题旁一个"?"，点了才弹说明
const showHelp = (text: string) => {
  tipDialogContent.value = text;
  tipDialogVisible.value = true;
};

const showTips = () => {

  const formatStatus = (val: boolean) => val ? t('enabled') : t('disabled');

  const rows = [
    {label: t('familiarExpireDays'), value: familiarExpireDays.value > 0 ? `${familiarExpireDays.value}` : t('familiarExpireNever')},
    {label: t('profile'), value: profileNames.value[isAdmin.value ? activeProfile.value : playerProfile.value]},
    {label: t('ignoreCase'), value: formatStatus(ignoreCase.value)},
    {label: t('ignorePunctuation'), value: formatStatus(ignorePunctuation.value)},
    {label: t('ignoreNumber'), value: formatStatus(ignoreNumber.value)},
    {label: t('speakLetters'), value: `${formatStatus(speakLetters.value)} \u2192 ${voiceSummary('speakLetters')}`},
    {label: t('speakWord'), value: `${formatStatus(speakWord.value)} \u2192 ${voiceSummary('speakWord')}`},
    {label: t('manualPlayTrigger'), value: `${formatTriggerKey(manualPlayTrigger.value)} \u2192 ${voiceSummary('manualPlay')}`},
    {label: t('spellPlayTrigger'), value: `${formatTriggerKey(spellPlayTrigger.value)} \u2192 ${voiceSummary('spellPlay')}`},
    {label: t('spellResetLevel'), value: formatStatus(spellResetLevel.value)},
    {label: t('hintTrigger'), value: formatTriggerKey(hintTrigger.value)},
    {label: t('maskTrigger'), value: maskTrigger.value ? formatTriggerKey(maskTrigger.value) : t('disabled')},
    {label: t('dimOnMask'), value: formatStatus(dimOnMask.value)},
    {label: t('immersiveOnMask'), value: formatStatus(immersiveOnMask.value)},
    {label: t('deleteTrigger'), value: deleteTrigger.value ? formatTriggerKey(deleteTrigger.value) : t('disabled')},
    {label: t('keyMapping'), value: keyMapping.value || t('disabled')},
    {label: t('familiarMs'), value: familiarMs.value > 0 ? `${familiarMs.value}ms` : t('disabled')},
    {label: t('familiarSkipTrigger'), value: familiarSkipTrigger.value ? `${formatTriggerKey(familiarSkipTrigger.value)} \u2192 ${voiceSummary('familiarSkip')}` : t('disabled')},
    {label: t('skipTrigger'), value: skipTrigger.value ? `${formatTriggerKey(skipTrigger.value)} \u2192 ${voiceSummary('skip')}` : t('disabled')}
  ];

  // 绑定是变长的，一条一行；一条都没配就显示"未启用"
  if (assistiveTouchBindings.value.length === 0) {
    rows.push({label: t('assistiveTouchTrigger'), value: t('disabled')});
  } else {
    for (const binding of assistiveTouchBindings.value) {
      const key = binding.key ? formatTriggerKey(binding.key) : t('disabled');
      const label = binding.wordAsk ? t('wordAskTrigger') : t('assistiveTouchTrigger');
      const read = binding.wordAsk ? ` → ${readActionName(binding)}` : '';
      rows.push({label: label, value: `${key} → ${bindingActionName(binding)}${read}`});
    }
  }

  let html = `<div style="display: flex; flex-direction: column; gap: 10px; text-align: left;">`;

  html += rows.map((row, index) => {
    const isLast = index === rows.length - 1;
    const borderStyle = isLast ? '' : 'border-bottom: 1px solid rgba(128,128,128,0.15);';

    return `
      <div style="display: flex; justify-content: space-between; align-items: center; padding-bottom: ${isLast ? '0' : '6px'}; ${borderStyle}">
        <b style="font-size: 14px;">${row.label}</b>
        <span style="font-size: 14px; opacity: 0.8;">${row.value}</span>
      </div>
    `.replace(/\n/g, '');
  }).join('');

  html += `</div>`;

  tipDialogContent.value = html;
  tipDialogVisible.value = true;
};
const getLabel = async () => {
  const req = new Request({
    path: Path.game,
    headers: {'jsMethod': 'Game.label'},
  });
  const res = await client.node!.send(req);

  labels.left = res.data.left;
  labels.middle = res.data.middle;
  labels.right = res.data.right;
};

// 把 profiles.value[index] 的各字段套用到现有的独立 ref 上（切换 profile / 初次加载都走这里）
const applyProfile = (index: number) => {
  const res = profiles.value[index] || {};
  ignorePunctuation.value = res['ignorePunctuation'];
  ignoreNumber.value = typeof res['ignoreNumber'] === 'boolean' ? res['ignoreNumber'] : true;
  ignoreCase.value = res['ignoreCase'];
  speakLetters.value = typeof res['speakLetters'] === 'boolean' ? res['speakLetters'] : false;
  speakWord.value = typeof res['speakWord'] === 'boolean' ? res['speakWord'] : true;
  manualPlayTrigger.value = typeof res['manualPlayTrigger'] === 'string' ? res['manualPlayTrigger'] : '.';
  spellPlayTrigger.value = typeof res['spellPlayTrigger'] === 'string' ? res['spellPlayTrigger'] : ',';
  for (const slot of ttsActionSlots) {
    const raw = res[slot.key];
    slot.action.value = typeof raw?.action === 'string' ? raw.action : '';
    slot.name.value = typeof raw?.name === 'string' ? raw.name : '';
  }
  // 熟词的整词朗读是后加的：老配置里没有这个字段时沿用生词那一套，熟词听到的声音跟以前一样
  if (typeof res['speakWordFamiliarAction']?.action !== 'string') {
    speakWordFamiliarAction.value = speakWordAction.value;
    speakWordFamiliarActionName.value = speakWordActionName.value;
  }
  // 熟词跳过以前用的是手动播放的熟词那一套，老配置没有这个字段时照旧
  if (typeof res['familiarSkipAction']?.action !== 'string') {
    familiarSkipAction.value = familiarPlayAction.value;
    familiarSkipActionName.value = familiarPlayActionName.value;
  }
  spellResetLevel.value = typeof res['spellResetLevel'] === 'boolean' ? res['spellResetLevel'] : false;
  hintTrigger.value = typeof res['hintTrigger'] === 'string' ? res['hintTrigger'] : ' ';
  maskTrigger.value = typeof res['maskTrigger'] === 'string' ? res['maskTrigger'] : '';
  dimOnMask.value = typeof res['dimOnMask'] === 'boolean' ? res['dimOnMask'] : false;
  immersiveOnMask.value = typeof res['immersiveOnMask'] === 'boolean' ? res['immersiveOnMask'] : true;
  deleteTrigger.value = typeof res['deleteTrigger'] === 'string' ? res['deleteTrigger'] : '';
  familiarSkipTrigger.value = typeof res['familiarSkipTrigger'] === 'string' ? res['familiarSkipTrigger'] : '';
  skipTrigger.value = typeof res['skipTrigger'] === 'string' ? res['skipTrigger'] : '';
  manualPlayTriggerSaved = manualPlayTrigger.value;
  spellPlayTriggerSaved = spellPlayTrigger.value;
  hintTriggerSaved = hintTrigger.value;
  maskTriggerSaved = maskTrigger.value;
  deleteTriggerSaved = deleteTrigger.value;
  familiarSkipTriggerSaved = familiarSkipTrigger.value;
  skipTriggerSaved = skipTrigger.value;
  keyMapping.value = typeof res['keyMapping'] === 'string' ? res['keyMapping'] : '';
  familiarMs.value = typeof res['familiarMs'] === 'number' && res['familiarMs'] > 0 ? res['familiarMs'] : 0;
  familiarMsInput.value = `${familiarMs.value}`;
  const rawBindings = Array.isArray(res['assistiveTouchBindings']) ? res['assistiveTouchBindings'] : [];
  assistiveTouchBindings.value = rawBindings.map((b: any) => ({
    key: typeof b?.key === 'string' ? b.key : '',
    action: typeof b?.action === 'string' ? b.action : '',
    name: typeof b?.name === 'string' ? b.name : '',
    wordAsk: b?.wordAsk === true,
    read: typeof b?.read === 'string' ? b.read : '',
    readName: typeof b?.readName === 'string' ? b.readName : '',
  }));
  // 老配置里单词提问是独立的一条，配过键就迁成列表里的一条 wordAsk 绑定。
  // 这里只改内存，不主动回写（玩家端也会走到这里，不该由它写配置）；
  // 等管理员下次改绑定时 saveAssistiveTouchBindings 会把老字段一并清掉。
  const rawWordAsk = res['wordAskTrigger'];
  if (typeof rawWordAsk?.key === 'string' && rawWordAsk.key !== '') {
    assistiveTouchBindings.value.push({
      key: rawWordAsk.key,
      action: typeof rawWordAsk.action === 'string' ? rawWordAsk.action : '',
      name: typeof rawWordAsk.name === 'string' ? rawWordAsk.name : '',
      wordAsk: true,
      read: '',
      readName: '',
    });
    legacyWordAskProfiles.add(index);
  }
  bindingKeysSaved = assistiveTouchBindings.value.map((b) => b.key);
};

// 找出绑定当前对应的按钮。返回 undefined 说明这个按钮已经不在辅助触控里了
// （自定义预设被删、内置动作被移出悬浮球、或当前复习模式下不可用）。
const findOption = (action: string) => assistiveTouchOptions.value.find((o) => o.id === action);

// 绑定行上显示的动作名：按钮还在就用 App 返回的真名，不在就用快照并标记已失效。
// 玩家端不拉按钮列表（options 为空），此时不做失效判断，直接显示快照。
const bindingActionName = (binding: AssistiveTouchBinding) => {
  if (assistiveTouchOptions.value.length === 0) {
    return binding.name;
  }
  const option = findOption(binding.action);
  return option ? option.name : `${t('assistiveTouchActionMissing')} ${binding.name}`;
};

// 每条绑定的下拉候选项。绑定的按钮已经不在列表里时，额外插一条"已失效"占位，
// 否则下拉会显示成空白，用户看不出原来绑的是什么。
// 必须用 computed 缓存出稳定的数组引用，不能在模板里现算：nut-menu 的标题依赖 nut-menu-item
// 的 props，每次渲染都传一个新数组会让两者互相触发更新，直接抛 Maximum recursive updates 把页面刷黑。
const bindingOptionList = computed(() => assistiveTouchBindings.value.map((binding) => {
  // 单词提问并朗读只能挑联网动作（type 'n'）：问到的结果要存进它的作用位置
  const options = assistiveTouchOptions.value
      .filter((o) => !binding.wordAsk || o.type === 'n')
      .map((o) => ({text: o.name, value: o.id}));
  if (binding.action && !findOption(binding.action)) {
    options.unshift({text: bindingActionName(binding), value: binding.action});
  }
  return options;
}));

// 绑定动作的二级弹层：没有可选按钮、也没绑过东西时点了没意义，小字退成普通灰字
const bindingPickable = (index: number) => (bindingOptionList.value[index]?.length ?? 0) > 0;
// 同一个弹层两用：挑绑定的动作（action），或者挑单词提问并朗读的朗读动作（read）
const bindingPickerVisible = ref(false);
const bindingPickerIndex = ref(0);
const bindingPickerRead = ref(false);
const bindingPickerAction = computed(() => {
  const binding = assistiveTouchBindings.value[bindingPickerIndex.value];
  return (bindingPickerRead.value ? binding?.read : binding?.action) ?? '';
});
const bindingPickerTitle = computed(() => {
  if (!assistiveTouchBindings.value[bindingPickerIndex.value]?.wordAsk) {
    return t('assistiveTouchTrigger');
  }
  return `${t('wordAskTrigger')} · ${bindingPickerRead.value ? t('wordAskRead') : t('wordAskNet')}`;
});
const bindingPickerOptions = computed(() => bindingPickerRead.value
    ? readOptionList.value[bindingPickerIndex.value] ?? []
    : bindingOptionList.value[bindingPickerIndex.value] ?? []);
const openBindingPicker = (index: number) => {
  if (!bindingPickable(index)) return;
  bindingPickerIndex.value = index;
  bindingPickerRead.value = false;
  bindingPickerVisible.value = true;
};
const openReadPicker = (index: number) => {
  if (!readPickable(index)) return;
  bindingPickerIndex.value = index;
  bindingPickerRead.value = true;
  bindingPickerVisible.value = true;
};
const onPickBinding = (value: string) => {
  if (bindingPickerRead.value) {
    setBindingRead(bindingPickerIndex.value, value);
  } else {
    setBindingAction(bindingPickerIndex.value, value);
  }
};

// 朗读动作那一行显示的名字：没选是"不朗读"，选的动作已经不在了就用快照并标记已失效
const readActionName = (binding: AssistiveTouchBinding) => {
  if (!binding.read) {
    return t('wordAskNoRead');
  }
  if (assistiveTouchOptions.value.length === 0) {
    return binding.readName;
  }
  const option = findOption(binding.read);
  return option ? option.name : `${t('assistiveTouchActionMissing')} ${binding.readName}`;
};
// 朗读动作候选：「不朗读」+ 所有朗读动作；跟 bindingOptionList 一样要 computed 保持引用稳定
const readOptionList = computed(() => assistiveTouchBindings.value.map((binding) => {
  const options = [{text: t('wordAskNoRead'), value: ''}, ...ttsActionOptions.value];
  if (binding.read && !options.some((o) => o.value === binding.read)) {
    options.push({text: readActionName(binding), value: binding.read});
  }
  return options;
}));
const readPickable = (index: number) => ttsActionOptions.value.length > 0
    || (assistiveTouchBindings.value[index]?.read ?? '') !== '';

// 朗读设置下拉里能选的：「默认音色」+ 辅助触控里所有「朗读」类型的动作。
// 玩家端不拉按钮列表（options 为空），这时只有"默认音色"一条。
const ttsActionOptions = computed(() => assistiveTouchOptions.value
    .filter((o) => o.type === 't')
    .map((o) => ({text: o.name, value: o.id})));

// 一行上显示的朗读动作名。没选是"默认音色"；选的动作已经不在了就用快照并标记已失效。
const ttsActionName = (action: string, name: string) => {
  if (!action) {
    return t('ttsActionDefault');
  }
  // 玩家端不拉按钮列表（options 为空），此时不做失效判断，直接显示快照
  if (assistiveTouchOptions.value.length === 0) {
    return name || t('ttsActionDefault');
  }
  const option = findOption(action);
  if (option) {
    return option.name;
  }
  return name ? `${t('assistiveTouchActionMissing')} ${name}` : t('assistiveTouchActionMissing');
};

// 跟 bindingOptionList 同理必须用 computed 缓存稳定引用，现算会把 nut-menu 刷进递归更新。
// 选中的动作不在候选里（被删/改成了别的类型）时补一条占位，否则下拉显示成空白。
const ttsOptionListOf = (action: string, name: string) => {
  const options = [{text: t('ttsActionDefault'), value: ''}, ...ttsActionOptions.value];
  if (action && !options.some((o) => o.value === action)) {
    options.push({text: ttsActionName(action, name), value: action});
  }
  return options;
};
// 会出声的每一行各有哪几套音色：title 是这一行的标题，groups 里 tag 是"生词/熟词/字母"标注
type VoiceRow = 'manualPlay' | 'familiarSkip' | 'skip' | 'spellPlay' | 'speakLetters' | 'speakWord';
const slotOf = (key: string) => ttsActionSlots.find((slot) => slot.key === key)!;
const voiceRows: Record<VoiceRow, { title: string; groups: { tag: string; slot: TtsActionSlot }[] }> = {
  manualPlay: {
    title: 'manualPlayTrigger',
    groups: [{tag: 'ttsTagNew', slot: slotOf('manualPlayAction')}, {tag: 'ttsTagFamiliar', slot: slotOf('familiarPlayAction')}],
  },
  familiarSkip: {title: 'familiarSkipTrigger', groups: [{tag: 'ttsTagFamiliar', slot: slotOf('familiarSkipAction')}]},
  skip: {
    title: 'skipTrigger',
    groups: [{tag: 'ttsTagNew', slot: slotOf('skipAction')}, {tag: 'ttsTagFamiliar', slot: slotOf('skipFamiliarAction')}],
  },
  spellPlay: {title: 'spellPlayTrigger', groups: [{tag: 'ttsTagLetter', slot: slotOf('spellPlayAction')}]},
  speakLetters: {title: 'speakLetters', groups: [{tag: 'ttsTagLetter', slot: slotOf('speakLettersAction')}]},
  speakWord: {
    title: 'speakWord',
    groups: [{tag: 'ttsTagNew', slot: slotOf('speakWordAction')}, {tag: 'ttsTagFamiliar', slot: slotOf('speakWordFamiliarAction')}],
  },
};
// 设置行第二行的小字，比如"生词: 默认音色 · 熟词: 美音慢速"
const voiceSummary = (row: VoiceRow) => voiceRows[row].groups
    .map((g) => `${t(g.tag)}: ${ttsActionName(g.slot.action.value, g.slot.name.value)}`)
    .join(' · ');
// 没有「朗读」动作可选时二级里只有"默认音色"一项，点进去没意义，小字就退成普通灰字；
// 但这一行还挂着一个已失效的动作时仍然能点，好把它改回默认音色
const voicePickable = (row: VoiceRow) => ttsActionOptions.value.length > 0
    || voiceRows[row].groups.some((g) => g.slot.action.value !== '');
const voiceLinkClass = (row: VoiceRow) => voicePickable(row) ? 'voice-link' : 'voice-text';
const voicePickerVisible = ref(false);
const voicePickerRow = ref<VoiceRow | null>(null);
// 选项列表跟 ttsOptionListOf 的老规矩一样放进 computed，保持引用稳定
const voicePickerGroups = computed(() => (voicePickerRow.value ? voiceRows[voicePickerRow.value].groups : [])
    .map((g) => ({...g, options: ttsOptionListOf(g.slot.action.value, g.slot.name.value)})));
const openVoicePicker = (row: VoiceRow) => {
  if (!voicePickable(row)) return;
  voicePickerRow.value = row;
  voicePickerVisible.value = true;
};

const getAssistiveTouchActions = async () => {
  try {
    const req = new Request({
      path: Path.game,
      headers: {'jsMethod': 'Game.assistiveTouchActions'},
    });
    const res = await client.node!.send(req);
    assistiveTouchOptions.value = Array.isArray(res.data) ? res.data : [];
    // 自定义预设改名后 id 不变，绑定仍然有效，顺手把快照刷新成新名字
    let changed = false;
    for (const binding of assistiveTouchBindings.value) {
      const option = findOption(binding.action);
      if (option && option.name !== binding.name) {
        binding.name = option.name;
        changed = true;
      }
      const readOption = binding.read ? findOption(binding.read) : undefined;
      if (readOption && readOption.name !== binding.readName) {
        binding.readName = readOption.name;
        changed = true;
      }
    }
    if (changed) {
      saveAssistiveTouchBindings();
    }
    // 朗读动作改名后 id 不变，同样把快照刷成新名字
    for (const slot of ttsActionSlots) {
      const option = findOption(slot.action.value);
      if (option && option.name !== slot.name.value) {
        setTtsAction(slot, slot.action.value);
      }
    }
  } catch (error) {
    console.error('Failed to get assistive touch actions:', error);
  }
};

const getConfig = async () => {
  const req = new Request({
    path: Path.game,
    headers: {'jsMethod': 'Game.getConfig'},
  });
  const res0 = await client.node!.send(req);
  const res = res0.data;
  activeProfile.value = typeof res['activeProfile'] === 'number' ? res['activeProfile'] : 0;
  profileNames.value = Array.isArray(res['profileNames']) ? res['profileNames'] : ['1', '2', '3'];
  profiles.value = Array.isArray(res['profiles']) ? res['profiles'] : [];
  playerProfile.value = typeof res['myProfile'] === 'number' ? res['myProfile'] : activeProfile.value;
  familiarExpireDays.value = typeof res['familiarExpireDays'] === 'number' ? res['familiarExpireDays'] : 0;
  // 依赖 isAdmin，所以 onMounted 里必须先 getAdmin 再 getConfig
  applyProfile(isAdmin.value ? activeProfile.value : playerProfile.value);
  // 上次停在哪一档就接着用；要在 applyProfile 之后，亮度/系统栏得按这套 profile 的 dimOnMask 等开关来
  const savedMaskMode = res['myMaskMode'];
  if (maskModeOrder.includes(savedMaskMode)) {
    maskMode.value = savedMaskMode;
    if (savedMaskMode !== 'off') {
      applyMaskUi(savedMaskMode);
    }
  }
};
const getAdmin = async () => {
  const req = new Request({
    path: Path.gameAdmin,
  });
  const res0 = await client.node!.send(req);
  const admin = res0.data;
  adminEnable.value = admin.adminEnable;
  adminId.value = admin.adminId;
};

const tap = async (event: String) => {
  const req = new Request({
    path: Path.game,
    headers: {'jsMethod': 'Game.tap'},
    data: event,
  });
  await client.node!.send(req);
  if (event == 'tapLeft') {
    await refresh();
  }
};

// 每个 setXxx 除了持久化到服务端，还要同步更新本地缓存的 profiles.value[activeProfile]，
// 这样切换到别的 profile 再切回来，不用重新请求就能看到刚才改过的值
const setIgnoreCase = (value: boolean) => {
  profiles.value[activeProfile.value].ignoreCase = value;
  setConfig("ignoreCase", value);
};
const setIgnorePunctuation = (value: boolean) => {
  profiles.value[activeProfile.value].ignorePunctuation = value;
  setConfig("ignorePunctuation", value);
};
const setIgnoreNumber = (value: boolean) => {
  profiles.value[activeProfile.value].ignoreNumber = value;
  setConfig("ignoreNumber", value);
};
const setSpeakLetters = (value: boolean) => {
  profiles.value[activeProfile.value].speakLetters = value;
  setConfig("speakLetters", value);
};
const setSpeakWord = (value: boolean) => {
  profiles.value[activeProfile.value].speakWord = value;
  setConfig("speakWord", value);
};
// 所有触发键（四个固定的 + 任意条辅助触控绑定）不能互相重复，比如手动播放和逐字母朗读不能都设成 '.'。
// exclude 是"正在改的那一个"（固定键用名字，绑定用下标），要排除掉，否则改成原值也会判成冲突。
type TriggerOwner = 'manualPlay' | 'spellPlay' | 'hint' | 'mask' | 'delete' | 'familiarSkip' | 'skip' | number;
const isKeyTaken = (value: string, exclude: TriggerOwner) => {
  const specs = parseKeySpecs(value);
  if (specs.length === 0) {
    return false; // 空值表示不启用，不参与冲突判断
  }
  const others: string[] = [];
  if (exclude !== 'manualPlay') others.push(manualPlayTrigger.value);
  if (exclude !== 'spellPlay') others.push(spellPlayTrigger.value);
  if (exclude !== 'hint') others.push(hintTrigger.value);
  if (exclude !== 'mask') others.push(maskTrigger.value);
  if (exclude !== 'delete') others.push(deleteTrigger.value);
  if (exclude !== 'familiarSkip') others.push(familiarSkipTrigger.value);
  if (exclude !== 'skip') others.push(skipTrigger.value);
  assistiveTouchBindings.value.forEach((b, i) => {
    if (exclude !== i) others.push(b.key);
  });
  return others.some((raw) => specsOverlap(specs, parseKeySpecs(raw)));
};

// 触发键输入框旁的"是否含空格键"提示：配置里任意一个按键是空格时都要提示，不然用户看不出来
const hasSpaceKey = (raw: string) => specsHaveChar(parseKeySpecs(raw), ' ');

// 冲突时提示并把输入框还原成上一次成功保存的值
const setManualPlayTrigger = (value: string) => {
  if (isKeyTaken(value, 'manualPlay')) {
    showToast.warn(t('triggerKeyConflict'));
    manualPlayTrigger.value = manualPlayTriggerSaved;
    return;
  }
  manualPlayTriggerSaved = value;
  profiles.value[activeProfile.value].manualPlayTrigger = value;
  setConfig("manualPlayTrigger", value);
};
const setSpellPlayTrigger = (value: string) => {
  if (isKeyTaken(value, 'spellPlay')) {
    showToast.warn(t('triggerKeyConflict'));
    spellPlayTrigger.value = spellPlayTriggerSaved;
    return;
  }
  spellPlayTriggerSaved = value;
  profiles.value[activeProfile.value].spellPlayTrigger = value;
  setConfig("spellPlayTrigger", value);
};
// 选中的朗读动作连同名字快照一起存：动作以后被删了，界面上还能看出原来绑的是哪个。
const setTtsAction = (slot: TtsActionSlot, value: string) => {
  slot.action.value = value;
  slot.name.value = findOption(value)?.name ?? '';
  const stored = {action: value, name: slot.name.value};
  profiles.value[activeProfile.value][slot.key] = stored;
  setConfig(slot.key, stored);
};

const setFamiliarSkipTrigger = (value: string) => {
  if (isKeyTaken(value, 'familiarSkip')) {
    showToast.warn(t('triggerKeyConflict'));
    familiarSkipTrigger.value = familiarSkipTriggerSaved;
    return;
  }
  familiarSkipTriggerSaved = value;
  profiles.value[activeProfile.value].familiarSkipTrigger = value;
  setConfig("familiarSkipTrigger", value);
};
const setSkipTrigger = (value: string) => {
  if (isKeyTaken(value, 'skip')) {
    showToast.warn(t('triggerKeyConflict'));
    skipTrigger.value = skipTriggerSaved;
    return;
  }
  skipTriggerSaved = value;
  profiles.value[activeProfile.value].skipTrigger = value;
  setConfig("skipTrigger", value);
};
const setSpellResetLevel = (value: boolean) => {
  profiles.value[activeProfile.value].spellResetLevel = value;
  setConfig("spellResetLevel", value);
};
const setHintTrigger = (value: string) => {
  if (isKeyTaken(value, 'hint')) {
    showToast.warn(t('triggerKeyConflict'));
    hintTrigger.value = hintTriggerSaved;
    return;
  }
  hintTriggerSaved = value;
  profiles.value[activeProfile.value].hintTrigger = value;
  setConfig("hintTrigger", value);
};
const setMaskTrigger = (value: string) => {
  if (isKeyTaken(value, 'mask')) {
    showToast.warn(t('triggerKeyConflict'));
    maskTrigger.value = maskTriggerSaved;
    return;
  }
  maskTriggerSaved = value;
  profiles.value[activeProfile.value].maskTrigger = value;
  setConfig("maskTrigger", value);
};
const setDimOnMask = (value: boolean) => {
  profiles.value[activeProfile.value].dimOnMask = value;
  setConfig("dimOnMask", value);
  // 正闭着眼时改开关：屏幕已经是暗的/系统栏已经藏了，按新设置立刻重下一次，
  // 不然只能靠再闭一次眼才恢复
  if (maskMode.value !== 'off') {
    applyMaskUi(maskMode.value);
  }
};
const setImmersiveOnMask = (value: boolean) => {
  profiles.value[activeProfile.value].immersiveOnMask = value;
  setConfig("immersiveOnMask", value);
  if (maskMode.value !== 'off') {
    applyMaskUi(maskMode.value);
  }
};
const setDeleteTrigger = (value: string) => {
  if (isKeyTaken(value, 'delete')) {
    showToast.warn(t('triggerKeyConflict'));
    deleteTrigger.value = deleteTriggerSaved;
    return;
  }
  deleteTriggerSaved = value;
  profiles.value[activeProfile.value].deleteTrigger = value;
  setConfig("deleteTrigger", value);
};
const setFamiliarExpireDays = (value: number) => {
  familiarExpireDays.value = value;
  setConfig("familiarExpireDays", value);
};
const setFamiliarMs = (value: string) => {
  const parsed = parseInt(value, 10);
  const ms = Number.isFinite(parsed) && parsed > 0 ? parsed : 0;
  familiarMs.value = ms;
  familiarMsInput.value = `${ms}`;
  profiles.value[activeProfile.value].familiarMs = ms;
  setConfig("familiarMs", ms);
};
const setKeyMapping = (value: string) => {
  profiles.value[activeProfile.value].keyMapping = value;
  setConfig("keyMapping", value);
};

// 绑定是变长数组，没法像其它设置那样一个字段一个 setter，统一整份存
const saveAssistiveTouchBindings = () => {
  const value = assistiveTouchBindings.value.map((b) => ({
    key: b.key, action: b.action, name: b.name, wordAsk: b.wordAsk, read: b.read, readName: b.readName,
  }));
  bindingKeysSaved = value.map((b) => b.key);
  profiles.value[activeProfile.value].assistiveTouchBindings = value;
  setConfig("assistiveTouchBindings", value);
  // 这个 profile 的单词提问是从老字段迁上来的：现在列表里已经存下了，把老字段清空，
  // 否则下次 applyProfile 还会再迁一遍，多出一条重复的绑定。
  if (legacyWordAskProfiles.has(activeProfile.value)) {
    legacyWordAskProfiles.delete(activeProfile.value);
    const empty = {key: '', action: '', name: ''};
    profiles.value[activeProfile.value].wordAskTrigger = empty;
    setConfig("wordAskTrigger", empty);
  }
};

const setBindingKey = (index: number, value: string) => {
  const binding = assistiveTouchBindings.value[index];
  if (!binding) {
    return;
  }
  if (isKeyTaken(value, index)) {
    showToast.warn(t('triggerKeyConflict'));
    binding.key = bindingKeysSaved[index] ?? '';
    return;
  }
  binding.key = value;
  saveAssistiveTouchBindings();
};

const setBindingAction = (index: number, action: string) => {
  const binding = assistiveTouchBindings.value[index];
  if (!binding) {
    return;
  }
  binding.action = action;
  const option = findOption(action);
  if (option) {
    binding.name = option.name;
  }
  saveAssistiveTouchBindings();
};

const setBindingRead = (index: number, read: string) => {
  const binding = assistiveTouchBindings.value[index];
  if (!binding) {
    return;
  }
  binding.read = read;
  binding.readName = findOption(read)?.name ?? '';
  saveAssistiveTouchBindings();
};

// 弹层选项的顺序就是 onChooseBindingType 里的下标顺序
const bindingTypeItems = computed(() => [
  {name: t('bindingTypeNormal')},
  {name: t('bindingTypeWordAsk')},
]);

const addBinding = () => {
  bindingTypeVisible.value = true;
};

const onChooseBindingType = (_item: any, index: number) => {
  bindingTypeVisible.value = false;
  const wordAsk = index === 1;
  // 单词提问并朗读只能绑联网动作，默认挑第一个联网动作、朗读动作挑第一个朗读动作
  const first = assistiveTouchOptions.value.find((o) => !wordAsk || o.type === 'n');
  const firstRead = wordAsk ? assistiveTouchOptions.value.find((o) => o.type === 't') : undefined;
  assistiveTouchBindings.value.push({
    key: '',
    action: first ? first.id : '',
    name: first ? first.name : '',
    wordAsk,
    read: firstRead ? firstRead.id : '',
    readName: firstRead ? firstRead.name : '',
  });
  saveAssistiveTouchBindings();
};

const removeBinding = (index: number) => {
  assistiveTouchBindings.value.splice(index, 1);
  saveAssistiveTouchBindings();
};

// "+"弹出的特殊按键选择器：target 标记要往哪个触发键配置里追加，number 表示第几条辅助触控绑定
type KeyPickerTarget = 'manualPlay' | 'spellPlay' | 'hint' | 'mask' | 'delete' | 'familiarSkip' | 'skip' | number;
const keyPickerVisible = ref(false);
const keyPickerTarget = ref<KeyPickerTarget | null>(null);
// 键盘上打不出/不方便打出来的按键，选中后写成 \name 的形式。
// key 是 keydown 事件里的 e.key（大小写不敏感），label 只用于列表展示：
// Mac 上 Option 键的 e.key 也是 'Alt'，所以只有一条配置，展示时把两个名字都写出来。
const specialKeyNames: { key: string; label?: string }[] = [
  {key: 'Enter'}, {key: 'Tab'}, {key: 'Escape'}, {key: 'NumLock'}, {key: 'CapsLock'}, {key: 'Insert'},
  {key: 'Alt', label: 'Alt / Option'}, {key: 'Control'}, {key: 'Shift'}, {key: 'Meta', label: 'Meta / Command'},
  {key: 'Home'}, {key: 'End'}, {key: 'PageUp'}, {key: 'PageDown'},
  {key: 'F1'}, {key: 'F2'}, {key: 'F3'}, {key: 'F4'}, {key: 'F5'}, {key: 'F6'},
  {key: 'F7'}, {key: 'F8'}, {key: 'F9'}, {key: 'F10'}, {key: 'F11'}, {key: 'F12'}];
const specialKeyItems = computed(() => specialKeyNames.map(({key, label}) => ({name: label ?? key, key})));

const keySourceVisible = ref(false);
const keySourceItems = computed(() => [{name: t('keySourceKeyboard')}, {name: t('keySourceGamepad')}]);

const openKeyPicker = (target: KeyPickerTarget) => {
  keyPickerTarget.value = target;
  keySourceVisible.value = true;
};

const onChooseKeySource = (_item: any, index: number) => {
  keySourceVisible.value = false;
  if (index === 0) {
    keyPickerVisible.value = true;
  } else {
    gamepadCaptureVisible.value = true;
  }
};

const appendKeyToken = (current: string, token: string) => current ? `${current}•${token}` : token;

const onChooseSpecialKey = (item: { name: string; key: string }) => {
  keyPickerVisible.value = false;
  appendTokenToTarget(`\\${item.key.toLowerCase()}`);
};

// 手柄录键：弹窗打开期间轮询，第一个按下的键就是要加的键。
// 手柄要在页面里先按一下才会被浏览器暴露出来，所以提示里一直显示当前识别到的手柄。
const gamepadCaptureVisible = ref(false);
const gamepadIds = ref<string[]>([]);
let stopGamepadCapture = () => {};
let gamepadIdTimer = 0;
const gamepadCaptureTip = computed(() => {
  const availability = gamepadAvailability();
  if (availability === 'insecure') return t('gamepadInsecure');
  if (availability === 'unsupported') return t('gamepadUnsupported');
  if (gamepadIds.value.length === 0) return t('gamepadWaiting');
  return t('gamepadPressKey', {name: gamepadIds.value.join(', ')});
});
watch(gamepadCaptureVisible, (visible) => {
  stopGamepadCapture();
  window.clearInterval(gamepadIdTimer);
  if (!visible) return;
  gamepadIds.value = connectedGamepadIds();
  gamepadIdTimer = window.setInterval(() => gamepadIds.value = connectedGamepadIds(), 500);
  stopGamepadCapture = watchGamepadPress((index) => {
    // 同一帧按下多个键时只取第一个；停止轮询要等 watch 回调，这一帧里还会再进来
    if (!gamepadCaptureVisible.value) return;
    gamepadCaptureVisible.value = false;
    appendTokenToTarget(`\\${gamepadKeyName(index)}`);
  });
});

const appendTokenToTarget = (token: string) => {
  const target = keyPickerTarget.value;
  if (target === null) return;
  if (target === 'manualPlay') {
    manualPlayTrigger.value = appendKeyToken(manualPlayTrigger.value, token);
    setManualPlayTrigger(manualPlayTrigger.value);
  } else if (target === 'spellPlay') {
    spellPlayTrigger.value = appendKeyToken(spellPlayTrigger.value, token);
    setSpellPlayTrigger(spellPlayTrigger.value);
  } else if (target === 'hint') {
    hintTrigger.value = appendKeyToken(hintTrigger.value, token);
    setHintTrigger(hintTrigger.value);
  } else if (target === 'mask') {
    maskTrigger.value = appendKeyToken(maskTrigger.value, token);
    setMaskTrigger(maskTrigger.value);
  } else if (target === 'delete') {
    deleteTrigger.value = appendKeyToken(deleteTrigger.value, token);
    setDeleteTrigger(deleteTrigger.value);
  } else if (target === 'familiarSkip') {
    familiarSkipTrigger.value = appendKeyToken(familiarSkipTrigger.value, token);
    setFamiliarSkipTrigger(familiarSkipTrigger.value);
  } else if (target === 'skip') {
    skipTrigger.value = appendKeyToken(skipTrigger.value, token);
    setSkipTrigger(skipTrigger.value);
  } else {
    const binding = assistiveTouchBindings.value[target];
    if (binding) {
      setBindingKey(target, appendKeyToken(binding.key, token));
    }
  }
};

const setActiveProfile = async (index: number) => {
  overlayVisible.value = true;
  try {
    const req = new Request({
      path: Path.game,
      headers: {'jsMethod': 'Game.setActiveProfile'},
      data: index,
    });
    await client.node!.send(req);
    activeProfile.value = index;
    applyProfile(index);
  } finally {
    overlayVisible.value = false;
  }
};

// 1 -> ①，……，20 -> ⑳；超出范围就原样显示数字
const circledNumber = (n: number) => (n >= 1 && n <= 20 ? String.fromCharCode(0x2460 + n - 1) : `${n}`);
const playerProfileItems = computed(() => profileNames.value.map((name, i) => ({
  name: i === playerProfile.value ? `✓ ${name}` : name,
})));

// 玩家切 profile：存到服务端自己名下后，遮罩（忽略标点/数字）、熟词阈值这些服务端按 profile 算的东西
// 都得重新拉一遍，所以走一次 refresh（共享打字进度会在 refresh 里接回来）
const onChoosePlayerProfile = async (_item: any, index: number) => {
  playerProfilePickerVisible.value = false;
  if (index === playerProfile.value) {
    return;
  }
  const req = new Request({
    path: Path.game,
    headers: {'jsMethod': 'Game.selectProfile'},
    data: index,
  });
  const res = await client.node!.send(req);
  if (res.error) {
    showToast.fail(res.error);
    return;
  }
  playerProfile.value = index;
  applyProfile(index);
  await refresh();
  await nextTick();
  typingRef.value?.focus();
};

const setProfileName = async (index: number, name: string) => {
  overlayVisible.value = true;
  try {
    const req = new Request({
      path: Path.game,
      headers: {'jsMethod': 'Game.setProfileName'},
      data: {index, name},
    });
    await client.node!.send(req);
    profileNames.value[index] = name;
  } finally {
    overlayVisible.value = false;
  }
};
const updateIgnoreIndexes = (mask: string) => {
  const indexes: number[] = [];
  for (let i = 0; i < mask.length; i++) {
    if (mask[i] !== '•') indexes.push(i);
  }
  ignoreContentIndexes.value = indexes;
};
const setConfig = async (key: String, value: any) => {
  overlayVisible.value = true;
  const req = new Request({
    path: Path.game,
    headers: {'jsMethod': 'Game.setConfig'},
    data: {key: key, value: value},
  });
  await client.node!.send(req);
  overlayVisible.value = false;
};
// 错误提示音：交给 Dart 原生播放（走系统音频路由，能跟随蓝牙耳机），而不是 WebView 自己的 Web Audio
const playWrongSound = async () => {
  try {
    const req = new Request({
      path: Path.game,
      headers: {'jsMethod': 'Game.playWrong'},
      data: {url: `${window.location.origin}/sounds/wrong.wav`},
    });
    const res = await client.node!.send(req);
    console.log('playWrongSound response:', res);
  } catch (error) {
    console.error('Failed to play wrong sound:', error);
  }
};

// TTS 朗读：串行播放，避免一次自动补全多个字符时同时开口
let speakQueue: Promise<void> = Promise.resolve();
// action 传了就用那个「朗读」动作存的 TTS 配置来读（引擎/音色/语速），读的还是这里的 text
const speak = (text: string, rate?: number, manual?: boolean, action?: string) => {
  if (!text) return speakQueue;
  speakQueue = speakQueue.then(async () => {
    try {
      const req = new Request({
        path: Path.game,
        headers: {'jsMethod': 'Game.tts'},
        data: {text, type: 'a', rate, manual, action},
      });
      await client.node!.send(req);
    } catch (error) {
      console.error('Failed to send tts:', error);
    }
  });
  return speakQueue;
};
const isSpeakable = (ch: string) => /[\p{L}\p{N}]/u.test(ch);

// 触发键配置格式化成人类可读文案：多个按键用 " / " 分隔，空格键额外提示，特殊按键显示成对应名字
const formatTriggerKey = (key: string) => formatKeySpecsDisplay(key, t('spaceKey'));

// ---- 熟词 ----
// 打得够快的词记进熟词库（服务端 GameKv），下次再遇到：光标一到词首就响一声提示音、
// 该词的下划线变紫，敲对首字母整词自动补全；首字母敲错就当场出库，退回正常输入。

// 撇号：I'm 的 m、you're 的 re 都不是完整的词，判断"完整"就看词前面是不是撇号
const APOSTROPHES = "'\u2019\u2018\u00b4";

// 把整句切成"能进熟词库的词"。切词口径跟 Typing 组件的 getWordBounds 一致（一段字母/数字算一个词），
// 在这之上再要求：全是字母、超过一个字母、前面不是撇号。
const familiarCandidates = (text: string): { start: number; end: number; word: string }[] => {
  const ret: { start: number; end: number; word: string }[] = [];
  const re = /[\p{L}\p{N}]+/gu;
  let match: RegExpExecArray | null;
  while ((match = re.exec(text)) !== null) {
    const seg = match[0];
    const start = match.index;
    if (seg.length < 2) continue;                                   // I 这种单字母词不进库
    if (!/^\p{L}+$/u.test(seg)) continue;                           // 带数字的不算单词
    if (start > 0 && APOSTROPHES.includes(text[start - 1])) continue; // 撇号后半截不是完整的词
    ret.push({start, end: start + seg.length - 1, word: seg.toLowerCase()});
  }
  return ret;
};

// 当前这句里已经在熟词库里的词（小写）。每换一句从服务端重新拉，服务端是唯一权威。
const familiarWords = ref<Set<string>>(new Set());
const isFamiliarWord = (word: string) => familiarWords.value.has(word.toLowerCase());

const familiarCandidateByStart = computed(() => {
  const map = new Map<number, { start: number; end: number; word: string }>();
  for (const item of familiarCandidates(content.value)) {
    map.set(item.start, item);
  }
  return map;
});

// 交给 Typing 组件的熟词位置。熟词库是所有 profile 共用的，展示/跳过/挑音色都只看库；
// 阈值只管要不要往库里记新词（阈值为 0 = 不记新词），所以这里不看阈值。
const familiarRanges = computed(() => {
  const ret: { start: number; end: number }[] = [];
  for (const item of familiarCandidateByStart.value.values()) {
    if (familiarWords.value.has(item.word)) ret.push({start: item.start, end: item.end});
  }
  return ret;
});

const loadFamiliar = async () => {
  const words = [...familiarCandidateByStart.value.values()].map((c) => c.word);
  if (words.length === 0) {
    familiarWords.value = new Set();
    return;
  }
  try {
    const req = new Request({
      path: Path.game,
      headers: {'jsMethod': 'Game.familiarQuery'},
      data: {words},
    });
    const res = await client.node!.send(req);
    familiarWords.value = new Set(Array.isArray(res.data?.words) ? res.data.words : []);
  } catch (error) {
    console.error('Failed to query familiar words:', error);
    familiarWords.value = new Set();
  }
};

const markFamiliar = (word: string) => {
  familiarWords.value.add(word);
  const req = new Request({
    path: Path.game,
    headers: {'jsMethod': 'Game.familiarMark'},
    data: {word},
  });
  client.node!.send(req).catch((error) => console.error('Failed to mark familiar word:', error));
};

// 按了熟词跳过键。跳成了就把整词念出来（音色走"熟词朗读"那一行，见 playActionOf）；
// 没跳成（光标所在的词不是熟词、或者已经打完了）就响一声中性提示音，不 await、不开 overlay，
// 别卡打字节奏。
const onFamiliarSkip = (word: string, skipped: boolean) => {
  if (skipped) {
    if (word) speak(word, undefined, true, familiarSkipAction.value);
    return;
  }
  playCueSound();
};

// 按了跳过键：生词熟词都能跳，跳成了按是不是熟词挑"跳过键"那一行的生词/熟词音色念整词；
// 没跳成（光标不在词上、或者词已经打完了）跟熟词跳过一样只响一声提示音。
const onSkip = (word: string, skipped: boolean, familiar: boolean) => {
  if (skipped) {
    if (word) speak(word, undefined, true, familiar ? skipFamiliarAction.value : skipAction.value);
    return;
  }
  playCueSound();
};

const playCueSound = () => {
  const req = new Request({
    path: Path.game,
    headers: {'jsMethod': 'Game.playSound'},
    data: {url: `${window.location.origin}/sounds/cue.wav`},
  });
  client.node!.send(req).catch((error) => console.error('Failed to play cue sound:', error));
};

// 一个词的计时：从第一个字母敲下算到最后一个字母敲下，<= familiarMs * (字母数 - 1) 就算熟。
// apple 5 个字母、阈值 200ms，就是 4 段间隔共 800ms。
// valid=false 表示这一遍不算数（打错过、有字母是自动填出来的、中途退格重来）。
type FamiliarTrack = { start: number; end: number; word: string; letters: number; firstAt: number; valid: boolean };
let familiarTrack: FamiliarTrack | null = null;

const trackFamiliar = (index: number, auto: boolean, correct: boolean) => {
  if (familiarMs.value <= 0) {
    familiarTrack = null;
    return;
  }
  const bounds = typingRef.value?.getWordBoundsAt(index);
  // 落在词外（空格、标点）：当前这个词的计时到此为止
  if (!bounds || index < bounds.start || index > bounds.end) {
    familiarTrack = null;
    return;
  }
  if (familiarTrack && familiarTrack.start !== bounds.start) {
    familiarTrack = null;
  }
  if (!familiarTrack) {
    // 只有"从词首第一个字母开始打"才计时。中途接手（协作、退格回来）这一遍不算。
    if (index !== bounds.start) return;
    const candidate = familiarCandidateByStart.value.get(bounds.start);
    if (!candidate) return;                                 // 不合格的词（单字母、撇号后半截、含数字）
    if (familiarWords.value.has(candidate.word)) return;    // 已经是熟词，不重新计时
    familiarTrack = {
      start: bounds.start,
      end: bounds.end,
      word: candidate.word,
      letters: bounds.end - bounds.start + 1,
      firstAt: Date.now(),
      valid: true,
    };
  }
  // 自动填出来的字符（被忽略的标点/数字）不是用户敲的，打错更不用说，这一遍都不算数
  if (auto || !correct) {
    familiarTrack.valid = false;
  }
  if (index === familiarTrack.end) {
    if (familiarTrack.valid && Date.now() - familiarTrack.firstAt <= familiarMs.value * (familiarTrack.letters - 1)) {
      markFamiliar(familiarTrack.word);
    }
    familiarTrack = null;
  }
};

// 整词朗读：非字母/数字（空格、撇号、标点等）都当作词与词之间的分界。
// 这里只记当前词里最后填入的字符下标，真正朗读时再按下标从原文切出整词——不能自己攒字符串：
// 手动播放/逐字母朗读会 clearCurrentWord 把词退回词首，Backspace/方向键也会改已输入内容，
// 这些都不发 charFilled，攒出来的串会重复（打成 "worword" 这种，发音自然不对）。
let pendingWordEnd: number | null = null;
const flushWord = () => {
  let p: Promise<void> = Promise.resolve();
  // 关掉整词朗读：打完一个词不出声，练习者的思路不被打断（提示音、逐字母朗读、
  // 手动播放这些是另外的开关，各管各的）
  if (pendingWordEnd !== null && speakWord.value) {
    const word = typingRef.value?.getWordAt(pendingWordEnd);
    if (word) p = speak(word, undefined, false, isFamiliarWord(word) ? speakWordFamiliarAction.value : speakWordAction.value);
  }
  pendingWordEnd = null;
  return p;
};

const onCharFilled = (index: number, char: string, auto: boolean, correct: boolean, skip: boolean) => {
  // 熟词跳过补出来的字符：跳过那一下已经把整词念过了，这里既不逐字母朗读、也不排队整词朗读，
  // 更不进熟词计时（不是用户敲出来的，不该算"打得快"）。
  if (skip) {
    pendingWordEnd = null;
    return;
  }
  trackFamiliar(index, auto, correct);

  if (auto || correct) {
    if (isSpeakable(char)) {
      pendingWordEnd = index;
    } else {
      flushWord();
    }
  }

  if (auto) {
    if (speakLetters.value && isSpeakable(char)) speak(char, undefined, false, speakLettersAction.value);
    return;
  }
  if (correct) {
    if (speakLetters.value && isSpeakable(char)) speak(char, undefined, false, speakLettersAction.value);
  } else {
    playWrongSound();
  }
};

const onCompleted = async () => {
  const completedRoundId = roundId;
  await flushWord();
  await new Promise((resolve) => setTimeout(resolve, 500));
  // 不直接 tap('tapLeft')：多人时要等大家都打完，由服务端决定什么时候换句
  if (completedRoundId !== roundId) return;
  await reportComplete(completedRoundId);
};

// 手动播放这个词该用哪套朗读设置：在熟词库里就用手动播放那一行的"熟词"下拉，否则用"生词"下拉。
const playActionOf = (word: string) => {
  return isFamiliarWord(word) ? familiarPlayAction.value : manualPlayAction.value;
};

const speakCurrentWord = () => {
  const word = typingRef.value?.getCurrentWord();
  if (word) speak(word, undefined, true, playActionOf(word));
};

const onManualPlay = (word: string) => {
  if (word) speak(word, undefined, true, playActionOf(word));
  typingRef.value?.clearCurrentWord();
};

const resetLevel = async () => {
  try {
    const req = new Request({
      path: Path.game,
      headers: {'jsMethod': 'Game.resetLevel'},
    });
    await client.node!.send(req);
  } catch (error) {
    console.error('Failed to reset level:', error);
  }
};

const onSpellPlay = (word: string) => {
  for (const ch of word) {
    if (isSpeakable(ch)) speak(ch, undefined, false, spellPlayAction.value);
  }
  if (spellResetLevel.value) {
    void resetLevel();
  }
  typingRef.value?.clearCurrentWord();
};

const onHintTrigger = () => {
  void tap('tapMiddle');
};

// 亮度调的是"跑 App 的那台设备"的屏幕，而请求是经 websocket 发回 App 的，
// 所以只有 App 内置 WebView（加载的是 https://127.0.0.1:<port>）才该调它——
// 局域网上别人用浏览器进来按闭眼，不能把主机的屏幕搞暗。
const isInAppWebView = ['127.0.0.1', 'localhost', '[::1]', '::1'].includes(window.location.hostname);

// 遮挡（"黑屏模式"）时把 App 那台设备的屏幕调暗、系统栏藏掉；取消遮挡时还原。
// 两件事各有一个开关，一起下发给 App。
// 不 await、不开 overlay：闭眼可以由快捷键触发，等一个网络往返会卡住打字节奏。
const applyMaskUi = (mode: MaskMode) => {
  if (!isInAppWebView) {
    return;
  }
  // 调暗只跟全黑那一档走：typed 档屏幕上还有字要看，调暗等于把自己的内容也糊掉。
  // 藏系统栏两档都做，遮挡时的沉浸感是一样的诉求。
  const req = new Request({
    path: Path.game,
    headers: {'jsMethod': 'Game.setBrightness'},
    data: {dim: mode === 'black' && dimOnMask.value, immersive: mode !== 'off' && immersiveOnMask.value},
  });
  client.node!.send(req).catch((error) => {
    console.error('Failed to apply mask ui:', error);
  });
};

// 遮挡切换的唯一入口：三个触发点（Eye 图标、遮罩上连点两下、maskTrigger 快捷键）都走这里，
// 免得亮度/系统栏的还原漏在某一条路上
const setMaskMode = (mode: MaskMode) => {
  if (maskMode.value === mode) {
    return;
  }
  maskMode.value = mode;
  applyMaskUi(mode);
  saveMaskMode(mode);
};

// 档位记到服务端，下次进来恢复。同 applyMaskUi：不 await、不开 overlay，免得卡住打字
const saveMaskMode = (mode: MaskMode) => {
  const req = new Request({
    path: Path.game,
    headers: {'jsMethod': 'Game.setMaskMode'},
    data: mode,
  });
  client.node!.send(req).catch((error) => {
    console.error('Failed to save mask mode:', error);
  });
};

// 轮转一档：off -> black -> typed -> off
const cycleMaskMode = () => {
  const next = maskModeOrder[(maskModeOrder.indexOf(maskMode.value) + 1) % maskModeOrder.length];
  setMaskMode(next);
};

// 黑屏模式下单击不退出：屏幕全黑之后揣兜里/放桌上，一碰就退出没法用。要连点两下才退。
// pointerdown 上 preventDefault 是关键：不然手指碰到遮罩，typing 那个覆盖层 <input> 会失焦，
// 蓝牙键盘立刻整个哑掉。maskTrigger 快捷键仍然随时可以切。
let lastMaskTapAt = 0;
const onMaskPointerDown = () => {
  const now = Date.now();
  if (now - lastMaskTapAt < 400) {
    lastMaskTapAt = 0;
    setMaskMode('off');
    return;
  }
  lastMaskTapAt = now;
};

const onMaskTrigger = () => {
  cycleMaskMode();
};

// 空键不算触发键，过滤掉，免得用户还没填键的那一行把普通输入吃掉
const assistTriggerKeys = computed(() => {
  return assistiveTouchBindings.value.map((b) => b.key).filter((k) => k !== '');
});

// 执行结果算不算"这个按钮没用了"。只有 App 明确回了一个不是 'ok' 的结果才算
// （'not_found' / 'unavailable' / 'invalid_args'）。
// 网络请求类的动作（比如 AI 解释）在 App 那边要跑十几秒，ws 的 10 秒超时会先返回一个
// status=504、data 为空的壳子，可这时候动作照样在执行、结果也会正常出来，
// 这种情况不能提示"已失效"，不然功能明明生效了却报错。
const tapFailed = (res: Response) => res.status === 200 && !res.error && res.data !== 'ok';

// 按下绑定键：让 App 执行对应的辅助触控按钮。这里不开 overlay，避免打断打字节奏；
// 但按钮已经被删掉/当前模式用不了时要给个提示，不然用户只会觉得"这个键没反应"。
const onAssistTrigger = async (key: string, bounds: { start: number; end: number } | null) => {
  const binding = assistiveTouchBindings.value.find((b) => b.key === key);
  if (!binding || !binding.action) {
    return;
  }
  if (binding.wordAsk) {
    await onWordAsk(binding, bounds);
    return;
  }
  try {
    const req = new Request({
      path: Path.game,
      headers: {'jsMethod': 'Game.assistiveTouchTap'},
      data: binding.action,
    });
    const res = await client.node!.send(req);
    if (tapFailed(res)) {
      showToast.warn(`${t('assistiveTouchActionMissing')} ${binding.name}`);
    }
  } catch (error) {
    console.error('Failed to tap assistive touch:', error);
  }
};

// 单词提问并朗读：把光标所在的词交给 App，只给这一个词标上下划线去问（问过的直接读存好的），
// 结果用绑定的朗读动作读出来。跟普通绑定一样不开 overlay，避免打断打字节奏。
const onWordAsk = async (binding: AssistiveTouchBinding, bounds: { start: number; end: number } | null) => {
  if (!bounds || !content.value) {
    return; // 按键时光标不在任何词上
  }
  try {
    const req = new Request({
      path: Path.game,
      headers: {'jsMethod': 'Game.wordAsk'},
      data: {
        id: binding.action,
        read: binding.read,
        sentence: content.value,
        start: bounds.start,
        end: bounds.end,
        prefix: t('wordAskKeyWords'),
      },
    });
    const res = await client.node!.send(req);
    if (res.status === 200 && !res.error && res.data === 'empty') {
      showToast.warn(t('wordAskEmpty'));
    } else if (tapFailed(res)) {
      showToast.warn(`${t('assistiveTouchActionMissing')} ${binding.name}`);
    }
  } catch (error) {
    console.error('Failed to ask word:', error);
  }
};

// 手机锁屏 / 切到别的 App 之后回来：WebView 里的 JS 在这期间是被 Chromium 冻结的，
// 输入框的焦点、软键盘、WebSocket 连接都可能已经没了。回到可见状态时统一自愈一次：
// 抢回焦点 → 让 App 重新把焦点给 WebView（蓝牙键盘只认焦点）。
// 冻结期间可能漏了 gameRefresh（别人打完换句了），在等人的话立刻再问一次服务端，
// 它会回 stale 让这边自己 refresh。
const onVisibilityChange = async () => {
  if (document.visibilityState !== 'visible') {
    return;
  }
  typingRef.value?.focus();
  await raiseSoftKeyboard();
  if (waitingTimer !== null) {
    clearTimeout(waitingTimer);
    await reportComplete(roundId);
  }
};

const refresh = async () => {
  try {
    overlayVisible.value = true;
    pendingWordEnd = null;
    pendingSave = null;
    stopWaiting();
    const req = new Request({
      path: Path.game,
      headers: {'jsMethod': 'Game.answer'},
    });
    const res = await client.node!.send(req);
    content.value = res.data.answer;
    roundId = typeof res.data.roundId === 'number' ? res.data.roundId : -1;
    updateIgnoreIndexes(res.data.mask);
    // 上次没打完的进度接回来。必须排在 content 赋值之后：Typing 的 watch(props.content)
    // 会把 userInput 清零并填好被忽略的自动字符，initUserInput 会等那个 watch 跑完再盖上去
    const savedInput = typeof res.data.userInput === 'string' ? res.data.userInput : '';
    if (savedInput !== '') {
      await nextTick();
      typingRef.value?.initUserInput(savedInput);
    }
    familiarTrack = null;
    await loadFamiliar();

    await getLabel();
  } catch (error) {
    console.error('Failed to refresh game:', error);
  } finally {
    overlayVisible.value = false;
  }
};

onMounted(async () => {
  await getAdmin();
  await getConfig();
  // 按钮列表只有设置面板的下拉要用，玩家端不拉，省一次请求
  if (isAdmin.value) {
    await getAssistiveTouchActions();
  }
  await refresh();
  // 内容到位、加载遮罩关掉之后才聚焦：Typing 挂载那会儿 content 还是空串，
  // 输入框既没定位也没尺寸，那时候聚焦是白聚焦。
  await nextTick();
  typingRef.value?.focus();
  await raiseSoftKeyboard();
  document.addEventListener('visibilitychange', onVisibilityChange);
  client.controllers.set('gameRefresh', async (_: Request) => {
    await refresh();
    return new Response();
  });
});

// 遮挡状态下页面被切走：屏幕还暗着/系统栏还藏着，还原一次。
// （App 那边 RepeatLogic.onClose / JsRuntime.dispose 也有兜底，这里是最快的那条）
onUnmounted(() => {
  document.removeEventListener('visibilitychange', onVisibilityChange);
  stopGamepadCapture();
  window.clearInterval(gamepadIdTimer);
  stopWaiting();
  if (maskMode.value !== 'off') {
    applyMaskUi('off');
  }
});

</script>
<style scoped>
.type-game-container {
  display: flex;
  flex-direction: column;
  flex: 1; /* 继承父级的高度占满 */
  min-height: 0; /* 不加这条，flex 子项的 min-height:auto 会被内容撑高，滚动条永远出不来 */
}

.typing-content {
  flex: 1; /* 自动撑开，把 actions 挤到最下面 */
  min-height: 0;
  overflow-y: auto; /* 内容多到一屏放不下时自己滚，底部按钮和顶部图标保持不动 */
  -webkit-overflow-scrolling: touch;
  padding: 10px;
  padding-top: 0;
}

.actions {
  display: flex;
  justify-content: space-around;
  padding: 10px 0;
  padding-bottom: env(safe-area-inset-bottom); /* 适配手机底部安全区 */
  flex-shrink: 0;
}

.actions .nut-button {
  line-height: 1.1;
  width: 32%;
}

.nut-theme-dark .info-icon,
.nut-theme-dark .info-profile {
  color: white;
}

.info-profile {
  font-size: 18px;
  line-height: 18px;
  cursor: pointer;
}

.info-waiting {
  margin-right: auto; /* 等人的提示靠左，profile 和图标贴右 */
  font-size: 13px;
  color: #e6a23c;
}

.info-bar {
  display: flex;
  justify-content: flex-end;
  align-items: center;
  gap: 12px;
  padding: 0 15px;
}

.cell-help {
  margin-left: 8px;
  cursor: pointer;
  flex-shrink: 0; /* 贴在行尾，别被前面的输入框挤小 */
}

.assist-binding-del {
  flex-shrink: 0;
  opacity: 0.6;
}

/* nut-input 默认上下 padding 10px，设置面板里一行一个输入框显得太高，统一压矮 */
.settings-panel :deep(.nut-input) {
  padding-top: 4px;
  padding-bottom: 4px;
}

/* 出声设置行：标题和触发键/开关在第一行，音色小字占满最后一行（flex-basis 100% 换到下一行） */
.voice-cell {
  flex-wrap: wrap;
  align-items: center;
}

/* 带输入框的行窄屏放不下一行，固定分行排：标题 + 问号 / 输入框 + 加号 / 音色小字（没有就只两行）。
   标题把第一行除问号以外的位置占满，输入框就被挤到第二行；order 决定各块的先后。 */
.stacked-cell {
  flex-wrap: wrap;
  align-items: center;
  row-gap: 6px;
}

.stacked-cell :deep(.nut-cell__title) {
  order: 0;
  flex: 1 1 0;
  min-width: calc(100% - 32px);
}

.stacked-cell > .cell-help {
  order: 1;
}

.stacked-cell > .stacked-space {
  order: 2;
  margin-right: 8px;
  opacity: 0.6;
}

.stacked-cell > .stacked-key {
  order: 2;
  flex: 1;
  min-width: 0;
}

.stacked-cell > .stacked-add {
  order: 3;
  flex-shrink: 0;
  margin-left: 8px;
}

.stacked-cell > .voice-line {
  order: 4;
}

/* 辅助触控绑定行第一行右边有删除和问号两个图标，标题要多让出一点位置 */
.stacked-cell-binding :deep(.nut-cell__title) {
  min-width: calc(100% - 56px);
}

.stacked-cell-binding > .assist-binding-del {
  order: 1;
  margin-left: 8px;
}

/* 最后一行的小字（音色/绑定的动作）：能点时是链接样式，不能点时是普通灰字 */
.voice-line {
  flex-basis: 100%;
  margin-top: 2px;
  font-size: 12px;
  line-height: 16px;
}

.voice-line.voice-link {
  color: #1989fa;
  text-decoration: underline;
  cursor: pointer;
}

.nut-theme-dark .voice-line.voice-link {
  color: #5ca8ff;
}

.voice-line.voice-text {
  opacity: 0.6;
}

/* 弹层里的文字不会从 nut-cell 继承颜色，亮/暗主题都要自己给 */
.voice-picker {
  padding: 16px;
  max-height: 70vh;
  overflow-y: auto;
  color: #1a1a1a;
}

.nut-theme-dark .voice-picker {
  color: #f5f5f5;
}

.voice-picker-title {
  font-weight: bold;
  text-align: center;
  margin-bottom: 12px;
}

.voice-picker-group {
  padding: 8px 0;
  border-bottom: 1px solid rgba(128, 128, 128, 0.2);
}

.voice-picker-tag {
  font-size: 13px;
  opacity: 0.6;
  margin-bottom: 4px;
}

.voice-picker-option {
  display: flex;
  padding: 6px 0;
}

.voice-picker-desc {
  margin-top: 12px;
  font-size: 12px;
  opacity: 0.6;
}

.eyes-closed-mask {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: #000;
  z-index: 3000;
}
</style>