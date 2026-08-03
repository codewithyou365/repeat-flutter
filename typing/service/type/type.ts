declare function sendMessage(method: string, payload: string): any;

type JsonRecord = Record<string, any>;

type IntervalMode = 'none' | 'oddHidden' | 'evenHidden';

// 一条"辅助触控触发键"绑定：按下 key 就执行 App 辅助触控里 action 对应的按钮。
// action 形如 builtin:<BuiltInAction 枚举名> 或 custom:<AssistiveTouchAction.id>；
// name 是选中那一刻的动作名快照，只用于显示（动作被删掉后拿不到真名时还能看出绑的是什么）。
type AssistiveTouchBinding = {
    key: string;
    action: string;
    name: string;
};

// 单词提问触发键：按下 key 时，把光标所在的词在句子里标上下划线，
// 连同之前已经标过的词一起当成 input1，去执行 action 对应的自定义动作（只有一个参数的那种）。
// action/name 的含义跟 AssistiveTouchBinding 一样；key 为空就是不启用。
type WordAskTrigger = {
    key: string;
    action: string;
    name: string;
};

type ProfileConfig = {
    ignorePunctuation: boolean;
    ignoreNumber: boolean;
    ignoreCase: boolean;
    intervalMode: IntervalMode;
    ttsRate: number;
    speakLetters: boolean;
    manualTtsRate: number;
    manualPlayTrigger: string;
    spellPlayTrigger: string;
    hintTrigger: string;
    maskTrigger: string;
    keyMapping: string;
    assistiveTouchBindings: AssistiveTouchBinding[];
    wordAskTrigger: WordAskTrigger;
    spellResetLevel: boolean;
    [key: string]: any;
};

type StoredConfig = {
    activeProfile: number;
    profileNames: string[];
    profiles: ProfileConfig[];
};

type VerseField = {
    text?: string;
    start?: string;
    end?: string;
    mediaHash?: string;
    showType?: string;
    [key: string]: any;
};

type Verse = {
    a?: VerseField;
    [key: string]: any;
};

type GameArgs = {
    userId: number;
    data: any;
};

const PROFILE_COUNT = 3;

function defaultProfileConfig(): ProfileConfig {
    return {"ignorePunctuation": true, "ignoreNumber": true, "ignoreCase": true, "intervalMode": "none", "ttsRate": 1, "speakLetters": false, "manualTtsRate": 0.5, "manualPlayTrigger": ".", "spellPlayTrigger": ",", "hintTrigger": " ", "maskTrigger": "", "keyMapping": "", "assistiveTouchBindings": [], "wordAskTrigger": {"key": "", "action": "", "name": ""}, "spellResetLevel": false};
}

function defaultStoredConfig(): StoredConfig {
    const names: string[] = [];
    const profiles: ProfileConfig[] = [];
    for (let i = 0; i < PROFILE_COUNT; i++) {
        names.push(`${i + 1}`);
        profiles.push(defaultProfileConfig());
    }
    return {activeProfile: 0, profileNames: names, profiles: profiles};
}

// 补齐/裁剪 profiles/profileNames 到固定的 PROFILE_COUNT 个槽位，activeProfile 越界时夹回范围内
function normalizeStoredConfig(raw: any): StoredConfig {
    const fallback = defaultStoredConfig();
    const profiles: ProfileConfig[] = [];
    const names: string[] = [];
    for (let i = 0; i < PROFILE_COUNT; i++) {
        const p = raw.profiles && raw.profiles[i];
        profiles.push(p ? {...defaultProfileConfig(), ...p} : defaultProfileConfig());
        const n = raw.profileNames && raw.profileNames[i];
        names.push(typeof n === 'string' && n ? n : fallback.profileNames[i]);
    }
    let activeProfile = typeof raw.activeProfile === 'number' ? raw.activeProfile : 0;
    if (!(activeProfile >= 0 && activeProfile < PROFILE_COUNT)) {
        activeProfile = 0;
    }
    return {activeProfile, profileNames: names, profiles: profiles};
}

// 老版本是扁平的单份配置（没有 profiles 数组），迁移成 profile 0，其余槽位用默认值填充，
// 并立即写回，避免每次读都要重新迁移
async function migrateFlatConfig(old: any): Promise<StoredConfig> {
    const migrated = defaultStoredConfig();
    migrated.profiles[0] = {...defaultProfileConfig(), ...old};
    await Util.setConfig(migrated);
    return migrated;
}

