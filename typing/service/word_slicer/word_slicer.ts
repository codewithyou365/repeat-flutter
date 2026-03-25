declare function sendMessage(method: string, payload: string): any;

type JsonRecord = Record<string, any>;

type Verse = {
    a?: string;
    [key: string]: any;
};

type GameArgs = {
    userId: number;
    data: any;
};

type SelectedWord = {
    start: number;
    end: number;
    colorIndex: number;
    word: string;
};

type AnswerWord = {
    start: number;
    end: number;
    word: string;
};

type ColorStat = {
    rightCount: number;
    errorCount: number;
    score: number;
};

const Util = {
    updateCurrVerseContent: async function (type: string, content: string): Promise<string> {
        try {
            const payload = {
                type: type,
                content: content
            };
            return await sendMessage('updateCurrVerseContent', JSON.stringify(payload));
        } catch (e) {
            console.error("Update Verse Content failed:", e);
            return 'error';
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
    getConfig: async function (): Promise<JsonRecord> {
        const defaultValue = {
            hiddenContentPercent: 0.5,
            maxScore: 10,
            shouldRememberIfPassingRate: 0.8,
        };
        try {
            const data = await sendMessage('getData', '{}');
            if (data == null || data === '') {
                return defaultValue;
            }
            return JSON.parse(data);
        } catch (e) {
            return defaultValue;
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
            const ret = JSON.parse(data);
            return ret;
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
    broadcast: async function (path: string, data: any): Promise<string> {
        try {
            // 确保 data 是字符串格式，符合 Dart 侧 jsonDecode 的预期
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
    getUserName: async function (userId: number): Promise<string> {
        try {
            return await sendMessage('getUserName', JSON.stringify({'userId': userId}));
        } catch (e) {
            console.error("GetUserName failed:", e);
            return '';
        }
    },

    gameScoreInc: async function (userId: number, score: number, remark = ''): Promise<string> {
        try {
            const payload = {
                userId: userId,
                score: score,
                remark: remark
            };
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

const GameStepEnum = {
    none: 'none',
    selectRole: 'selectRole',
    started: 'started',
    finished: 'finished',
};

const Game = {
    key: 'WordSlicerText',
    gameRefreshPath: 'gameRefresh',
    gameStatus: GameStepEnum.selectRole,
    punctuationRegex: /[\p{P}\p{S}]/gu,
    currUserIndex: 0,
    _config: null as JsonRecord | null,
    originContentWithSpace: '',
    originContent: '',
    answer: '',
    verseId: undefined as string | number | undefined,

    content: '',
    userIds: [] as number[],
    userIdToUserName: {} as Record<string, string>,
    colorIndexToUserId: [[], [], []] as number[][],
    colorIndexToStat: [] as ColorStat[],
    colorIndexToSelectedContentIndex: [[], [], []] as number[][],
    abandonUserIds: [] as number[],
    userIdToScore: {} as Record<string, number>,
    userIdToNexted: {} as Record<string, boolean>,

    getConfigWithCache: async function (forceRefresh = false): Promise<JsonRecord> {
        if (this._config && !forceRefresh) {
            return this._config;
        }
        try {
            this._config = await Util.getConfig();
            return this._config;
        } catch (e) {
            return {maxScore: 10, hiddenContentPercent: 0.5};
        }
    },

    getStatus: function (args: GameArgs): string {
        try {
            return JSON.stringify({
                status: 200,
                data: this.getBroadcastData()
            });
        } catch (e: any) {
            return JSON.stringify({status: 500, error: e.toString()});
        }
    },

    selectRole: async function (args: GameArgs): Promise<string> {
        try {
            const userId = args.userId;
            const colorIndex = args.data.index;

            if (!userId) throw new Error("Missing userId");

            // 注册新玩家
            if (!this.userIds.includes(userId)) {
                this.userIds.push(userId);
                this.userIdToUserName[userId] = await Util.getUserName(userId);
            }

            for (let i = 0; i < 3; i++) {
                this.colorIndexToUserId[i] = this.colorIndexToUserId[i].filter(id => id !== userId);
            }

            if (colorIndex >= 0 && colorIndex <= 2) {
                this.colorIndexToUserId[colorIndex].push(userId);
            }

            await Util.broadcast(this.gameRefreshPath, this.getBroadcastData());
            return JSON.stringify({status: 200, data: "Role selected"});
        } catch (e: any) {
            return JSON.stringify({status: 500, error: e.toString()});
        }
    },

    leave: async function (args: GameArgs): Promise<string> {
        try {
            const userId = args.userId;

            this.userIds = this.userIds.filter(id => id !== userId);
            this.abandonUserIds = this.abandonUserIds.filter(id => id !== userId);

            for (let i = 0; i < 3; i++) {
                this.colorIndexToUserId[i] = this.colorIndexToUserId[i].filter(id => id !== userId);
            }

            await Util.broadcast(this.gameRefreshPath, this.getBroadcastData());
            return JSON.stringify({status: 200});
        } catch (e: any) {
            return JSON.stringify({status: 500, error: e.toString()});
        }
    },

    start: async function (args: GameArgs): Promise<string> {
        this.gameStatus = GameStepEnum.started;
        await this.getConfigWithCache();
        await this.clear();
        return JSON.stringify({status: 200, data: "Game started"});
    },
    onNewVerse: async function () {
        await this.clear();
    },
    clear: async function (): Promise<void> {
        if (Util.adminEnable()) {
            await Util.broadcast(this.gameRefreshPath, '{}');
            return;
        }
        if (this.gameStatus === GameStepEnum.finished) {
            this.gameStatus = GameStepEnum.started;
        }
        const config = await this.getConfigWithCache();
        const verse = await Util.getVerse();
        this.answer = verse.a || '';

        const manualContent = verse[this.key];
        let baseContent = (manualContent && manualContent !== '') ? manualContent : this.answer;
        baseContent = baseContent.replace(this.punctuationRegex, " ");
        baseContent = baseContent.replace(/\s+/g, " ");
        this.originContentWithSpace = baseContent.toLowerCase().trim();
        this.originContent = baseContent.replace(/\s+/g, "");

        const hcp = config.hiddenContentPercent || 0;
        if (hcp > 0 && hcp <= 1 && this.originContent.length > 0) {
            const chars = this.originContent.split('');
            const hideCount = Math.round(chars.length * hcp);
            const indexes = Array.from({length: chars.length}, (_, i) => i);
            for (let i = indexes.length - 1; i > 0; i--) {
                const j = Math.floor(Math.random() * (i + 1));
                [indexes[i], indexes[j]] = [indexes[j], indexes[i]];
            }
            for (let i = 0; i < hideCount; i++) {
                if (chars[indexes[i]] !== ' ') chars[indexes[i]] = '•';
            }
            this.content = chars.join('');
        } else {
            this.content = this.originContent;
        }
        this.colorIndexToSelectedContentIndex = [[], [], []];
        this.abandonUserIds = [];
        this.userIdToScore = {};
        this.userIdToNexted = {};
        this.colorIndexToStat = [
            {rightCount: 0, errorCount: 0, score: 0},
            {rightCount: 0, errorCount: 0, score: 0},
            {rightCount: 0, errorCount: 0, score: 0}
        ];

        await Util.broadcast(this.gameRefreshPath, this.getBroadcastData());
    },

    submit: async function (args: GameArgs): Promise<string> {
        const userId = args.userId;
        const selectedIndexed = (args.data || []) as number[];

        if (selectedIndexed.length === 0) {
            if (!this.abandonUserIds.includes(userId)) {
                this.abandonUserIds.push(userId);
                this.currUserIndex = (this.currUserIndex + 1) % this.userIds.length;
            }
            await this.checkFinishCondition();
            await Util.broadcast(this.gameRefreshPath, this.getBroadcastData());
            return JSON.stringify({status: 200});
        }

        if (this.userIds.length > 1 && selectedIndexed.length > 0) {
            selectedIndexed.sort((a: number, b: number) => a - b);
            for (let i = 1; i < selectedIndexed.length; i++) {
                if (selectedIndexed[i] !== selectedIndexed[i - 1] + 1) {
                    return JSON.stringify({status: 400, error: 'wordSlicerYourCommitMustBeConsecutive'});
                }
            }
        }

        let userColorIndex = -1;
        for (let i = 0; i < 3; i++) {
            if (this.colorIndexToUserId[i].includes(userId)) {
                userColorIndex = i;
                break;
            }
        }

        if (userColorIndex !== -1) {
            const currentSelections = new Set(this.colorIndexToSelectedContentIndex[userColorIndex]);
            selectedIndexed.forEach((index: number) => currentSelections.add(index));
            this.colorIndexToSelectedContentIndex[userColorIndex] = Array.from(currentSelections).sort((a: number, b: number) => a - b);
        }
        if (selectedIndexed.length !== 0) {
            const contentChars = this.content.split('');
            for (const idx of selectedIndexed) {
                if (idx >= 0 && idx < this.originContent.length) {
                    contentChars[idx] = this.originContent[idx];
                }
            }
            this.content = contentChars.join('');
        }
        this.currUserIndex = (this.currUserIndex + 1) % this.userIds.length;
        await this.checkFinishCondition();
        await Util.broadcast(this.gameRefreshPath, this.getBroadcastData());
        return JSON.stringify({status: 200});
    },

    checkFinishCondition: async function (): Promise<boolean> {
        const allSelected = new Set<number>();
        this.colorIndexToSelectedContentIndex.forEach(arr => {
            arr.forEach(idx => allSelected.add(idx));
        });

        const effectiveContentLength = this.originContent.replace(/[\s\p{P}\p{S}]/gu, '').length;

        const isAllSelected = allSelected.size >= effectiveContentLength;
        const isAllAbandoned = this.abandonUserIds.length > 0 && this.abandonUserIds.length >= this.userIds.length;

        if (isAllSelected || isAllAbandoned) {
            await this.setResult();
            return true;
        }
        return false;
    },

    _getColorIndexToWords: function (): SelectedWord[] {
        const result: SelectedWord[] = [];
        for (let i = 0; i < 3; i++) {
            const selectedIndexes = this.colorIndexToSelectedContentIndex[i];
            const words = this._extractConsecutiveWord(selectedIndexes, i);
            result.push(...words);
        }

        result.sort((a, b) => a.start - b.start);

        result.forEach(ele => {
            ele.word = this.originContent.substring(ele.start, ele.end + 1);
        });

        return result;
    },
// 内部工具：提取连续索引块 (由原 Dart 代码转化)
    _extractConsecutiveWord: function (indexes: number[], colorIndex: number): SelectedWord[] {
        if (!indexes || indexes.length === 0) return [];

        const sorted = [...new Set(indexes)].sort((a, b) => a - b);
        const ranges: SelectedWord[] = [];

        let start = sorted[0];
        let end = start;

        for (let i = 1; i < sorted.length; i++) {
            if (sorted[i] === end + 1) {
                end = sorted[i];
            } else {
                ranges.push({start: start, end: end, colorIndex: colorIndex, word: ''});
                start = end = sorted[i];
            }
        }

        ranges.push({start: start, end: end, colorIndex: colorIndex, word: ''});
        return ranges;
    },
    _getAnswerWords: function (): AnswerWord[] {
        const result: AnswerWord[] = [];
        if (!this.originContentWithSpace) return result;

        const words = this.originContentWithSpace.split(' ');
        let cursor = 0;

        for (const w of words) {
            if (w.length > 0) {
                const start = cursor;
                const end = cursor + w.length - 1;

                result.push({
                    start: start,
                    end: end,
                    word: w
                });

                cursor += w.length;
            }
        }

        return result;
    },
    setResult: async function (): Promise<void> {
        const config = await this.getConfigWithCache();
        const maxScore = config.maxScore || 10;
        const tempScores = [0, 0, 0];

        // 初始化统计数据
        this.colorIndexToStat = Array.from({length: 3}, () => ({rightCount: 0, errorCount: 0, score: 0}));

        const totalValidChars = this.originContent.replace(/\s/g, '').length;
        if (totalValidChars === 0) {
            return;
        }

        const scoreEachChar = maxScore / totalValidChars;

        const answerWords = this._getAnswerWords();
        const selectedWords = this._getColorIndexToWords();

        selectedWords.forEach((selected: SelectedWord) => {
            const delta = selected.word.length * scoreEachChar;
            // 查找起始位置匹配的答案
            const match = answerWords.find(a => a.start === selected.start);

            if (match && match.word === selected.word) {
                tempScores[selected.colorIndex] += delta;
                this.colorIndexToStat[selected.colorIndex].rightCount += selected.word.length;
            } else {
                tempScores[selected.colorIndex] -= delta;
                this.colorIndexToStat[selected.colorIndex].errorCount += selected.word.length;
            }
        });

        // 最终得分映射
        tempScores.forEach((val, i) => {
            // 可以在这里加一个限制：Math.max(0, Math.round(val))，如果你不想扣成负分
            this.colorIndexToStat[i].score = Math.round(val);
        });

        // 分摊分数到每个用户
        this.userIds.forEach(userId => {
            let userColorIdx = -1;
            for (let i = 0; i < 3; i++) {
                if (this.colorIndexToUserId[i].includes(userId)) {
                    userColorIdx = i;
                    break;
                }
            }

            if (userColorIdx !== -1) {
                const teamSize = this.colorIndexToUserId[userColorIdx].length;
                const rawTeamScore = this.colorIndexToStat[userColorIdx].score;
                const finalScore = teamSize > 0 ? Math.round(rawTeamScore / teamSize) : 0;

                this.userIdToScore[userId.toString()] = finalScore;

                if (finalScore !== 0) {
                    Util.gameScoreInc(userId as number, finalScore, finalScore > 0 ? 'i:obtainedInTheGame' : 'i:deductedInTheGame');
                }
            }
        });

        this.gameStatus = GameStepEnum.finished;
    },

    next: async function (args: GameArgs): Promise<string> {
        try {
            const userId = args.userId;
            if (!userId) return JSON.stringify({status: 400});

            this.userIdToNexted[userId] = true;

            const allNexted = this.userIds.every(id => this.userIdToNexted[id] === true);

            if (allNexted) {
                const config = await this.getConfigWithCache();
                const maxScore = config.maxScore || 10;
                const passingRate = config.shouldRememberIfPassingRate || 0.8;
                if (Util.repeatFlow() === 'examine') {
                    const totalScore = this.userIds.reduce((sum, id) => {
                        const score = this.userIdToScore[id.toString()] || 0;
                        return sum + score;
                    }, 0 as number);
                    if ((totalScore / maxScore) >= passingRate) {
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
                return JSON.stringify({status: 200, data: "waiting_for_others"});
            }
        } catch (e: any) {
            return JSON.stringify({status: 500, error: e.toString()});
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
                return JSON.stringify({status: 200});
            } else {
                return JSON.stringify({status: 403, error: "only_admin_can_edit"});
            }
        } catch (e: any) {
            return JSON.stringify({status: 500, error: e.toString()});
        }
    },

    getConfig: async function (): Promise<string> {
        try {
            const configData = await Util.getConfig();
            return JSON.stringify({status: 200, data: configData});
        } catch (error: any) {
            return JSON.stringify({status: 500, error: error.toString()});
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
    resetWordSlicerText: async function (args: GameArgs): Promise<string> {
        try {
            const userId = args.userId;
            const adminId = Util.adminId();
            const adminEnable = Util.adminEnable();
            if (userId === adminId && adminEnable) {
                await Util.updateCurrVerseContent(Game.key, '');
                return JSON.stringify({status: 200, data: "Manual content resetted"});
            } else {
                return JSON.stringify({status: 500, error: "not admin"});
            }
        } catch (e: any) {
            return JSON.stringify({status: 500, error: e.toString()});
        }
    },
    setWordSlicerText: async function (args: GameArgs): Promise<string> {
        try {
            const userId = args.userId;
            const adminId = Util.adminId();
            const adminEnable = Util.adminEnable();
            if (userId === adminId && adminEnable) {
                const content = args.data;
                await Util.updateCurrVerseContent(Game.key, content);
                return JSON.stringify({status: 200, data: "Manual content updated"});
            } else {
                return JSON.stringify({status: 500, error: "not admin"});
            }
        } catch (e: any) {
            return JSON.stringify({status: 500, error: e.toString()});
        }
    },
    getWordSlicerText: async function (args: GameArgs): Promise<string> {
        try {
            const verse = await Util.getVerse();
            let savedContent = verse[Game.key];
            if (!savedContent || savedContent === '') {
                savedContent = verse['a'] || '';
            }

            return JSON.stringify({
                status: 200,
                data: {
                    answer: savedContent,
                },
            });
        } catch (e: any) {
            return JSON.stringify({
                status: 500,
                error: e.toString()
            });
        }
    },

    getBroadcastData: function (): JsonRecord {
        const isFinished = this.gameStatus === GameStepEnum.finished;
        return {
            verseId: this.verseId,
            answer: isFinished ? this.originContentWithSpace : '',
            content: this.content,
            gameStep: this.gameStatus,

            colorIndexToUserId: this.colorIndexToUserId,
            userIds: this.userIds,
            userIdToUserName: this.userIdToUserName,
            currUserIndex: this.currUserIndex,

            colorIndexToSelectedContentIndex: this.colorIndexToSelectedContentIndex,
            colorIndexToStat: this.colorIndexToStat,

            userIdToScore: this.userIdToScore,
            userIdToNexted: this.userIdToNexted,
            config: this._config,
        };
    },
};
