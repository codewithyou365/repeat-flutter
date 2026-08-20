export class ShadowPhone {
    /// IPA 符号
    p: string = '';
    start: number = 0;
    end: number = 0;
    score: number = 0;
    /// 'ok' / 'sub' / 'del'
    status: string = 'ok';

    constructor(init?: Partial<ShadowPhone>) {
        Object.assign(this, init);
    }
}

export class ShadowWord {
    w: string = '';
    start: number = 0;
    end: number = 0;
    score: number = 0;
    /// 'good' / 'fair' / 'bad'。**阈值由服务端定**，前端直接拿它上色——
    /// 前端自己定阈值的话，改校准要改两处。
    level: string = 'fair';
    /// 漏读
    missed: boolean = false;
    phones: ShadowPhone[] = [];

    constructor(init?: Partial<ShadowWord>) {
        if (init) {
            Object.assign(this, init);
            this.phones = (init.phones || []).map((p: any) => new ShadowPhone(p));
        }
    }
}

export class ShadowResult {
    overall: number = 0;
    accuracy: number = 0;
    completeness: number = 0;
    fluency: number = 0;
    durationMs: number = 0;
    speechMs: number = 0;
    /// 本地 ASR 粗评分的结果，没有音素信息
    degraded: boolean = false;
    /// 读的根本不是这句。UI 必须显式提示，否则用户会以为是自己发音差。
    mismatch: boolean = false;
    words: ShadowWord[] = [];
    missedWords: string[] = [];
    /// 多读的音素数
    insertions: number = 0;

    constructor(init?: Partial<ShadowResult>) {
        if (init) {
            Object.assign(this, init);
            this.words = (init.words || []).map((w: any) => new ShadowWord(w));
            this.missedWords = init.missedWords || [];
        }
    }
}

export class ShadowRecorderState {
    /// idle / recording / recorded / scoring / done / failed
    state: string = 'idle';
    elapsedMs: number = 0;
    levelDb: number = -60;
    /// 打分服务挂了，这局剩下的都会走降级
    remoteDown: boolean = false;

    constructor(init?: Partial<ShadowRecorderState>) {
        Object.assign(this, init);
    }
}

export class ShadowConfig {
    autoListen: boolean = true;
    ttsRate: number = 1.0;
    maxRecordMs: number = 15000;
    maxAttempts: number = 3;
    passThreshold: number = 65;
    star1: number = 65;
    star2: number = 80;
    star3: number = 90;
    maxScore: number = 10;
    showPhones: boolean = true;
    autoNextOnPass: boolean = false;

    [key: string]: any;

    constructor(init?: Partial<ShadowConfig>) {
        Object.assign(this, init);
    }
}

export class ShadowStatus {
    /// ready / recording / scoring / result / noText
    phase: string = 'ready';
    roundId: number = 0;
    attempt: number = 1;
    maxAttempts: number = 3;
    text: string = '';
    /// 本轮最高分。重试免费，只取最高。
    best: number = 0;
    stars: number = 0;
    passed: boolean = false;
    result: ShadowResult | null = null;
    error: string = '';
    degraded: boolean = false;
    recorder: ShadowRecorderState = new ShadowRecorderState();
    config: ShadowConfig = new ShadowConfig();
    labels: Record<string, string> = {};

    constructor(init?: Partial<ShadowStatus>) {
        if (init) {
            Object.assign(this, init);
            this.result = init.result ? new ShadowResult(init.result) : null;
            this.recorder = new ShadowRecorderState(init.recorder || {});
            this.config = new ShadowConfig(init.config || {});
        }
    }
}