const Util = {
    getConfig: async function (): Promise<StoredConfig> {
        try {
            const data = await sendMessage('getData', '{}');
            if (data == null || data === '') {
                return defaultStoredConfig();
            }
            const parsed = JSON.parse(data);
            if (parsed && Array.isArray(parsed.profiles)) {
                return normalizeStoredConfig(parsed);
            }
            return await migrateFlatConfig(parsed);
        } catch (e) {
            return defaultStoredConfig();
        }
    },

    setConfig: async function (data: StoredConfig): Promise<void> {
        await sendMessage('setData', JSON.stringify(data));
    },

    // q/a/t 的正文在字段块里（{text,start,end,mediaHash,showType}），
    // n 这类没有媒体的字段仍然是平铺的字符串。
    fieldText: function (verse: Verse | null | undefined, acronym: string): string {
        const v = verse ? verse[acronym] : null;
        if (typeof v === 'string') return v;
        // 提示('t')是数组，一节可以挂好几条，这里取第 1 条。
        if (Array.isArray(v)) {
            const first = v[0];
            if (typeof first === 'string') return first;
            return (first && first.text) ? first.text : '';
        }
        return (v && v.text) ? v.text : '';
    },
    getVerse: async function (): Promise<Verse> {
        try {
            const data = await sendMessage('getVerse', '{}');
            if (data == null || data === '') {
                return {};
            }
            return JSON.parse(data);
        } catch (e) {
            return {};
        }
    },
    getUserName: async function (userId: number): Promise<string> {
        try {
            return await sendMessage('getUserName', JSON.stringify({'userId': userId}));
        } catch (e) {
            return '';
        }
    },
    getLabel: function (): JsonRecord {
        try {
            const left = sendMessage('uiLabel', JSON.stringify({'name': 'left'}));
            const right = sendMessage('uiLabel', JSON.stringify({'name': 'right'}));
            const middle = sendMessage('uiLabel', JSON.stringify({'name': 'middle'}));
            const ret = {
                'left': left,
                'right': right,
                'middle': middle,
            };
            return ret;
        } catch (e) {
            return {};
        }
    },
    uiTap: function (event: string): string {
        try {
            return sendMessage('uiTap', JSON.stringify({'event': event}));
        } catch (e) {
            return '';
        }
    },
    // App 辅助触控当前显示的按钮列表（内置动作 + 用户自定义预设），供设置面板做下拉选择
    assistiveTouchActions: async function (): Promise<JsonRecord[]> {
        try {
            const data = await sendMessage('assistiveTouchActions', '{}');
            if (data == null || data === '') {
                return [];
            }
            const parsed = JSON.parse(data);
            return Array.isArray(parsed) ? parsed : [];
        } catch (e) {
            return [];
        }
    },
    // 执行一个辅助触控按钮。返回 'ok'；动作已被删除返回 'not_found'，
    // 动作还在但当前复习模式下不可用返回 'unavailable'
    //
    // inputs 是自定义动作的参数（按位置对应指令模版里的 {{input1}}..{{input10}}，
    // 个数见 assistiveTouchActions 返回的 inputCount）。游戏调用一律不弹框问用户：
    // 不传或传得不够的，App 那边都按空字符串处理
    assistiveTouchTap: async function (id: string, inputs?: string[]): Promise<string> {
        try {
            const payload: JsonRecord = {'id': id};
            if (inputs != null) {
                payload['inputs'] = inputs;
            }
            return await sendMessage('assistiveTouchTap', JSON.stringify(payload));
        } catch (e) {
            return 'error';
        }
    },
    // 这个自定义动作上次执行时用的 input1（App 拿作用位置里存着的上次指令反着套模版抠出来的）。
    // 没执行过 / 模版对不上 / 模版里没写 {{input1}} 都返回 ''
    assistiveTouchLastInput: async function (id: string): Promise<string> {
        try {
            const ret = await sendMessage('assistiveTouchLastInput', JSON.stringify({'id': id}));
            return typeof ret === 'string' ? ret : '';
        } catch (e) {
            return '';
        }
    },
    adminId: function (): number {
        try {
            const userId = sendMessage('adminId', '{}');
            const parsed = parseInt(userId, 10);
            return Number.isNaN(parsed) ? -1 : parsed;
        } catch (e) {
            return -1;
        }
    },
    adminEnable: function (): boolean {
        try {
            const res = sendMessage('adminEnable', '{}');
            return res === 'true';
        } catch (e) {
            return false;
        }
    },
    broadcast: async function (path: string, data: any): Promise<string> {
        try {
            const payload = {
                path: path,
                data: typeof data === 'string' ? data : JSON.stringify(data)
            };
            return await sendMessage('broadcast', JSON.stringify(payload));
        } catch (e) {
            console.error("Broadcast failed:", e);
            return 'error';
        }
    },
    tts: async function (payload: any): Promise<any> {
        try {
            return await sendMessage('tts', JSON.stringify(payload ?? {}));
        } catch (e) {
            return '';
        }
    },
    playWrong: async function (url: string): Promise<any> {
        try {
            return await sendMessage('playWrong', JSON.stringify({url}));
        } catch (e) {
            return '';
        }
    },
};

