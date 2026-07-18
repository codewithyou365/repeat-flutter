declare function sendMessage(method: string, payload: string): any;

type JsonRecord = Record<string, any>;

type IntervalMode = 'none' | 'oddHidden' | 'evenHidden';

type Config = {
    ignorePunctuation: boolean;
    ignoreCase: boolean;
    intervalMode: IntervalMode;
    ttsRate: number;
    speakLetters: boolean;
    manualTtsRate: number;
    manualPlayTrigger: string;
    [key: string]: any;
};

type Verse = {
    a?: string;
    [key: string]: any;
};

type GameArgs = {
    userId: number;
    data: any;
};

const Util = {
    getConfig: async function (): Promise<Config> {
        try {
            const data = await sendMessage('getData', '{}');
            if (data == null || data === '') {
                return {"ignorePunctuation": true, "ignoreCase": true, "intervalMode": "none", "ttsRate": 1, "speakLetters": true, "manualTtsRate": 1, "manualPlayTrigger": "."};
            }
            return JSON.parse(data);
        } catch (e) {
            return {"ignorePunctuation": true, "ignoreCase": true, "intervalMode": "none", "ttsRate": 1, "speakLetters": true, "manualTtsRate": 1, "manualPlayTrigger": "."};
        }
    },

    setConfig: async function (key: string, value: any): Promise<void> {
        const data = await this.getConfig();
        data[key] = value;
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
                await Util.setConfig(data.key, data.value);
                return JSON.stringify({});
            } else {
                return JSON.stringify({status: 500, error: "not admin"});
            }
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

    getIntervalMask: function (content: string, mode: IntervalMode, ignorePunctuation: boolean): string {
        if (content.length === 0) {
            return content;
        }
        const chars = content.split('');
        const punctuationRegex = /\p{P}/u;
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
            const config = await Util.getConfig();
            const intervalMode: IntervalMode = config.intervalMode || 'none';
            const ignorePunctuation = config.ignorePunctuation ?? true;
            const mask = this.getIntervalMask(answer, intervalMode, ignorePunctuation);
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

    tts: async function (args: GameArgs): Promise<string> {
        try {
            const data = args.data || {};
            const text = typeof data.text === 'string' ? data.text : '';
            const type = typeof data.type === 'string' ? data.type : '';
            // 调用方（客户端）可以直接指定语速（比如手动播放走 manualTtsRate）；
            // 不指定时按自动播放语速（config.ttsRate）
            let rate = typeof data.rate === 'number' ? data.rate : undefined;
            if (rate === undefined) {
                const config = await Util.getConfig();
                rate = typeof config.ttsRate === 'number' ? config.ttsRate : 1;
            }
            await Util.tts({text, type, rate});
            return JSON.stringify({data: 'ok'});
        } catch (error: any) {
            return JSON.stringify({status: 500, error: error.toString()});
        }
    },
};
