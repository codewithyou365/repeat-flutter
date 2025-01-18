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

    constructor() {
        this.list = [];
    }

    static from(other: any): GameUserHistoryRes {
        const ret = new GameUserHistoryRes();
        ret.list = other.list;
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

export class SubmitRes {
    id: number;
    input: string[];
    output: string[];

    constructor() {
        this.id = 0;
        this.input = [];
        this.output = [];
    }

    static from(json: any): SubmitRes {
        const ret = new SubmitRes();
        ret.id = toNumber(json.id);
        ret.input = json.input || [];
        ret.output = json.output || [];
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