// 单词提问：给句子里被选中的词套上的下划线写法（LaTeX），
// 既是写出去的格式，也是下次从上一版 input1 里认回"哪些词已经标过"的依据。
const UNDERLINE_PREFIX = '$\\underline{';
const UNDERLINE_SUFFIX = '}$';

// 把标好下划线的句子拆回「干净句子 + 已标词的区间（按干净句子的下标，含头含尾）」。
// 认不出标记就整句当干净句子、区间为空。
function stripUnderline(marked: string): { plain: string; spans: number[][] } {
    let plain = '';
    const spans: number[][] = [];
    let i = 0;
    while (i < marked.length) {
        if (marked.startsWith(UNDERLINE_PREFIX, i)) {
            const close = marked.indexOf(UNDERLINE_SUFFIX, i + UNDERLINE_PREFIX.length);
            if (close >= 0) {
                const word = marked.slice(i + UNDERLINE_PREFIX.length, close);
                spans.push([plain.length, plain.length + word.length - 1]);
                plain += word;
                i = close + UNDERLINE_SUFFIX.length;
                continue;
            }
        }
        plain += marked[i];
        i++;
    }
    return {plain, spans};
}

// 按区间把干净句子重新标上下划线。区间按起点排序后依次插入，互相不重叠。
function applyUnderline(plain: string, spans: number[][]): string {
    const sorted = spans.slice().sort((a, b) => a[0] - b[0]);
    let ret = '';
    let pos = 0;
    for (const [start, end] of sorted) {
        if (start < pos || start < 0 || end >= plain.length || end < start) {
            continue; // 越界或跟前一个重叠，跳过
        }
        ret += plain.slice(pos, start) + UNDERLINE_PREFIX + plain.slice(start, end + 1) + UNDERLINE_SUFFIX;
        pos = end + 1;
    }
    return ret + plain.slice(pos);
}

