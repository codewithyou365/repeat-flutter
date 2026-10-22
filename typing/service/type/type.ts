declare function sendMessage(method: string, payload: string): any;

type JsonRecord = Record<string, any>;

type IntervalMode = 'none' | 'oddHidden' | 'evenHidden';

// 一条"辅助触控触发键"绑定：按下 key 就执行 App 辅助触控里 action 对应的按钮。
// action 形如 custom:<AtAction.id>（老配置里还有 builtin:<枚举名>，App 端读到会当作找不到）；
// name 是选中那一刻的动作名快照，只用于显示（动作被删掉后拿不到真名时还能看出绑的是什么）。
// wordAsk=true 的绑定是"单词提问"：按下 key 时先把光标所在的词在句子里标上下划线，
// 连同之前已经标过的词一起当成 input1，再去执行 action 对应的自定义动作（只有一个参数的那种）。
type AssistiveTouchBinding = {
    key: string;
    action: string;
    name: string;
    wordAsk: boolean;
};

// 老版本里单词提问是独立的一条配置，现在并进了 assistiveTouchBindings（wordAsk=true 的那条）。
// 这个类型只为读老配置保留，前端读到后会迁移进绑定列表并把这里清空。
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
    speakLetters: boolean;
    speakWord: boolean;
    manualPlayTrigger: string;
    spellPlayTrigger: string;
    hintTrigger: string;
    maskTrigger: string;
    dimOnMask: boolean;
    keyMapping: string;
    assistiveTouchBindings: AssistiveTouchBinding[];
    wordAskTrigger: WordAskTrigger;
    spellResetLevel: boolean;
    // 熟词阈值：每个字母允许的毫秒数，0 = 整个"熟词"功能不工作。
    // 一个词从第一个字母敲下到最后一个字母敲下 <= familiarMs * (字母数 - 1) 就算熟词。
    familiarMs: number;
    // 熟词有效期（天），0 = 不过期。进库超过这个天数的词在 familiarQuery 时被删掉。
    familiarExpireDays: number;
    // 熟词跳过键：按下时把光标所在的熟词整词补完，空串 = 不启用。
    familiarSkipTrigger: string;
    [key: string]: any;
};

