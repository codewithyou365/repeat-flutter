import {toNumber} from './convert.ts';

export const Path = {
    kick: '/api/kick',
    refreshGame: '/api/refreshGame',

    heart: '/api/heart',
    loginOrRegister: '/api/loginOrRegister',
    entryGame: '/api/entryGame',
    gameUserHistory: '/api/gameUserHistory',
    submit: '/api/submit',
    getEditStatus: '/api/getEditStatus',
    getSegmentContent: '/api/getSegmentContent',
    setSegmentContent: '/api/setSegmentContent',

}

export class GameType {
    constructor(
        public code: number,
        public path: string
    ) {
    }

    static NONE = new GameType(0, '');
    static TYPE = new GameType(1, '/game/type-game');
    static BLANK_IT_RIGHT = new GameType(2, '/game/blank-it-right-game');
    static INPUT = new GameType(3, '/game/input-game');

    static toGameType(code: number): GameType {
        switch (code) {
            case GameType.TYPE.code:
                return GameType.TYPE;
            case GameType.BLANK_IT_RIGHT.code:
                return GameType.BLANK_IT_RIGHT;
            case GameType.INPUT.code:
                return GameType.INPUT;
            default:
                return GameType.NONE;
        }
    }
}


export class GameUserHistoryReq {
    gameId: number;
    time: number;

    constructor() {
        this.gameId = 0;
        this.time = 0;
    }

    static from(other: any): GameUserHistoryReq {
        const ret = new GameUserHistoryReq();
        ret.gameId = other.gameId || 0;
        ret.time = other.time || 0;
        return ret;
    }
}

export class GameUserHistoryRes {
    list: SubmitRes[];
    tips: string[];

    constructor() {
        this.list = [];
        this.tips = [];
    }

    static from(other: any): GameUserHistoryRes {
        const ret = new GameUserHistoryRes();
        ret.list = other.list;
        ret.tips = other.tips;
        return ret;
    }
}

export class SubmitReq {
    gameId: number;
    prevId: number;
    input: string;

    constructor() {
        this.gameId = 0;
        this.prevId = 0;
        this.input = '';
    }

    static from(other: any): SubmitReq {
        const ret = new SubmitReq();
        ret.gameId = other.gameId || 0;
        ret.prevId = other.prevId || 0;
        ret.input = other.input || '';
        return ret;
    }
}

export enum MatchType {
    word = 0,
    single = 1,
    all = 2,
}

export class SubmitRes {
    id: number;
    input: string[];
    output: string[];
    matchType: number;


    constructor() {
        this.id = 0;
        this.input = [];
        this.output = [];
        this.matchType = 0;
    }

    static from(json: any): SubmitRes {
        const ret = new SubmitRes();
        ret.id = toNumber(json.id);
        ret.input = json.input || [];
        ret.output = json.output || [];
        ret.matchType = toNumber(json.matchType);
        return ret;
    }
}


export class GetSegmentContentReq {
    gameId: number;

    constructor() {
        this.gameId = 0;
    }

    static from(other: any): GetSegmentContentReq {
        const ret = new GetSegmentContentReq();
        ret.gameId = other.gameId || 0;
        return ret;
    }
}


export class GetSegmentContentRes {
    content: string;

    constructor() {
        this.content = '';
    }

    static from(other: any): GetSegmentContentRes {
        const ret = new GetSegmentContentRes();
        ret.content = other.content || 0;
        return ret;
    }
}


export class SetSegmentContentReq {
    gameId: number;
    content: string;

    constructor() {
        this.gameId = 0;
        this.content = '';
    }

    static from(other: any): SetSegmentContentReq {
        const ret = new SetSegmentContentReq();
        ret.gameId = other.gameId || 0;
        ret.content = other.content || 0;
        return ret;
    }
}