const Game = {
    gameRefreshPath: 'gameRefresh',
    // 协作打字的共享状态走单独的广播路径：gameRefreshPath 已经被"换了一条 verse，全体重新拉内容"
    // 占用了，收到它的客户端会走整套 refresh（含加载遮罩），每敲一个字都来一遍没法用。
    typeStatePath: 'typeState',

    // ---- 共享打字进度（只在内存里，不落库；服务重启即清空）----
    // roundId: 每 clear() 一次 +1，用来判断客户端上报的是不是上一条 verse 的残留
    roundId: 0,
    // seq: 本轮的写入版本号。客户端上报时带上自己看到的 baseSeq，对不上说明中间有别人写过，
    //      本次上报直接作废并把最新快照回给它重新同步（整串 last-write-wins + 冲突检测）
    seq: 0,
    // userInput: 就是 Typing 组件里的 userInput，已输入串（含打错的字符）
    userInput: '',
    // indexToUserId: 哪个下标的字符是谁敲的，客户端拿它上色
    indexToUserId: {} as Record<string, number>,
    userIdToUserName: {} as Record<string, string>,
    // completedRoundId: 已经因为"打完了"触发过 tapLeft 的轮次，防止多个客户端同时判完成而连跳 verse
    completedRoundId: -1,

    onNewVerse: async function () {
        await this.clear();
    },
    clear: async function (): Promise<void> {
        // 内存重置必须无条件执行：adminEnable 时虽然不广播，但内容本身已经换了，
        // 旧的共享输入串留着，等退出维护态就会把上一条的进度盖到新内容上。
        this.roundId += 1;
        this.seq = 0;
        this.userInput = '';
        this.indexToUserId = {};
        this.completedRoundId = -1;
        if (!Util.adminEnable()) {
            await Util.broadcast(this.gameRefreshPath, {});
        }
    },
    getBroadcastData: function (): JsonRecord {
        return {
            roundId: this.roundId,
            seq: this.seq,
            userInput: this.userInput,
            indexToUserId: this.indexToUserId,
            userIdToUserName: this.userIdToUserName,
        };
    },
    // 挂载 / 断线重连 / 换完 verse 之后拉一次，把共享进度接上
    getState: function (): string {
        try {
            return JSON.stringify({data: this.getBroadcastData()});
        } catch (error: any) {
            return JSON.stringify({status: 500, error: error.toString()});
        }
    },
    // args.data = {roundId, baseSeq, userInput, changedIndexes}
    input: async function (args: GameArgs): Promise<string> {
        try {
            const userId = args.userId;
            const data = args.data || {};
            // 过期上报（换过 verse，或中间被别人写过）：不写入，把最新快照回给它自己去同步
            if (data.roundId !== this.roundId || data.baseSeq !== this.seq) {
                return JSON.stringify({data: Object.assign({stale: true}, this.getBroadcastData())});
            }

            const userInput: string = typeof data.userInput === 'string' ? data.userInput : '';
            this.userInput = userInput;

            const changedIndexes = Array.isArray(data.changedIndexes) ? data.changedIndexes : [];
            for (const index of changedIndexes) {
                this.indexToUserId[index] = userId;
            }
            // 退格/清词会让串变短，超出长度的归属信息要一起丢掉，否则重新打到这里颜色是旧的
            for (const key of Object.keys(this.indexToUserId)) {
                if (Number(key) >= userInput.length) {
                    delete this.indexToUserId[key];
                }
            }

            if (this.userIdToUserName[userId] === undefined) {
                this.userIdToUserName[userId] = await Util.getUserName(userId);
            }

            this.seq += 1;
            await Util.broadcast(this.typeStatePath, this.getBroadcastData());
            return JSON.stringify({data: {seq: this.seq, roundId: this.roundId}});
        } catch (error: any) {
            return JSON.stringify({status: 500, error: error.toString()});
        }
    },
    // 打完一整句时由客户端调用，代替原来的 tap('tapLeft')。按 roundId 幂等：
    // 协作模式下可能有不止一个客户端判定完成，重复 uiTap 会一口气跳过好几条 verse。
    complete: function (): string {
        try {
            if (this.completedRoundId === this.roundId) {
                return JSON.stringify({data: 'already'});
            }
            this.completedRoundId = this.roundId;
            const result = Util.uiTap('tapLeft');
            if (result !== 'success') {
                return JSON.stringify({status: 500, error: result + ''});
            }
            return JSON.stringify({data: 'ok'});
        } catch (error: any) {
            return JSON.stringify({status: 500, error: error.toString()});
        }
    },
    setConfig: async function (args: GameArgs): Promise<string> {
        try {
            const userId = args.userId;
            const adminId = Util.adminId();
            const adminEnable = Util.adminEnable();
            if (userId === adminId && adminEnable) {
                const data = args.data;
                const stored = await Util.getConfig();
                const profile = stored.profiles[stored.activeProfile];
                profile[data.key] = data.value;
                await Util.setConfig(stored);
                return JSON.stringify({});
            } else {
                return JSON.stringify({status: 500, error: "not admin"});
            }
        } catch (e: any) {
            return JSON.stringify({status: 500, error: e.toString()});
        }
    },

    setActiveProfile: async function (args: GameArgs): Promise<string> {
        try {
            const userId = args.userId;
            if (userId !== Util.adminId() || !Util.adminEnable()) {
                return JSON.stringify({status: 500, error: "not admin"});
            }
            const index = typeof args.data === 'number' ? args.data : parseInt(args.data, 10);
            const stored = await Util.getConfig();
            if (Number.isFinite(index) && index >= 0 && index < stored.profiles.length) {
                stored.activeProfile = index;
                await Util.setConfig(stored);
            }
            return JSON.stringify({});
        } catch (e: any) {
            return JSON.stringify({status: 500, error: e.toString()});
        }
    },

    setProfileName: async function (args: GameArgs): Promise<string> {
        try {
            const userId = args.userId;
            if (userId !== Util.adminId() || !Util.adminEnable()) {
                return JSON.stringify({status: 500, error: "not admin"});
            }
            const {index, name} = args.data || {};
            const stored = await Util.getConfig();
            if (typeof index === 'number' && index >= 0 && index < stored.profileNames.length && typeof name === 'string' && name.trim()) {
                stored.profileNames[index] = name.trim();
                await Util.setConfig(stored);
            }
            return JSON.stringify({});
        } catch (e: any) {
            return JSON.stringify({status: 500, error: e.toString()});
        }
    },
    getConfig: async function (): Promise<string> {
        try {
            const configData = await Util.getConfig();
            return JSON.stringify({
                data: configData,
            });
        } catch (error: any) {
            return JSON.stringify({
                status: 500,
                error: error.toString()
            });
        }
    },

    getIntervalMask: function (content: string, mode: IntervalMode, ignorePunctuation: boolean, ignoreNumber: boolean): string {
        if (content.length === 0) {
            return content;
        }
        const chars = content.split('');
        const punctuationRegex = /\p{P}/u;
        const numberRegex = /\p{N}/u;
        let wordPos = 0; // 单词内的字母序号（0-based），遇到空格/换行清零

        for (let i = 0; i < chars.length; i++) {
            const char = chars[i];
            if (char === ' ' || char === '\n') {
                wordPos = 0;
                continue;
            }
            if (ignorePunctuation && punctuationRegex.test(char)) {
                continue; // 标点不算字母，也不占用/重置单词内计数
            }
            if (ignoreNumber && numberRegex.test(char)) {
                continue; // 数字不算字母，也不占用/重置单词内计数
            }
            // 1-based 字母序号 n = wordPos + 1
            // none       -> 不间隔，每个字母都必须输入
            // oddHidden  -> n 为奇数(wordPos 偶数)时隐藏，必须输入
            // evenHidden -> n 为偶数(wordPos 奇数)时隐藏，必须输入
            const hide = mode === 'none' ? true : (mode === 'oddHidden' ? (wordPos % 2 === 0) : (wordPos % 2 === 1));
            if (hide) {
                chars[i] = '•'; // '•' = 必须输入
            }
            wordPos++;
        }
        return chars.join('');
    },

    answer: async function (): Promise<string> {
        try {
            const verse = await Util.getVerse();
            const answer = Util.fieldText(verse, 'a');
            const stored = await Util.getConfig();
            const config = stored.profiles[stored.activeProfile];
            const intervalMode: IntervalMode = config.intervalMode || 'none';
            const ignorePunctuation = config.ignorePunctuation ?? true;
            const ignoreNumber = config.ignoreNumber ?? true;
            const mask = this.getIntervalMask(answer, intervalMode, ignorePunctuation, ignoreNumber);
            return JSON.stringify({
                data: {answer: answer, mask: mask},
            });
        } catch (error: any) {
            return JSON.stringify({
                status: 500,
                error: error.toString()
            });
        }
    },

    label: function (): string {
        try {
            const label = Util.getLabel();
            return JSON.stringify({
                data: label,
            });
        } catch (error: any) {
            return JSON.stringify({
                status: 500,
                error: error.toString()
            });
        }
    },

    tap: function (args: GameArgs): string {
        try {
            const result = Util.uiTap(args.data);
            if (result !== 'success') {
                return JSON.stringify({
                    status: 500,
                    error: result + '',
                });
            }
            return JSON.stringify({});
        } catch (error: any) {
            return JSON.stringify({
                status: 500,
                error: error.toString()
            });
        }
    },

    assistiveTouchActions: async function (): Promise<string> {
        try {
            const actions = await Util.assistiveTouchActions();
            return JSON.stringify({data: actions});
        } catch (error: any) {
            return JSON.stringify({status: 500, error: error.toString()});
        }
    },

    // 玩家按下绑定键时调用，不限管理员（按键的就是正在打字的玩家）。
    // data 既可以是老的动作 id 字符串，也可以是 {id, inputs} —— 后者由脚本自己
    // 控制这个动作的参数（见 Util.assistiveTouchTap），不会弹框问用户
    assistiveTouchTap: async function (args: GameArgs): Promise<string> {
        try {
            const raw = args.data;
            let id: string;
            let inputs: string[] | undefined;
            if (raw != null && typeof raw === 'object') {
                id = typeof raw.id === 'string' ? raw.id : `${raw.id}`;
                if (Array.isArray(raw.inputs)) {
                    inputs = raw.inputs.map((e: any) => (e == null ? '' : `${e}`));
                }
            } else {
                id = typeof raw === 'string' ? raw : `${raw}`;
            }
            const result = await Util.assistiveTouchTap(id, inputs);
            return JSON.stringify({data: result});
        } catch (error: any) {
            return JSON.stringify({status: 500, error: error.toString()});
        }
    },

    // 单词提问：玩家在某个词上按下触发键时调用，不限管理员（按键的就是正在打字的玩家）。
    // data = {id, sentence, start, end}：id 是自定义动作，sentence 是正在打的整句，
    // start/end 是光标所在词在句子里的下标（含头含尾，由打字组件给）。
    //
    // 上次的 input1 里已经标过的词照旧留着，这次的词再加进去，一起当成新的 input1——
    // 于是第一次是「$\underline{How}$ are you?」，第二次变成「$\underline{How}$ are $\underline{you}$?」。
    // 这个词已经标过就保持原样，请求照发（指令跟上次一模一样，配合 playOrOverwrite 就是直接重放）。
    wordAsk: async function (args: GameArgs): Promise<string> {
        try {
            const data = args.data || {};
            const id = typeof data.id === 'string' ? data.id : '';
            const sentence = typeof data.sentence === 'string' ? data.sentence : '';
            const start = typeof data.start === 'number' ? data.start : -1;
            const end = typeof data.end === 'number' ? data.end : -1;
            if (!id || !sentence || start < 0 || end < start || end >= sentence.length) {
                return JSON.stringify({status: 500, error: 'invalid_args'});
            }
            const prev = await Util.assistiveTouchLastInput(id);
            let spans: number[][] = [];
            if (prev) {
                const parsed = stripUnderline(prev);
                // 上次那句跟现在这句对不上（换节了、或者上次的内容是手改的），之前的标记就不要了
                if (parsed.plain === sentence) {
                    spans = parsed.spans;
                }
            }
            if (!spans.some(([s, e]) => s <= end && start <= e)) {
                spans.push([start, end]);
            }
            const result = await Util.assistiveTouchTap(id, [applyUnderline(sentence, spans)]);
            return JSON.stringify({data: result});
        } catch (error: any) {
            return JSON.stringify({status: 500, error: error.toString()});
        }
    },

    // 拼读（逐字母朗读）时把当前 verse 的学习等级置零，由客户端在开启开关时调用
    resetLevel: async function (): Promise<string> {
        try {
            const res = await sendMessage('resetCurrVerseLevel', '{}');
            return JSON.stringify({data: res});
        } catch (error: any) {
            return JSON.stringify({status: 500, error: error.toString()});
        }
    },

    tts: async function (args: GameArgs): Promise<string> {
        try {
            const data = args.data || {};
            const text = typeof data.text === 'string' ? data.text : '';
            const type = typeof data.type === 'string' ? data.type : '';
            const manual = data.manual === true;
            // 调用方（客户端）可以直接指定语速（比如手动播放走 manualTtsRate）；
            // 不指定时按自动播放语速（config.ttsRate）
            let rate = typeof data.rate === 'number' ? data.rate : undefined;
            if (rate === undefined) {
                const stored = await Util.getConfig();
                const config = stored.profiles[stored.activeProfile];
                rate = typeof config.ttsRate === 'number' ? config.ttsRate : 1;
            }
            await Util.tts({text, type, rate, manual});
            return JSON.stringify({data: 'ok'});
        } catch (error: any) {
            return JSON.stringify({status: 500, error: error.toString()});
        }
    },

    playWrong: async function (args: GameArgs): Promise<string> {
        try {
            const data = args.data || {};
            const url = typeof data.url === 'string' ? data.url : '';
            await Util.playWrong(url);
            return JSON.stringify({data: 'ok'});
        } catch (error: any) {
            return JSON.stringify({status: 500, error: error.toString()});
        }
    },
};