type StoredConfig = {
    // 管理员设置面板里正在编辑的槽位，也是没自己挑过 profile 的玩家默认用的那套
    activeProfile: number;
    profileNames: string[];
    profiles: ProfileConfig[];
    // 玩家在游戏界面自己挑的 profile：userId -> 槽位下标。没挑过的玩家走 activeProfile
    userProfiles: Record<string, number>;
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

// 打字进度落盘的最小间隔（毫秒）：敲字期间按这个节流，收尾的地方强制写
const PERSIST_INTERVAL_MS = 1000;

// 熟词库在 GameKv 里的 key 前缀（`fw:<小写词>`），value 存记住它的时间戳
const FAMILIAR_PREFIX = 'fw:';

// 能进熟词库的词：必须是"完整的、超过一个字母的纯字母词"。
// 这里只看词本身；"完整"里"前面不能是撇号"那一半（you're 的 re 不算词）由客户端在切词时判断，
// 因为只有它手上有整句原文。不合格返回 ''。
function normalizeFamiliarWord(raw: any): string {
    if (typeof raw !== 'string') {
        return '';
    }
    const word = raw.trim().toLowerCase();
    if (word.length < 2 || !/^\p{L}+$/u.test(word)) {
        return '';
    }
    return word;
}

// 某个玩家实际生效的 profile 下标：自己挑过且仍在范围内就用自己的，否则用 activeProfile
function profileIndexOf(stored: StoredConfig, userId: number): number {
    const index = stored.userProfiles[String(userId)];
    return typeof index === 'number' && index >= 0 && index < stored.profiles.length ? index : stored.activeProfile;
}

// 该玩家生效 profile 的熟词阈值，<=0 表示关闭
async function familiarMs(userId: number): Promise<number> {
    const stored = await Util.getConfig();
    const value = stored.profiles[profileIndexOf(stored, userId)].familiarMs;
    return typeof value === 'number' && value > 0 ? value : 0;
}

// 该玩家生效 profile 的熟词有效期（天），<=0 表示不过期
async function familiarExpireDays(userId: number): Promise<number> {
    const stored = await Util.getConfig();
    const value = stored.profiles[profileIndexOf(stored, userId)].familiarExpireDays;
    return typeof value === 'number' && value > 0 ? value : 0;
}

function defaultProfileConfig(): ProfileConfig {
    return {"ignorePunctuation": true, "ignoreNumber": true, "ignoreCase": true, "intervalMode": "none", "speakLetters": false, "speakWord": true, "manualPlayTrigger": ".", "spellPlayTrigger": ",", "hintTrigger": " ", "maskTrigger": "", "dimOnMask": false, "keyMapping": "", "assistiveTouchBindings": [], "wordAskTrigger": {"key": "", "action": "", "name": ""}, "spellResetLevel": false, "familiarMs": 0, "familiarExpireDays": 0, "familiarSkipTrigger": ""};
}

function defaultStoredConfig(): StoredConfig {
    const names: string[] = [];
    const profiles: ProfileConfig[] = [];
    for (let i = 0; i < PROFILE_COUNT; i++) {
        names.push(`${i + 1}`);
        profiles.push(defaultProfileConfig());
    }
    return {activeProfile: 0, profileNames: names, profiles: profiles, userProfiles: {}};
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
    // 越界的选择直接丢掉（槽位数以后变少也不会指到不存在的 profile）
    const userProfiles: Record<string, number> = {};
    if (raw.userProfiles && typeof raw.userProfiles === 'object') {
        for (const key of Object.keys(raw.userProfiles)) {
            const index = raw.userProfiles[key];
            if (typeof index === 'number' && index >= 0 && index < PROFILE_COUNT) {
                userProfiles[key] = index;
            }
        }
    }
    return {activeProfile, profileNames: names, profiles: profiles, userProfiles};
}

// 老版本是扁平的单份配置（没有 profiles 数组），迁移成 profile 0，其余槽位用默认值填充，
// 并立即写回，避免每次读都要重新迁移
async function migrateFlatConfig(old: any): Promise<StoredConfig> {
    const migrated = defaultStoredConfig();
    migrated.profiles[0] = {...defaultProfileConfig(), ...old};
    await Util.setConfig(migrated);
    return migrated;
}

// 打字进度落盘的形状（getData/setData 那个 blob 里的 typeState 字段）。
// 只存"当前正在打的这一条"，verseKey 是这条 verse 的答案原文，用来认领：对不上就当没存过。
type StoredTypeState = {
    verseKey: string;
    userInput: string;
    indexToUserId: Record<string, number>;
    userIdToUserName: Record<string, string>;
};

const Util = {
    // getData/setData 只有一个 JSON blob，配置和打字进度都住在里面，读改写时必须留着对方的字段。
    // 本服务是这个 blob 的唯一写方，所以直接在内存里缓存一份，省掉每次落盘前的那次读。
    storeCache: null as JsonRecord | null,

    getStore: async function (): Promise<JsonRecord> {
        if (Util.storeCache !== null) {
            return Util.storeCache;
        }
        let store: JsonRecord = {};
        try {
            const data = await sendMessage('getData', '{}');
            if (data != null && data !== '') {
                const parsed = JSON.parse(data);
                if (parsed && typeof parsed === 'object') {
                    store = parsed;
                }
            }
        } catch (e) {
            store = {};
        }
        Util.storeCache = store;
        return store;
    },

    setStore: async function (store: JsonRecord): Promise<void> {
        Util.storeCache = store;
        await sendMessage('setData', JSON.stringify(store));
    },

    getConfig: async function (): Promise<StoredConfig> {
        try {
            const store = await Util.getStore();
            if (Object.keys(store).length === 0) {
                return defaultStoredConfig();
            }
            if (Array.isArray(store.profiles)) {
                return normalizeStoredConfig(store);
            }
            return await migrateFlatConfig(store);
        } catch (e) {
            return defaultStoredConfig();
        }
    },

    // 只覆写配置那几个键，blob 里的打字进度（typeState）原样留着，别互相冲掉
    setConfig: async function (data: StoredConfig): Promise<void> {
        const store = await Util.getStore();
        const next: JsonRecord = {
            activeProfile: data.activeProfile,
            profileNames: data.profileNames,
            profiles: data.profiles,
            userProfiles: data.userProfiles,
        };
        if (store.typeState !== undefined) {
            next.typeState = store.typeState;
        }
        await Util.setStore(next);
    },

    getTypeState: async function (): Promise<StoredTypeState | null> {
        const store = await Util.getStore();
        const s = store.typeState;
        if (!s || typeof s !== 'object' || typeof s.verseKey !== 'string' || typeof s.userInput !== 'string') {
            return null;
        }
        return {
            verseKey: s.verseKey,
            userInput: s.userInput,
            indexToUserId: (s.indexToUserId && typeof s.indexToUserId === 'object') ? s.indexToUserId : {},
            userIdToUserName: (s.userIdToUserName && typeof s.userIdToUserName === 'object') ? s.userIdToUserName : {},
        };
    },

    setTypeState: async function (state: StoredTypeState | null): Promise<void> {
        const store = await Util.getStore();
        if (state === null) {
            delete store.typeState;
        } else {
            store.typeState = state;
        }
        await Util.setStore(store);
    },

    // 字段块（{text|content,start,end,mediaHash,showType}）的正文。
    // 新形态是有序的 'content' 数组（正文串 + 文件项），老形态是平铺的 'text'，两者二选一。
    // 跟 Dart 侧 VerseField.getText 保持一致：只把裸字符串项按顺序拼起来（\n 连接），文件项跳过。
    blockText: function (block: VerseField | string | null | undefined): string {
        if (typeof block === 'string') return block;
        if (!block) return '';
        const items = block.content;
        if (Array.isArray(items)) {
            const buf: string[] = [];
            for (const item of items) {
                if (typeof item === 'string' && item !== '') buf.push(item);
            }
            return buf.join('\n');
        }
        return block.text ? block.text : '';
    },
    fieldText: function (verse: Verse | null | undefined, acronym: string): string {
        const v = verse ? verse[acronym] : null;
        if (typeof v === 'string') return v;
        // 提示('t')是数组，一节可以挂好几条，这里取第 1 条。
        if (Array.isArray(v)) return Util.blockText(v[0]);
        return Util.blockText(v);
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
    // ---- GameKv：游戏自己的键值表（Dart 侧见 lib/db/entity/game_kv.dart）----
    // 熟词库这种"条目一直长、要按 key 单条读写"的数据走这里，不塞进 getData/setData 那个整块 JSON。
    kvGet: async function (k: string): Promise<string> {
        try {
            const ret = await sendMessage('kvGet', JSON.stringify({k}));
            return typeof ret === 'string' ? ret : '';
        } catch (e) {
            return '';
        }
    },
    kvGetMany: async function (ks: string[]): Promise<JsonRecord> {
        try {
            const data = await sendMessage('kvGetMany', JSON.stringify({ks}));
            if (data == null || data === '') {
                return {};
            }
            const parsed = JSON.parse(data);
            return (parsed && typeof parsed === 'object') ? parsed : {};
        } catch (e) {
            return {};
        }
    },
    kvSet: async function (k: string, v: string): Promise<void> {
        try {
            await sendMessage('kvSet', JSON.stringify({k, v}));
        } catch (e) {
            // 写不进去就算了，熟词库丢一条不值得打断打字
        }
    },
    kvDelete: async function (ks: string[]): Promise<void> {
        try {
            await sendMessage('kvDelete', JSON.stringify({ks}));
        } catch (e) {
        }
    },
    playWrong: async function (url: string): Promise<any> {
        try {
            return await sendMessage('playWrong', JSON.stringify({url}));
        } catch (e) {
            return '';
        }
    },
    // 调的是跑 App 的那台设备的屏幕亮度/系统栏，所以只该由 App 内置 WebView 的客户端触发。
    // payload 原样透传：dim 控制调暗，immersive 控制隐藏状态栏/导航栏，两者独立。
    setBrightness: async function (payload: { dim?: boolean; immersive?: boolean }): Promise<any> {
        try {
            return await sendMessage('setBrightness', JSON.stringify(payload));
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

    // ---- 共享打字进度 ----
    // 内存里存一份当权威（定序、冲突检测），同时把当前这条 verse 的进度落到 getData/setData 的
    // blob 里：退出 App / 服务重启后再进来，同一条 verse 能接着打（见 ensureLoaded / persist）。
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
    // lastWriterUserId: 最后一次写入是谁干的。客户端拿它认出"这条广播是我自己敲字的回声"，
    // 直接忽略，免得回声把本地刚敲出来的字盖回去
    lastWriterUserId: -1,
    // verseKey: 当前这条 verse 的答案原文，落盘时当认领用的 key
    verseKey: '',
    // loaded: 内存态有没有跟磁盘对过账。App 刚起来 / 服务重启时是 false，第一次用到就去读盘
    loaded: false,
    lastPersistAt: 0,
    // dirty: 有改动还没落盘（被节流压着），下一个落盘时机补上
    dirty: false,

    onNewVerse: async function () {
        await this.clear();
    },
    currentVerseKey: async function (): Promise<string> {
        const verse = await Util.getVerse();
        return Util.fieldText(verse, 'a');
    },
    // 把磁盘上存的进度接回内存（verseKey 对得上才接）。
    // seq 不恢复：客户端重进也是重新 getState 拉一份，从 0 重新定序就行。
    restoreFromStore: async function (): Promise<boolean> {
        const saved = await Util.getTypeState();
        if (!saved || saved.verseKey !== this.verseKey) {
            return false;
        }
        this.userInput = saved.userInput;
        this.indexToUserId = saved.indexToUserId;
        this.userIdToUserName = saved.userIdToUserName;
        return true;
    },
    // 内存态还没跟磁盘对过账（服务重启后第一次被调用，期间没走过 clear）就补一次
    ensureLoaded: async function (): Promise<void> {
        if (this.loaded) {
            return;
        }
        this.loaded = true;
        this.verseKey = await this.currentVerseKey();
        await this.restoreFromStore();
    },
    // 落盘。每敲一个字写一次库太重，平时按 1 秒节流，收尾的地方（换 verse、打完）用 force 立刻写。
    // 调用点一律排在 Util.broadcast 之后：写库的耗时不该算进协作者看到字的延迟里。
    persist: async function (force: boolean): Promise<void> {
        this.dirty = true;
        const now = Date.now();
        if (!force && now - this.lastPersistAt < PERSIST_INTERVAL_MS) {
            this.schedulePersist();
            return;
        }
        this.lastPersistAt = now;
        this.dirty = false;
        await Util.setTypeState({
            verseKey: this.verseKey,
            userInput: this.userInput,
            indexToUserId: this.indexToUserId,
            userIdToUserName: this.userIdToUserName,
        });
    },
    persistTimerOn: false,
    // 节流压下去的那次改动，如果后面没人再敲字就没有下一个落盘时机了（停手那一下会丢）。
    // 运行时有 setTimeout 就挂一次补写；没有（JS 引擎不一定提供）就只能等下一次 input/getState/clear。
    schedulePersist: function (): void {
        if (this.persistTimerOn || typeof setTimeout !== 'function') {
            return;
        }
        this.persistTimerOn = true;
        setTimeout(async () => {
            this.persistTimerOn = false;
            if (this.dirty) {
                await this.persist(true);
            }
        }, PERSIST_INTERVAL_MS);
    },
    clear: async function (): Promise<void> {
        // 内存重置必须无条件执行：adminEnable 时虽然不广播，但内容本身已经换了，
        // 旧的共享输入串留着，等退出维护态就会把上一条的进度盖到新内容上。
        this.roundId += 1;
        this.seq = 0;
        this.userInput = '';
        this.indexToUserId = {};
        this.completedRoundId = -1;
        this.lastWriterUserId = -1;
        this.dirty = false;
        this.loaded = true;
        this.verseKey = await this.currentVerseKey();
        // 重进 App / 重启服务时 newVerse 事件照样会来一发，那时候内容其实没变，
        // 不能借着这一发把盘上存的进度冲掉：verseKey 对得上就当"接着打"，把进度捞回来。
        if (!await this.restoreFromStore()) {
            // 真换了内容：盘上换成新 verse 的空进度，上一条的不再保留（只存当前这一条）
            await this.persist(true);
        }
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
            lastWriterUserId: this.lastWriterUserId,
        };
    },
    // 挂载 / 断线重连 / 换完 verse 之后拉一次，把共享进度接上
    getState: async function (): Promise<string> {
        try {
            await this.ensureLoaded();
            if (this.dirty) {
                await this.persist(true);
            }
            return JSON.stringify({data: this.getBroadcastData()});
        } catch (error: any) {
            return JSON.stringify({status: 500, error: error.toString()});
        }
    },
    // args.data = {roundId, baseSeq, userInput, changedIndexes}
    input: async function (args: GameArgs): Promise<string> {
        try {
            await this.ensureLoaded();
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
            this.lastWriterUserId = userId;
            await Util.broadcast(this.typeStatePath, this.getBroadcastData());
            await this.persist(false);
            return JSON.stringify({data: {seq: this.seq, roundId: this.roundId}});
        } catch (error: any) {
            return JSON.stringify({status: 500, error: error.toString()});
        }
    },
    // 打完一整句时由客户端调用，代替原来的 tap('tapLeft')。按 roundId 幂等：
    // 协作模式下可能有不止一个客户端判定完成，重复 uiTap 会一口气跳过好几条 verse。
    complete: async function (): Promise<string> {
        try {
            if (this.completedRoundId === this.roundId) {
                return JSON.stringify({data: 'already'});
            }
            this.completedRoundId = this.roundId;
            // 这句已经打完了，盘上的进度不用留：不然万一没跳成下一条，重进 App 会把打完的内容又摆出来
            this.dirty = false;
            await Util.setTypeState(null);
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
    // 玩家在游戏界面自己挑 profile，不限管理员：只记在自己名下，不动别人和管理员的 activeProfile
    selectProfile: async function (args: GameArgs): Promise<string> {
        try {
            const index = typeof args.data === 'number' ? args.data : parseInt(args.data, 10);
            const stored = await Util.getConfig();
            if (!(Number.isFinite(index) && index >= 0 && index < stored.profiles.length)) {
                return JSON.stringify({status: 500, error: "invalid profile"});
            }
            stored.userProfiles[String(args.userId)] = index;
            await Util.setConfig(stored);
            return JSON.stringify({});
        } catch (e: any) {
            return JSON.stringify({status: 500, error: e.toString()});
        }
    },
    // myProfile：请求者实际生效的那套（自己挑过的，否则 activeProfile）
    getConfig: async function (args: GameArgs): Promise<string> {
        try {
            const configData = await Util.getConfig();
            return JSON.stringify({
                data: {...configData, myProfile: profileIndexOf(configData, args.userId)},
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

    // 间隔遮罩按请求者自己的 profile 算，所以不同玩家拿到的 mask 可以不一样
    answer: async function (args: GameArgs): Promise<string> {
        try {
            const verse = await Util.getVerse();
            const answer = Util.fieldText(verse, 'a');
            const stored = await Util.getConfig();
            const config = stored.profiles[profileIndexOf(stored, args.userId)];
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
            // 朗读设置由调用方指定的动作带（'custom:<动作id>'，Dart 侧用那个动作存的
            // 引擎/音色/语速/音高来读）。这里必须原样转发出去，漏了这个字段就退回公共配置了。
            const action = typeof data.action === 'string' ? data.action : '';
            // rate 只在调用方明确指定时才传。不指定就交给 Dart 那边按字段的公共配置来定，
            // 这里不能自己兜一个默认值：塞了 rate 就会把动作/公共配置里的语速覆盖掉。
            const rate = typeof data.rate === 'number' ? data.rate : undefined;
            await Util.tts({text, type, rate, manual, action});
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

    // 播放任意提示音。Dart 那边的消息名叫 playWrong（第一个调用方是打错提示音），
    // 实现其实是通用的"下载 url 落地临时文件再播"，所以熟词提示音也走它。
    playSound: async function (args: GameArgs): Promise<string> {
        try {
            const data = args.data || {};
            const url = typeof data.url === 'string' ? data.url : '';
            await Util.playWrong(url);
            return JSON.stringify({data: 'ok'});
        } catch (error: any) {
            return JSON.stringify({status: 500, error: error.toString()});
        }
    },

    // ---- 熟词 ----
    // 打得够快的词进库（familiarMark），下次再遇到标成紫色，可以用"熟词跳过键"整词跳过。
    // 出库只有一条路：进库时间超过"熟词有效期"，familiarQuery 查到时顺手删掉——
    // 想留住一个词就得隔一阵子再打快一遍。
    // 库是按游戏存的（GameKv，主键 gameId + key），一台设备上所有玩家共用一份。

    // args.data = {words: string[]}；返回其中已经在熟词库里的词（小写）。
    // 阈值没配（familiarMs<=0）时一律返回空：服务端也当总开关，客户端配置没刷新也不会误触发。
    familiarQuery: async function (args: GameArgs): Promise<string> {
        try {
            if (await familiarMs(args.userId) <= 0) {
                return JSON.stringify({data: {words: []}});
            }
            const raw = (args.data && Array.isArray(args.data.words)) ? args.data.words : [];
            const words: string[] = [];
            for (const item of raw) {
                const word = normalizeFamiliarWord(item);
                if (word && words.indexOf(word) === -1) {
                    words.push(word);
                }
            }
            if (words.length === 0) {
                return JSON.stringify({data: {words: []}});
            }
            const found = await Util.kvGetMany(words.map((w) => FAMILIAR_PREFIX + w));
            // 进库时间就是 kv 的值（familiarMark 存的 Date.now()）。超过有效期的当场删掉再返回，
            // 免得客户端还按紫色标记去跳一个早就该忘掉的词。
            // 值解析不出数字的当作不过期（老数据兜底），有效期 <=0 时整段跳过。
            const days = await familiarExpireDays(args.userId);
            const deadline = days > 0 ? Date.now() - days * 24 * 60 * 60 * 1000 : 0;
            const alive: string[] = [];
            const expired: string[] = [];
            for (const w of words) {
                const value = found[FAMILIAR_PREFIX + w];
                if (value === undefined) {
                    continue;
                }
                const markedAt = Number(value);
                if (deadline > 0 && Number.isFinite(markedAt) && markedAt < deadline) {
                    expired.push(FAMILIAR_PREFIX + w);
                } else {
                    alive.push(w);
                }
            }
            if (expired.length > 0) {
                await Util.kvDelete(expired);
            }
            return JSON.stringify({data: {words: alive}});
        } catch (error: any) {
            return JSON.stringify({status: 500, error: error.toString()});
        }
    },

    // args.data = {word}
    familiarMark: async function (args: GameArgs): Promise<string> {
        try {
            if (await familiarMs(args.userId) <= 0) {
                return JSON.stringify({data: 'off'});
            }
            const word = normalizeFamiliarWord(args.data && args.data.word);
            if (!word) {
                return JSON.stringify({data: 'skip'});
            }
            await Util.kvSet(FAMILIAR_PREFIX + word, `${Date.now()}`);
            return JSON.stringify({data: 'ok'});
        } catch (error: any) {
            return JSON.stringify({status: 500, error: error.toString()});
        }
    },

    // args.data = {word}。出库不看阈值开关：关掉功能之前记下的词，该删还是要能删。
    // 现在打字页自己不调它了（出库统一走 familiarQuery 里的过期清理），保留给脚本/别的页面用。
    familiarForget: async function (args: GameArgs): Promise<string> {
        try {
            const word = normalizeFamiliarWord(args.data && args.data.word);
            if (!word) {
                return JSON.stringify({data: 'skip'});
            }
            await Util.kvDelete([FAMILIAR_PREFIX + word]);
            return JSON.stringify({data: 'ok'});
        } catch (error: any) {
            return JSON.stringify({status: 500, error: error.toString()});
        }
    },

    // 闭眼遮挡（"黑屏模式"）时把屏幕调暗/还原、把系统栏藏掉/放回。不加管理员门禁：
    // 闭眼是玩家动作，由客户端保证只有 App 内置 WebView 才会调过来。
    // immersive 缺省时不传，Dart 侧就不动系统栏（老版本页面的行为保持不变）。
    setBrightness: async function (args: GameArgs): Promise<string> {
        try {
            const data = args.data || {};
            const payload: { dim: boolean; immersive?: boolean } = {dim: data.dim === true};
            if (data.immersive !== undefined) {
                payload.immersive = data.immersive === true;
            }
            await Util.setBrightness(payload);
            return JSON.stringify({data: 'ok'});
        } catch (error: any) {
            return JSON.stringify({status: 500, error: error.toString()});
        }
    },
};
