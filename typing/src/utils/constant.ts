import {toNumber} from './convert.ts';

export const Path = {
    kick: '/api/kick',
    refreshGame: '/api/refreshGame',

    loginOrRegister: '/api/loginOrRegister',
    contentKey: '/api/contentKey',
    heart: '/api/heart',
    gameAdmin: '/api/gameAdmin',
    game: '/api/game',
    tip: '/api/tip',
    gameUserScoreHistory: '/api/gameUserScoreHistory',
    gameUserScore: '/api/gameUserScore',
    gameUserScoreMinus: '/api/gameUserScoreMinus',

    blankItRightSettings: '/api/blankItRightSettings',
    blankItRightContent: '/api/blankItRightContent',
    blankItRightBlank: '/api/blankItRightBlank',
    blankItRightSubmit: '/api/blankItRightSubmit',
    wordSlicerStatus: '/api/wordSlicerStatus',
    wordSlicerStatusUpdate: '/api/wordSlicerStatusUpdate',
    wordSlicerSelectRole: '/api/wordSlicerSelectRole',
    wordSlicerChooseColor: '/api/wordSlicerChooseColor',
    wordSlicerStartGame: '/api/wordSlicerStartGame',
    wordSlicerSubmit: '/api/wordSlicerSubmit',
    wordSlicerEdit: '/api/wordSlicerEdit',
    submit: '/api/submit',

}

export class ContentType {
    constructor(
        public code: number,
        public path: string
    ) {
    }

    static NONE = new ContentType(0, '');
    static TYPE = new ContentType(1, '/game/type-game');
    static BLANK_IT_RIGHT = new ContentType(2, '/game/blank-it-right-game');
    static WORD_SLICER = new ContentType(3, '/game/word-slicer-game');
    static INPUT = new ContentType(4, '/game/input-game');
    static JAPANESE_A = new ContentType(5, '/tip/japanese/a');
    static JAPANESE_Q = new ContentType(6, '/tip/japanese/q');
    static JAPANESE_T = new ContentType(7, '/tip/japanese/t');
    static JAPANESE_N = new ContentType(8, '/tip/japanese/n');

    static toContentType(code: String): ContentType {
        switch (code) {
            case 'Type':
                return ContentType.TYPE;
            case 'BlankItRight':
                return ContentType.BLANK_IT_RIGHT;
            case 'WordSlicer':
                return ContentType.WORD_SLICER;
            case 'Input':
                return ContentType.INPUT;
            case 'JapaneseA':
                return ContentType.JAPANESE_A;
            case 'JapaneseQ':
                return ContentType.JAPANESE_Q;
            case 'JapaneseT':
                return ContentType.JAPANESE_T;
            case 'JapaneseN':
                return ContentType.JAPANESE_N;
            default:
                return ContentType.NONE;
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
