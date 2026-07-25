declare function sendMessage(method: string, payload: string): any;

type JsonRecord = Record<string, any>;

type IntervalMode = 'none' | 'oddHidden' | 'evenHidden';

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
    spellClearWord: boolean;
    spellResetLevel: boolean;
    [key: string]: any;
};

type StoredConfig = {
    activeProfile: number;
    profileNames: string[];
    profiles: ProfileConfig[];
};

type Verse = {
    a?: string;
    [key: string]: any;
};

type GameArgs = {
    userId: number;
    data: any;
};

const PROFILE_COUNT = 3;

function defaultProfileConfig(): ProfileConfig {
    return {"ignorePunctuation": true, "ignoreNumber": true, "ignoreCase": true, "intervalMode": "none", "ttsRate": 1, "speakLetters": false, "manualTtsRate": 0.5, "manualPlayTrigger": ".", "spellPlayTrigger": ",", "hintTrigger": " ", "maskTrigger": "", "keyMapping": "", "spellClearWord": true, "spellResetLevel": false};
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
};

const Game = {
    gameRefreshPath: 'gameRefresh',
    onNewVerse: async function () {
        await this.clear();
    },
    clear: async function (): Promise<void> {
        if (!Util.adminEnable()) {
            await Util.broadcast(this.gameRefreshPath, {});
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
            let answer = '';
            if (verse && verse.a) {
                answer = verse.a;
            }
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
};
