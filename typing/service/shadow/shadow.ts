// 跟读打分游戏的服务端逻辑。
//
// 这个文件被整体 evaluate 进 Dart 里的 JS 引擎，所以**必须是无 import 的单文件**——
// 带 import 的 ES module 产物是运行时炸，不是编译时报错。
//
// **为什么是轮询式而不是"录完给我分数"**：
// Dart 那边 JsRuntime.invoke 给每个 Game.* 只有 5 秒（handlePromise 的 timeout），
// 超时会返回 500 并且泄漏一个 20ms 的 Timer.periodic；网页 ws.ts 还有一层 10 秒超时。
// 而一次"听→录→打分"是 5~30 秒。所以每个方法都立刻返回，网页在
// phase ∈ {recording, scoring} 期间按 300ms 调 Game.poll 拿进度。

declare function sendMessage(method: string, payload: string): any;

type JsonRecord = Record<string, any>;

type VerseField = {
    text?: string;
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

const Util = {
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
        const defaultValue: JsonRecord = {
            // 进入一轮时自动播一遍参考音
            autoListen: true,
            ttsRate: 1.0,
            // 录音上限，到点自动停。Dart 那边也有一份同样的定时器兜底。
            maxRecordMs: 15000,
            // 重试次数。重试免费，只取最高分。
            maxAttempts: 3,
            // 及格线：到这个分才发积分，examine 流程下也才算过
            passThreshold: 65,
            star1: 65,
            star2: 80,
            star3: 90,
            maxScore: 10,
            // 点词看音素明细
            showPhones: true,
            // 拿 2 星以上自动进下一句（先让人看清结果）
            autoNextOnPass: false,
        };
        try {
            const data = await sendMessage('getData', '{}');
            if (data == null || data === '') {
                return defaultValue;
            }
            const parsed = JSON.parse(data);
            // 老存档里没有的键要补上默认值，否则加了新配置项的那一版会读到 undefined
            return Object.assign({}, defaultValue, parsed);
        } catch (e) {
            return defaultValue;
        }
    },
    setConfig: async function (key: string, value: any): Promise<void> {
        const data = await this.getConfig();
        data[key] = value;
        await sendMessage('setData', JSON.stringify(data));
    },
    // q/a/t 的正文在字段块里（{text,start,end,...}），n 这类没有媒体的字段是平铺字符串。
    fieldText: function (verse: Verse | null | undefined, acronym: string): string {
        const v = verse ? verse[acronym] : null;
        if (typeof v === 'string') return v;
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
    getLabel: function (): JsonRecord {
        try {
            return {
                'left': sendMessage('uiLabel', JSON.stringify({'name': 'left'})),
                'right': sendMessage('uiLabel', JSON.stringify({'name': 'right'})),
                'middle': sendMessage('uiLabel', JSON.stringify({'name': 'middle'})),
            };
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
    gameScoreInc: async function (userId: number, score: number, remark = ''): Promise<string> {
        try {
            return await sendMessage('gameScoreInc', JSON.stringify({userId, score, remark}));
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
    // **不要 await 这个**：Dart 侧 tts_helper 设了 awaitSpeakCompletion(true)，
    // 会一直等到播完。长句子光是播放就能撑爆 Game.* 的 5 秒预算。
    tts: function (payload: any): void {
        try {
            sendMessage('tts', JSON.stringify(payload ?? {}));
        } catch (e) {
            console.error("tts failed:", e);
        }
    },
    // ---- 跟读录音的五个桥。Dart 侧见 lib/logic/game_server/shadow_recorder.dart ----
    shadowStart: async function (payload: any): Promise<string> {
        try {
            const ret = await sendMessage('shadowStart', JSON.stringify(payload ?? {}));
            return typeof ret === 'string' ? ret : 'error';
        } catch (e) {
            return 'error: ' + e;
        }
    },
    shadowStop: function (text: string): string {
        try {
            const ret = sendMessage('shadowStop', JSON.stringify({text}));
            return typeof ret === 'string' ? ret : 'error';
        } catch (e) {
            return 'error';
        }
    },
    shadowCancel: function (): string {
        try {
            return sendMessage('shadowCancel', '{}');
        } catch (e) {
            return 'error';
        }
    },
    shadowStatus: function (): JsonRecord {
        try {
            const data = sendMessage('shadowStatus', '{}');
            if (data == null || data === '') {
                return {state: 'idle', token: 0};
            }
            const parsed = typeof data === 'string' ? JSON.parse(data) : data;
            return (parsed && typeof parsed === 'object') ? parsed : {state: 'idle', token: 0};
        } catch (e) {
            return {state: 'idle', token: 0};
        }
    },
    shadowHealth: async function (): Promise<JsonRecord> {
        try {
            const data = await sendMessage('shadowHealth', '{}');
            if (data == null || data === '') {
                return {};
            }
            const parsed = typeof data === 'string' ? JSON.parse(data) : data;
            return (parsed && typeof parsed === 'object') ? parsed : {};
        } catch (e) {
            return {};
        }
    },
};

const PhaseEnum = {
    // 可以听、可以开录
    ready: 'ready',
    recording: 'recording',
    scoring: 'scoring',
    result: 'result',
    // 这一句没有英文原文，跟读不了
    noText: 'noText',
};

const Game = {
    gameRefreshPath: 'gameRefresh',

    phase: PhaseEnum.ready,
    // 每换一句 +1。用来给"发分"和"推进流程"做幂等守卫。
    roundId: 0,
    attempt: 1,
    text: '',
    // 本轮最高分。重试免费，只取最高。
    best: 0,
    result: null as JsonRecord | null,
    error: '',
    degraded: false,

    // 已经发过分的轮次。uiTap 和 gameScoreInc 都不幂等，
    // 重复调用会一次跳掉好几个 verse / 重复计分。
    scoredRoundId: -1,
    completedRoundId: -1,

    // 上一次看到的录音器 token。打分结果按它认领，
    // 用户放弃这一轮之后迟到的分数不会糊到新句子上。
    lastToken: -1,

    _config: null as JsonRecord | null,

    config: async function (): Promise<JsonRecord> {
        if (this._config == null) {
            this._config = await Util.getConfig();
        }
        return this._config;
    },

    stars: function (cfg: JsonRecord): number {
        if (this.best >= cfg.star3) return 3;
        if (this.best >= cfg.star2) return 2;
        if (this.best >= cfg.star1) return 1;
        return 0;
    },

    buildStatus: async function (): Promise<JsonRecord> {
        const cfg = await this.config();
        const rec = Util.shadowStatus();
        return {
            phase: this.phase,
            roundId: this.roundId,
            attempt: this.attempt,
            maxAttempts: cfg.maxAttempts,
            text: this.text,
            best: this.best,
            stars: this.stars(cfg),
            passed: this.best >= cfg.passThreshold,
            result: this.result,
            error: this.error,
            degraded: this.degraded,
            recorder: {
                state: rec.state || 'idle',
                elapsedMs: rec.elapsedMs || 0,
                levelDb: typeof rec.levelDb === 'number' ? rec.levelDb : -60,
                remoteDown: rec.remoteDown === true,
            },
            config: cfg,
            labels: Util.getLabel(),
        };
    },

    push: async function (): Promise<void> {
        await Util.broadcast(this.gameRefreshPath, await this.buildStatus());
    },

    reset: async function (): Promise<void> {
        this.attempt = 1;
        this.best = 0;
        this.result = null;
        this.error = '';
        this.degraded = false;
        this.lastToken = -1;
        Util.shadowCancel();

        const verse = await Util.getVerse();
        this.text = (Util.fieldText(verse, 'a') || '').trim();
        // a 字段可能是空的（有些材料只有问句），这时跟读不了，
        // 直接告诉用户而不是把空串喂进 g2p。
        this.phase = this.text === '' ? PhaseEnum.noText : PhaseEnum.ready;
    },

    // ---- 网页调的方法。全部立刻返回。 ----

    getStatus: async function (args: GameArgs): Promise<string> {
        try {
            if (this.text === '' && this.phase !== PhaseEnum.noText) {
                await this.reset();
            }
            return JSON.stringify({status: 200, data: await this.buildStatus()});
        } catch (e: any) {
            return JSON.stringify({status: 500, error: e.toString()});
        }
    },

    listen: async function (args: GameArgs): Promise<string> {
        try {
            if (this.text === '') {
                return JSON.stringify({status: 400, error: 'shadowNoText'});
            }
            const cfg = await this.config();
            // 不 await：tts 会等到播完，长句子会撑爆 5 秒预算。
            Util.tts({text: this.text, type: 'a', rate: cfg.ttsRate, manual: true});
            return JSON.stringify({status: 200});
        } catch (e: any) {
            return JSON.stringify({status: 500, error: e.toString()});
        }
    },

    startRecord: async function (args: GameArgs): Promise<string> {
        try {
            if (this.text === '') {
                return JSON.stringify({status: 400, error: 'shadowNoText'});
            }
            const cfg = await this.config();
            this.error = '';
            this.result = null;
            // text 一并传下去：这样 maxRecordMs 到点自动停时 Dart 能直接进打分，
            // 不用等网页再来一次 stopRecord。
            const ret = await Util.shadowStart({maxMs: cfg.maxRecordMs, text: this.text});
            if (ret !== 'ok') {
                this.error = ret === 'no_permission' ? 'shadowNoMic' : ret;
                await this.push();
                return JSON.stringify({status: 400, error: this.error});
            }
            this.phase = PhaseEnum.recording;
            this.lastToken = Util.shadowStatus().token;
            await this.push();
            return JSON.stringify({status: 200});
        } catch (e: any) {
            return JSON.stringify({status: 500, error: e.toString()});
        }
    },

    stopRecord: async function (args: GameArgs): Promise<string> {
        try {
            const ret = Util.shadowStop(this.text);
            if (ret !== 'ok') {
                return JSON.stringify({status: 400, error: ret});
            }
            this.phase = PhaseEnum.scoring;
            await this.push();
            return JSON.stringify({status: 200});
        } catch (e: any) {
            return JSON.stringify({status: 500, error: e.toString()});
        }
    },

    cancelRecord: async function (args: GameArgs): Promise<string> {
        try {
            Util.shadowCancel();
            if (this.phase === PhaseEnum.recording || this.phase === PhaseEnum.scoring) {
                this.phase = PhaseEnum.ready;
            }
            await this.push();
            return JSON.stringify({status: 200});
        } catch (e: any) {
            return JSON.stringify({status: 500, error: e.toString()});
        }
    },

    /// 唯一被定时调用的方法。幂等：同一个 token 的结果只处理一次。
    poll: async function (args: GameArgs): Promise<string> {
        try {
            const rec = Util.shadowStatus();

            if (rec.state === 'recorded') {
                // maxRecordMs 到点自动停了，但 Dart 那边没拿到参考文本。
                // 补一次 stop，让它进打分。
                Util.shadowStop(this.text);
                this.phase = PhaseEnum.scoring;
            } else if (rec.state === 'done' && this.phase === PhaseEnum.scoring) {
                await this.applyResult(args, rec);
            } else if (rec.state === 'failed' && this.phase === PhaseEnum.scoring) {
                this.error = rec.error || 'shadowScoreFailed';
                this.phase = PhaseEnum.ready;
            }
            return JSON.stringify({status: 200, data: await this.buildStatus()});
        } catch (e: any) {
            return JSON.stringify({status: 500, error: e.toString()});
        }
    },

    applyResult: async function (args: GameArgs, rec: JsonRecord): Promise<void> {
        const cfg = await this.config();
        const r = rec.result as JsonRecord | null;
        if (!r) {
            this.error = rec.error || 'shadowScoreFailed';
            this.phase = PhaseEnum.ready;
            return;
        }
        this.result = r;
        this.degraded = r.degraded === true;
        const overall = typeof r.overall === 'number' ? r.overall : 0;
        if (overall > this.best) {
            this.best = overall;
        }
        this.phase = PhaseEnum.result;

        // 发分。scoredRoundId 守卫：重试不重复计分。
        if (this.scoredRoundId !== this.roundId && this.best >= cfg.passThreshold) {
            this.scoredRoundId = this.roundId;
            const userId = args && args.userId ? args.userId : 0;
            if (userId) {
                const score = Math.round(cfg.maxScore * this.best / 100);
                if (score > 0) {
                    await Util.gameScoreInc(userId, score, 'i:obtainedInTheGame');
                }
            }
        }
    },

    retry: async function (args: GameArgs): Promise<string> {
        try {
            const cfg = await this.config();
            if (this.attempt >= cfg.maxAttempts) {
                return JSON.stringify({status: 400, error: 'shadowNoMoreAttempts'});
            }
            this.attempt += 1;
            this.result = null;
            this.error = '';
            this.phase = PhaseEnum.ready;
            Util.shadowCancel();
            await this.push();
            return JSON.stringify({status: 200});
        } catch (e: any) {
            return JSON.stringify({status: 500, error: e.toString()});
        }
    },

    next: async function (args: GameArgs): Promise<string> {
        try {
            // completedRoundId 守卫：uiTap 不幂等，重复调用会一次跳掉好几个 verse。
            if (this.completedRoundId === this.roundId) {
                return JSON.stringify({status: 200, data: 'already'});
            }
            this.completedRoundId = this.roundId;
            const cfg = await this.config();
            Util.shadowCancel();

            if (Util.repeatFlow() === 'browse') {
                Util.uiTap('tapLeft');
            } else if (this.best >= cfg.passThreshold) {
                Util.uiTap('tapLeft');
            } else {
                // 读得差就把这句重新排队，而不是标记成已学会
                Util.uiTap('tapRight');
            }
            return JSON.stringify({status: 200});
        } catch (e: any) {
            return JSON.stringify({status: 500, error: e.toString()});
        }
    },

    health: async function (args: GameArgs): Promise<string> {
        try {
            return JSON.stringify({status: 200, data: await Util.shadowHealth()});
        } catch (e: any) {
            return JSON.stringify({status: 500, error: e.toString()});
        }
    },

    getConfig: async function (args: GameArgs): Promise<string> {
        try {
            return JSON.stringify({status: 200, data: await this.config()});
        } catch (e: any) {
            return JSON.stringify({status: 500, error: e.toString()});
        }
    },

    setConfig: async function (args: GameArgs): Promise<string> {
        try {
            const adminId = Util.adminId();
            const adminEnable = Util.adminEnable();
            if (!adminEnable || adminId !== args.userId) {
                return JSON.stringify({status: 403, error: 'only_admin_can_edit'});
            }
            const data = args.data;
            if (!data || typeof data.key !== 'string') {
                return JSON.stringify({status: 400});
            }
            await Util.setConfig(data.key, data.value);
            this._config = null;
            await this.push();
            return JSON.stringify({status: 200});
        } catch (e: any) {
            return JSON.stringify({status: 500, error: e.toString()});
        }
    },

    /// 换句子。Dart 那边通过 subNewVerse 调过来。
    ///
    /// **只能靠这个钩子判断换轮，不能 diff 文本**：getVerse 只返回内容 JSON、
    /// 不带 id，而相邻两句完全可能文本相同。
    onNewVerse: async function (): Promise<string> {
        try {
            this.roundId += 1;
            await this.reset();
            await this.push();
            return JSON.stringify({status: 200});
        } catch (e: any) {
            return JSON.stringify({status: 500, error: e.toString()});
        }
    },
};
