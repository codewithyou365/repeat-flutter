import {toNumber} from './convert.ts';

export const Path = {
    kick: '/api/kick',
    refreshGame: '/api/refreshGame',

    loginOrRegister: '/api/loginOrRegister',
    gameKey: '/api/gameKey',
    heart: '/api/heart',
    gameAdmin: '/api/gameAdmin',
    game: '/api/game',
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

export class GameType {
    constructor(
        public code: number,
        public path: string
    ) {
    }

    static NONE = new GameType(0, '');
    static TYPE = new GameType(1, '/game/type-game');
    static BLANK_IT_RIGHT = new GameType(2, '/game/blank-it-right-game');
    static WORD_SLICER = new GameType(3, '/game/word-slicer-game');
    static INPUT = new GameType(4, '/game/input-game');
    static JAPAN = new GameType(5, '/game/japan-game');

    static toGameType(code: String): GameType {
        switch (code) {
            case 'Type':
                return GameType.TYPE;
            case 'BlankItRight':
                return GameType.BLANK_IT_RIGHT;
            case 'WordSlicer':
                return GameType.WORD_SLICER;
            case 'Input':
                return GameType.INPUT;
            case 'Japan':
                return GameType.JAPAN;
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
