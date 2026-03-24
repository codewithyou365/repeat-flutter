/**
 * 外部注入的方法声明
 */
declare function sendMessage(method: string, args: string): any;

/**
 * 接口定义
 */
interface GameConfig {
    autoBlank: boolean;
    blankContentPercent: number;
    ignorePunctuation: boolean;
    ignoreCase?: boolean;
    maxScore: number;
    shouldRememberIfPassingRate?: number;
}

interface Verse {
    a: string; // 原文/答案
    [key: string]: any; // 允许动态键值，如 blankItRightText
}

interface UserStatus {
    step: StepEnum;
    submit: string;
    name: string;
    score: number;
    nexted: boolean;
}

interface LabelSet {
    left: string;
    right: string;
    middle: string;
}

/**
 * 枚举定义
 */
enum GameEnum {
    init = 'init',
    started = 'started',
    finished = 'finished'
}

enum StepEnum {
    blanking = 'blanking',
    finished = 'finished'
}

/**
 * 工具函数
 */
const Util = {
    updateCurrVerseContent: async function (type: string, content: string): Promise<string> {
        try {
            const payload = {type, content};
            return await sendMessage('updateCurrVerseContent', JSON.stringify(payload));
        } catch (e) {
            console.error("Update Verse Content failed:", e);
            return 'error';
        }
    },

    adminId: function (): number | string {
        try {
            let userId = sendMessage('adminId', '{}');
            return parseInt(userId, 10);
        } catch (e) {
            return '';
        }
    },

    adminEnable: function (): boolean {
        try {
            let res = sendMessage('adminEnable', '{}');
            return res === 'true' || res === true;
        } catch (e) {
            return false;
        }
    },

    getConfig: async function (): Promise<GameConfig> {
        const defaultValue: GameConfig = {
            autoBlank: true,
            blankContentPercent: 0.5,
            ignorePunctuation: true,
            ignoreCase: true,
            maxScore: 10,
            shouldRememberIfPassingRate: 0.8,
        };
        try {
            let data = await sendMessage('getData', '{}');
            if (data == null || data === '') {
                return defaultValue;
            }
            return typeof data === 'string' ? JSON.parse(data) : data;
        } catch (e) {
            return defaultValue;
        }
    },

    setConfig: async function (key: keyof GameConfig, value: any): Promise<void> {
        let data = await this.getConfig();
        (data as any)[key] = value;
        await sendMessage('setData', JSON.stringify(data));
    },

    getVerse: async function (): Promise<Verse> {
        try {
            let data = await sendMessage('getVerse', '{}');
            if (data == null || data === '') return {} as Verse;
            return typeof data === 'string' ? JSON.parse(data) : data;
        } catch (e) {
            return {} as Verse;
        }
    },

    getLabel: function (): LabelSet | Record<string, never> {
        try {
            let left = sendMessage('uiLabel', JSON.stringify({'name': 'left'}));
            let right = sendMessage('uiLabel', JSON.stringify({'name': 'right'}));
            let middle = sendMessage('uiLabel', JSON.stringify({'name': 'middle'}));
            return {left, right, middle};
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

    broadcast: async function (path: string, data: any): Promise<any> {
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

    getUserName: async function (userId: string | number): Promise<string> {
        try {
            return await sendMessage('getUserName', JSON.stringify({'userId': userId}));
        } catch (e) {
            console.error("GetUserName failed:", e);
            return '';
        }
    },

    gameScoreInc: async function (userId: string | number, score: number, remark: string = ''): Promise<any> {
        try {
            const payload = {userId, score, remark};
            return await sendMessage('gameScoreInc', JSON.stringify(payload));
        } catch (e) {
            console.error("gameScoreInc failed:", e);
            return '';
        }
    },

    repeatFlow: function (): string {
        try {
            return sendMessage('repeatFlow', '{}');
        } catch (e) {
            return 'examine';
        }
    },
};

/**
 * 游戏主逻辑
 */
const Game = {
    gameRefreshPath: 'gameRefresh',
    key: 'blankItRightText',
    punctuationRegex: /[\p{P}\p{S}]/gu,
    userIdToUserStatus: {} as Record<string, UserStatus>,
    userIds: [] as string[],
    gameStatus: GameEnum.init as GameEnum,

    _config: null as GameConfig | null,
    answer: '',
    blankContent: '' as string,

    getStatus: function (_: { userId: string }) {
        try {
            const broadcastData = this.getBroadcastData();
            return JSON.stringify({
                status: 200,
                data: broadcastData
            });
        } catch (e: any) {
            return JSON.stringify({
                status: 500,
                error: e.toString()
            });
        }
    },

    join: async function (args: { userId: string }) {
        try {
            const userId = args.userId;
            if (!userId) throw new Error("Missing userId");

            if (!this.userIdToUserStatus[userId]) {
                this.userIds.push(userId);
                const userName = await Util.getUserName(userId);
                this.userIdToUserStatus[userId] = {
                    step: StepEnum.blanking,
                    submit: '',
                    name: userName,
                    score: 0,
                    nexted: false,
                };
            }
            await Util.broadcast(this.gameRefreshPath, this.getBroadcastData());
            return JSON.stringify({status: 200, data: "User joined"});
        } catch (e: any) {
            return JSON.stringify({status: 500, error: e.toString()});
        }
    },

    leave: async function (args: { userId: string }) {
        try {
            const userId = args.userId;
            if (!userId) throw new Error("Missing userId");

            if (this.userIdToUserStatus[userId]) {
                delete this.userIdToUserStatus[userId];
                this.userIds = this.userIds.filter(id => id !== userId);
                await Util.broadcast(this.gameRefreshPath, this.getBroadcastData());
                return JSON.stringify({status: 200, data: `User ${userId} left`});
            } else {
                return JSON.stringify({status: 404, error: "User not found"});
            }
        } catch (e: any) {
            return JSON.stringify({status: 500, error: e.toString()});
        }
    },

    start: async function (_: any) {
        this.gameStatus = GameEnum.started;
        await this.clear();
        return JSON.stringify({status: 200, data: "Game started"});
    },

    submit: async function (args: { userId: string, data: { content: string } }) {
        const userId = args.userId;
        const userTyped = args.data.content;
        const verse = await Util.getVerse();
        const config = await this.getConfigWithCache();
        const passingRate = config.shouldRememberIfPassingRate || 0.8;

        let score = this.getScore(userTyped, verse.a, this.blankContent, config.maxScore, config.ignoreCase ?? true);
        if ((score / config.maxScore) < passingRate) {
            score = 0;
        }

        if (this.userIdToUserStatus[userId]) {
            this.userIdToUserStatus[userId].score = score;
            this.userIdToUserStatus[userId].submit = userTyped;
            this.userIdToUserStatus[userId].step = StepEnum.finished;
        }

        try {
            await Util.gameScoreInc(userId, score, 'i:obtainedInTheGame');
        } catch (e) {
            console.error("Sync score to DB failed", e);
        }
        await Util.broadcast(this.gameRefreshPath, this.getBroadcastData());
        return JSON.stringify({status: 200});
    },

    next: async function (args: { userId: string }) {
        try {
            const userId = args.userId;
            const player = this.userIdToUserStatus[userId];
            if (!player) return JSON.stringify({status: 404, error: "User not found"});

            if (player.step === StepEnum.finished) {
                player.nexted = true;
            } else {
                return JSON.stringify({status: 400, error: "You are not finished"});
            }

            // 【关键修改点】: 显式声明 players 是 UserStatus 数组
            const players: UserStatus[] = Object.values(this.userIdToUserStatus);

            if (players.length === 0) return JSON.stringify({status: 400, error: "No players"});

            const allFinished = players.every((u: UserStatus) => u.step === StepEnum.finished);
            const allNeedToNext = players.every((u: UserStatus) => u.nexted);

            if (allFinished && allNeedToNext) {
                const config = await this.getConfigWithCache();
                const maxScore = config.maxScore || 10;
                const passingRate = config.shouldRememberIfPassingRate || 0.8;

                if (Util.repeatFlow() === 'examine') {
                    const isAllPassed = players.every((u: UserStatus) => (u.score / maxScore) >= passingRate);
                    if (isAllPassed) {
                        Util.uiTap("tapNext");
                    } else {
                        Util.uiTap("tapRight");
                    }
                } else {
                    Util.uiTap("tapNext");
                }
                return JSON.stringify({status: 200, data: "navigated"});
            } else {
                await Util.broadcast(this.gameRefreshPath, this.getBroadcastData());
                return JSON.stringify({status: 202, data: "waiting_for_others"});
            }
        } catch (e: any) {
            return JSON.stringify({status: 500, error: e.toString()});
        }
    },
    myStatus: async function (args: { userId: string }) {
        try {
            const userId = args.userId;
            const user = this.userIdToUserStatus[userId];

            if (!user) {
                return JSON.stringify({status: 404, error: "User not found"});
            }

            if (user.step === StepEnum.finished) {
                const verse = await Util.getVerse();
                return JSON.stringify({
                    status: 200,
                    data: {
                        answer: verse.a || '',
                        score: user.score,
                        submit: user.submit
                    },
                });
            } else {
                return JSON.stringify({
                    status: 200,
                    data: {answer: '', score: 0, submit: ''}
                });
            }
        } catch (error: any) {
            return JSON.stringify({status: 500, error: error.toString()});
        }
    },

    setConfig: async function (args: { userId: string, data: { key: keyof GameConfig, value: any } }) {
        try {
            const userId = args.userId;
            const adminId = Util.adminId();
            const adminEnable = Util.adminEnable();
            if (userId == adminId && adminEnable) {
                let data = args.data;
                await Util.setConfig(data.key, data.value);
                return JSON.stringify({});
            } else {
                return JSON.stringify({status: 500, error: "not admin"});
            }
        } catch (e: any) {
            return JSON.stringify({status: 500, error: e.toString()});
        }
    },

    getConfig: async function () {
        try {
            let configData = await Util.getConfig();
            return JSON.stringify({data: configData});
        } catch (error: any) {
            return JSON.stringify({status: 500, error: error.toString()});
        }
    },

    label: function () {
        try {
            let label = Util.getLabel();
            return JSON.stringify({data: label});
        } catch (error: any) {
            return JSON.stringify({status: 500, error: error.toString()});
        }
    },

    tap: function (args: { data: string }) {
        try {
            let result = Util.uiTap(args.data);
            if (result !== 'success') {
                return JSON.stringify({status: 500, error: result + ''});
            }
            return JSON.stringify({});
        } catch (error: any) {
            return JSON.stringify({status: 500, error: error.toString()});
        }
    },

    resetManualBlank: async function (args: { userId: string }) {
        try {
            const userId = args.userId;
            const adminId = Util.adminId();
            const adminEnable = Util.adminEnable();
            if (userId == adminId && adminEnable) {
                await Util.updateCurrVerseContent(this.key, '');
                return JSON.stringify({status: 200, data: "Manual content resetted"});
            } else {
                return JSON.stringify({status: 500, error: "not admin"});
            }
        } catch (e: any) {
            return JSON.stringify({status: 500, error: e.toString()});
        }
    },

    setBlankContent: async function (args: { userId: string, data: string }) {
        try {
            const userId = args.userId;
            const adminId = Util.adminId();
            const adminEnable = Util.adminEnable();
            if (userId == adminId && adminEnable) {
                const content = args.data;
                await Util.updateCurrVerseContent(this.key, content);
                return JSON.stringify({status: 200, data: "Manual content updated"});
            } else {
                return JSON.stringify({status: 500, error: "not admin"});
            }
        } catch (e: any) {
            return JSON.stringify({status: 500, error: e.toString()});
        }
    },

    getBlankContent: async function (args: { userId: string }) {
        try {
            const userId = args.userId;
            const adminId = Util.adminId();
            const adminEnable = Util.adminEnable();
            if (userId == adminId && adminEnable) {
                const verse = await Util.getVerse();
                const answer = verse['a'];
                let savedContent = verse[this.key];
                if (!savedContent || savedContent === '') {
                    savedContent = answer || '';
                }
                return JSON.stringify({
                    status: 200,
                    data: {blank: savedContent, answer: answer},
                });
            } else {
                return JSON.stringify({status: 500, error: "not admin"});
            }
        } catch (e: any) {
            return JSON.stringify({status: 500, error: e.toString()});
        }
    },

    clear: async function () {
        if (Util.adminEnable()) {
            await Util.broadcast(this.gameRefreshPath, '{}');
            return;
        }
        for (let id in this.userIdToUserStatus) {
            this.userIdToUserStatus[id].step = StepEnum.blanking;
            this.userIdToUserStatus[id].submit = '';
            this.userIdToUserStatus[id].score = 0;
            this.userIdToUserStatus[id].nexted = false;
        }
        const verse = await Util.getVerse();
        this.answer = verse.a || '';
        this.blankContent = await this.getBlankMix();
        await Util.broadcast(this.gameRefreshPath, this.getBroadcastData());
    },

    getBroadcastData: function () {
        const userIds = this.userIds;
        const userIdToUserName: Record<string, string> = {};

        const players = userIds.map(id => {
            const user = this.userIdToUserStatus[id];
            userIdToUserName[id] = user.name;

            let ret: any = {
                userId: id,
                name: user.name,
                step: user.step,
                nexted: user.nexted || false,
            };
            if (this.gameStatus === GameEnum.finished) {
                ret.submit = user.submit;
                ret.score = user.score;
            }
            return ret;
        });

        return {
            gameStatus: this.gameStatus,
            config: this._config,
            blankContent: this.blankContent,
            players: players,
            userIds: userIds,
            userIdToUserName: userIdToUserName,
        };
    },

    getConfigWithCache: async function (forceRefresh = false): Promise<GameConfig> {
        if (this._config && !forceRefresh) {
            return this._config;
        }

        try {
            this._config = await Util.getConfig();
            return this._config;
        } catch (e) {
            console.error("获取配置失败:", e);
            return {
                autoBlank: true,
                blankContentPercent: 0.5,
                ignorePunctuation: true,
                maxScore: 10,
            };
        }
    },

    _shuffle: function <T>(array: T[]): T[] {
        for (let i = array.length - 1; i > 0; i--) {
            const j = Math.floor(Math.random() * (i + 1));
            [array[i], array[j]] = [array[j], array[i]];
        }
        return array;
    },

    getBlankMix: async function (): Promise<string> {
        const config = await this.getConfigWithCache();
        const verse = await Util.getVerse();
        const ignorePunctuation = config.ignorePunctuation ?? true;

        if (config.autoBlank) {
            this.blankContent = this.getBlankAuto(verse, config);
        } else {
            this.blankContent = this.getBlankManual(verse, ignorePunctuation);
            if (this.blankContent === '') {
                this.blankContent = this.getBlankAuto(verse, config);
            }
        }

        return this.blankContent || '';
    },

    getBlankAuto: function (verse: Verse, config: GameConfig): string {
        const content = verse.a || '';
        const percent = config.blankContentPercent ?? 0.5;
        const ignorePunctuation = config.ignorePunctuation ?? true;

        if (percent <= 0 || content.length === 0) {
            return content;
        }

        const chars = content.split('');
        const blankableIndexes: number[] = [];

        for (let i = 0; i < chars.length; i++) {
            const char = chars[i];
            if (char === ' ') continue;

            if (ignorePunctuation && this.punctuationRegex.test(char)) {
                this.punctuationRegex.lastIndex = 0;
                continue;
            }
            blankableIndexes.push(i);
        }

        if (blankableIndexes.length > 0) {
            let hideCount = Math.round(blankableIndexes.length * percent);
            hideCount = Math.max(1, hideCount);

            this._shuffle(blankableIndexes);

            for (let i = 0; i < hideCount && i < blankableIndexes.length; i++) {
                chars[blankableIndexes[i]] = '•';
            }
        }

        return chars.join('');
    },

    getBlankManual: function (verseMap: Verse, ignorePunctuation: boolean): string {
        const a = verseMap.a || '';
        const b = verseMap[this.key] || '';
        if (b === '') return '';
        if (!b && !ignorePunctuation) return '•'.repeat(a.length);

        let result = '';
        for (let i = 0; i < a.length; i++) {
            const aChar = a[i];

            if (ignorePunctuation && this.punctuationRegex.test(aChar)) {
                this.punctuationRegex.lastIndex = 0;
                result += aChar;
                continue;
            }

            if (i >= b.length) {
                result += (aChar === ' ') ? ' ' : '•';
                continue;
            }

            const bChar = b[i];
            if (aChar === ' ') {
                result += ' ';
            } else if (aChar === bChar) {
                result += aChar;
            } else {
                result += '•';
            }
        }
        return result;
    },

    getScore: function (userAnswer: string, correctAnswer: string, blank: string, maxScore: number, ignoreCase: boolean): number {
        let blankCount = 0;
        let rightCount = 0;
        const len = Math.min(userAnswer.length, correctAnswer.length, blank.length);

        for (let i = 0; i < len; i++) {
            if (blank[i] === '•') {
                blankCount++;
                let u = userAnswer[i];
                let c = correctAnswer[i];
                if (u && c && (ignoreCase ? u.toLowerCase() === c.toLowerCase() : u === c)) {
                    rightCount++;
                }
            }
        }
        return blankCount > 0 ? Math.floor((rightCount / blankCount) * maxScore) : 0;
    }
};