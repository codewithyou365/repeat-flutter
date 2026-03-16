const Util = {
    updateCurrVerseContent: async function (type, content) {
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
    adminId: function () {
        try {
            let userId = sendMessage('adminId', '{}');
            return parseInt(userId, 10);
        } catch (e) {
            return '';
        }
    },
    adminEnable: function () {
        try {
            let res = sendMessage('adminEnable', '{}');
            return res === 'true';
        } catch (e) {
            return false;
        }
    },
    getConfig: async function () {
        const defaultValue = {
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
            return JSON.parse(data);
        } catch (e) {
            return defaultValue;
        }
    },

    setConfig: async function (key, value) {
        let data = await this.getConfig();
        data[key] = value;
        await sendMessage('setData', JSON.stringify(data));
    },

    getVerse: async function () {
        try {
            let data = await sendMessage('getVerse', '{}');
            if (data == null || data === '') {
                return {};
            }
            let ret = JSON.parse(data);
            return ret;
        } catch (e) {
            return {};
        }
    },
    getLabel: function () {
        try {
            let left = sendMessage('uiLabel', JSON.stringify({'name': 'left'}));
            let right = sendMessage('uiLabel', JSON.stringify({'name': 'right'}));
            let middle = sendMessage('uiLabel', JSON.stringify({'name': 'middle'}));
            let ret = {
                'left': left,
                'right': right,
                'middle': middle,
            };
            return ret;
        } catch (e) {
            return {};
        }
    },
    uiTap: function (event) {
        try {
            return sendMessage('uiTap', JSON.stringify({'event': event}));
        } catch (e) {
            return '';
        }
    },
    broadcast: async function (path, data) {
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
    getUserName: async function (userId) {
        try {
            return await sendMessage('getUserName', JSON.stringify({'userId': userId}));
        } catch (e) {
            console.error("GetUserName failed:", e);
            return '';
        }
    },

    gameScoreInc: async function (userId, score, remark = '') {
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

    repeatFlow: function () {
        try {
            return sendMessage('repeatFlow', '{}');
        } catch (e) {
            return 'examine';
        }
    },
}

const GameEnum = {
    init: 'init',
    started: 'started',
};
const StepEnum = {
    blanking: 'blanking',
    finished: 'finished',
};

const Game = {
    gameRefreshPath: 'gameRefresh',
    key: 'blankItRightText',
    punctuationRegex: /[\p{P}\p{S}]/gu,
    userIdToUserStatus: {},
    userIds: [],
    gameStatus: GameEnum.init,
    // 内部状态
    _config: null,             // 用于存储缓存的配置对象
    answer: '',
    blankContent: null,        // 存储当前挖空后的文本结果
    getStatus: function (args) {
        try {
            const userId = args.userId;
            const broadcastData = this.getBroadcastData();
            return JSON.stringify({
                status: 200,
                data: broadcastData
            });
        } catch (e) {
            return JSON.stringify({
                status: 500,
                error: e.toString()
            });
        }
    },
    join: async function (args) {
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
        } catch (e) {
            return JSON.stringify({status: 500, error: e.toString()});
        }
    },
    leave: async function (args) {
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
        } catch (e) {
            return JSON.stringify({status: 500, error: e.toString()});
        }
    },
    start: async function (args) {
        this.gameStatus = GameEnum.started;
        await this.clear();

        return JSON.stringify({status: 200, data: "Game started"});
    },
    submit: async function (args) {
        const userId = args.userId;
        const userTyped = args.data.content;
        const verse = await Util.getVerse();
        const config = await this.getConfigWithCache();
        const passingRate = config.shouldRememberIfPassingRate || 0.8;

        // 计算分数
        let score = this.getScore(userTyped, verse.a, this.blankContent, config.maxScore, config.ignoreCase);
        if ((score / config.maxScore) < passingRate) {
            score = 0;
        }
        // 更新用户状态
        if (this.userIdToUserStatus[userId]) {
            this.userIdToUserStatus[userId].score = score;
            this.userIdToUserStatus[userId].submit = userTyped;
            this.userIdToUserStatus[userId].step = StepEnum.finished; // 标记已提交
        }

        try {
            await Util.gameScoreInc(userId, score, 'i:obtainedInTheGame');
        } catch (e) {
            console.error("Sync score to DB failed", e);
        }
        await Util.broadcast(this.gameRefreshPath, this.getBroadcastData());
        return JSON.stringify({status: 200});
    },
    next: async function (args) {
        try {
            const userId = args.userId;

            const player = this.userIdToUserStatus[userId];
            if (player.step === StepEnum.finished) {
                player.nexted = true;
            } else {
                return JSON.stringify({status: 400, error: "You are not finish"});
            }
            const players = Object.values(this.userIdToUserStatus);
            if (players.length === 0) return JSON.stringify({status: 400, error: "No players"});

            const allFinished = players.every(u => u.step === StepEnum.finished);
            const allNeedToNext = players.every(u => u.nexted);

            if (allFinished && allNeedToNext) {
                const config = await this.getConfigWithCache();
                const maxScore = config.maxScore || 10;
                const passingRate = config.shouldRememberIfPassingRate || 0.8;
                if (Util.repeatFlow() === 'examine') {
                    const isAllPassed = players.every(u => (u.score / maxScore) >= passingRate);
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
        } catch (e) {
            return JSON.stringify({status: 500, error: e.toString()});
        }
    },
    myStatus: async function (args) {
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
                    data: {
                        answer: '',
                        score: 0,
                        submit: ''
                    }
                });
            }
        } catch (error) {
            return JSON.stringify({
                status: 500,
                error: error.toString()
            });
        }
    },

    setConfig: async function (args) {
        try {
            const userId = args.userId;
            const adminId = Util.adminId();
            const adminEnable = Util.adminEnable();
            if (userId === adminId && adminEnable) {
                let data = args.data;
                await Util.setConfig(data.key, data.value);
                return JSON.stringify({});
            } else {
                return JSON.stringify({status: 500, error: "not admin"});
            }
        } catch (e) {
            return JSON.stringify({status: 500, error: e.toString()});
        }
    },
    getConfig: async function () {
        try {
            let configData = await Util.getConfig();
            return JSON.stringify({
                data: configData,
            });
        } catch (error) {
            return JSON.stringify({
                status: 500,
                error: error.toString()
            });
        }
    },
    label: function () {
        try {
            let label = Util.getLabel();
            return JSON.stringify({
                data: label,
            });
        } catch (error) {
            return JSON.stringify({
                status: 500,
                error: error.toString()
            });
        }
    },
    tap: function (args) {
        try {
            let result = Util.uiTap(args.data);
            if (result !== 'success') {
                return JSON.stringify({
                    status: 500,
                    error: result + '',
                });
            }
            return JSON.stringify({});
        } catch (error) {
            return JSON.stringify({
                status: 500,
                error: error.toString()
            });
        }
    },
    resetManualBlank: async function (args) {
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
        } catch (e) {
            return JSON.stringify({status: 500, error: e.toString()});
        }
    },
    setBlankContent: async function (args) {
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
        } catch (e) {
            return JSON.stringify({status: 500, error: e.toString()});
        }
    },
    getBlankContent: async function (args) {
        try {
            const verse = await Util.getVerse();
            let savedContent = verse[Game.key];
            if (!savedContent || savedContent === '') {
                savedContent = verse['a'] || '';
            }

            return JSON.stringify({
                status: 200,
                data: {
                    blank: savedContent,
                    answer: this.answer,
                },
            });
        } catch (e) {
            return JSON.stringify({
                status: 500,
                error: e.toString()
            });
        }
    },
    clear: async function () {
        for (let id in this.userIdToUserStatus) {
            this.userIdToUserStatus[id].step = StepEnum.blanking;
            this.userIdToUserStatus[id].submit = '';
            this.userIdToUserStatus[id].score = 0;
            this.userIdToUserStatus[id].nexted = false;
        }
        const verse = await Util.getVerse();
        this.answer = verse.a || '';
        this.blankContent = await this.getBlankMix();
        if (!Util.adminEnable()) {
            await Util.broadcast(this.gameRefreshPath, this.getBroadcastData());
        }
    },
    getBroadcastData: function () {
        const userIds = this.userIds;
        const userIdToUserName = {};

        const players = userIds.map(id => {
            const user = this.userIdToUserStatus[id];

            userIdToUserName[id] = user.name;

            let ret = {
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
        let blankContent = this.blankContent;
        return {
            gameStatus: this.gameStatus,
            config: this._config,
            blankContent: this.blankContent,
            players: players,
            userIds: userIds,
            userIdToUserName: userIdToUserName,
        };
    },

    getConfigWithCache: async function (forceRefresh = false) {
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

    _shuffle: function (array) {
        for (let i = array.length - 1; i > 0; i--) {
            const j = Math.floor(Math.random() * (i + 1));
            [array[i], array[j]] = [array[j], array[i]];
        }
        return array;
    },

    getBlankMix: async function () {
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
    getBlankAuto: function (verse, config) {
        const content = verse.a || '';
        const percent = config.blankContentPercent ?? 0.5;
        const ignorePunctuation = config.ignorePunctuation ?? true;

        if (percent <= 0 || content.length === 0) {
            return content;
        }

        const chars = content.split('');
        const blankableIndexes = [];

        // 1. 筛选哪些位置可以被挖空
        for (let i = 0; i < chars.length; i++) {
            const char = chars[i];
            if (char === ' ') continue; // 跳过空格

            if (ignorePunctuation && this.punctuationRegex.test(char)) {
                this.punctuationRegex.lastIndex = 0; // 重置正则状态
                continue;
            }
            blankableIndexes.push(i);
        }

        // 2. 执行挖空操作
        if (blankableIndexes.length > 0) {
            // 计算需要隐藏的数量 (至少 1 个)
            let hideCount = Math.round(blankableIndexes.length * percent);
            hideCount = Math.max(1, hideCount);

            // 随机打乱索引
            this._shuffle(blankableIndexes);

            // 将选中索引处的字符替换为圆点
            for (let i = 0; i < hideCount && i < blankableIndexes.length; i++) {
                chars[blankableIndexes[i]] = '•';
            }
        }

        return chars.join('');
    },

    getBlankManual: function (verseMap, ignorePunctuation) {
        const a = verseMap.a || '';
        const b = verseMap[this.key] || ''; // 用户当前输入或已保存的进度
        if (b === '') {
            return ''
        }
        if (!b && !ignorePunctuation) return '•'.repeat(a.length);

        let result = '';
        for (let i = 0; i < a.length; i++) {
            const aChar = a[i];

            // 如果是标点且开启了忽略，直接显示
            if (ignorePunctuation && this.punctuationRegex.test(aChar)) {
                this.punctuationRegex.lastIndex = 0;
                result += aChar;
                continue;
            }

            // 如果超出用户输入长度，显示圆点
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

    getScore: function (userAnswer, correctAnswer, blank, maxScore, ignoreCase) {
        let blankCount = 0;
        let rightCount = 0;
        const len = Math.min(userAnswer.length, correctAnswer.length, blank.length);

        for (let i = 0; i < len; i++) {
            if (blank[i] === '•') {
                blankCount++;
                let u = userAnswer[i];
                let c = correctAnswer[i];
                if (ignoreCase ? u.toLowerCase() === c.toLowerCase() : u === c) {
                    rightCount++;
                }
            }
        }
        return blankCount > 0 ? Math.floor((rightCount / blankCount) * maxScore) : 0;
    }


};