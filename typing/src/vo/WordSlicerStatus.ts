export enum GameStepEnum {
    none,
    selectRule,
    started,
    finished,
}

export class Stat {
    rightCount: number = 0;
    errorCount: number = 0;
    score: number = 0;

    static fromJson(json: any): Stat {
        const stat = new Stat();
        if (json) {
            stat.rightCount = typeof json.rightCount === 'number' ? json.rightCount : 0;
            stat.errorCount = typeof json.errorCount === 'number' ? json.errorCount : 0;
            stat.score = typeof json.score === 'number' ? json.score : 0;
        }
        return stat;
    }
}

export class Word {
    start: number;
    end: number;
    word: string;
    colorIndex: number;
    right: boolean;

    constructor(params: {
        start: number;
        end: number;
        word?: string;
        colorIndex?: number;
        right?: boolean;
    }) {
        this.start = params.start;
        this.end = params.end;
        this.word = params.word ?? '';
        this.colorIndex = params.colorIndex ?? -1;
        this.right = params.right ?? false;
    }
}

export class WordSlicerStatus {
    maxScore: number = 10;
    verseId: number = -1;
    gameStep: GameStepEnum = GameStepEnum.none;
    colorIndexToUserId: number[][] = [[], [], []];
    userIds: number[] = [];
    userIdToUserName: Record<number, string> = {};
    currUserIndex: number = -1;
    content: string = '';
    answer: string = '';
    colorIndexToSelectedContentIndex: number[][] = [[], [], []];
    colorIndexToStat: Stat[] = [new Stat(), new Stat(), new Stat()];
    userIdToScore: Record<number, number> = {};

    static fromJson(json: any): WordSlicerStatus {
        const status = new WordSlicerStatus();

        status.maxScore = json.maxScore;
        status.verseId = json.verseId;

        if (json.gameStep !== undefined) {
            if (typeof json.gameStep === 'string') {
                status.gameStep = GameStepEnum[json.gameStep as keyof typeof GameStepEnum] ?? GameStepEnum.none;
            } else {
                status.gameStep = json.gameStep;
            }
        }

        status.colorIndexToUserId = Array.isArray(json.colorIndexToUserId)
            ? json.colorIndexToUserId
            : [[], [], []];

        status.userIds = Array.isArray(json.userIds)
            ? json.userIds
            : [];

        status.userIdToUserName =
            json.userIdToUserName && typeof json.userIdToUserName === "object"
                ? json.userIdToUserName
                : {};

        status.currUserIndex =
            typeof json.currUserIndex === "number"
                ? json.currUserIndex
                : -1;

        status.content = json.content || '';
        status.answer = json.answer || '';

        status.colorIndexToSelectedContentIndex =
            Array.isArray(json.colorIndexToSelectedContentIndex)
                ? json.colorIndexToSelectedContentIndex
                : [];

        if (Array.isArray(json.colorIndexToStat)) {
            status.colorIndexToStat = json.colorIndexToStat.map((s: any) => Stat.fromJson(s));
        }
        status.userIdToScore = json.userIdToScore;
        return status;
    }


    getColorIndexToWords(): Word[] {
        const result: Word[] = [];

        for (let i = 0; i < 3; i++) {
            const selectedIndexes = Array.from(
                new Set(this.colorIndexToSelectedContentIndex[i]),
            );
            result.push(...this.extractConsecutiveWord(selectedIndexes, i));
        }

        result.sort((a, b) => a.start - b.start);

        for (const ele of result) {
            ele.word = this.content.substring(ele.start, ele.end + 1);
        }

        return result;
    }

    getAnswerWords(): Word[] {
        const result: Word[] = [];
        if (!this.answer || !this.content) return result;

        const words = this.answer.split(' ');
        let cursor = 0;
        for (const w of words) {
            if (!w) continue;

            const start = cursor;
            const end = cursor + w.length - 1;

            result.push(
                new Word({
                    start,
                    end,
                    word: w,
                }),
            );

            cursor += w.length;
        }

        return result;
    }

    scoreEachChar(): string {
        return (this.maxScore / this.content.length).toFixed(2);
    }

    getResult(): Word[] {

        if (!this.content.length) return [];

        const answerWords = this.getAnswerWords();
        const selectedWords = this.getColorIndexToWords();
        for (const selected of selectedWords) {
            let hit = false;

            for (const answer of answerWords) {
                if (answer.start === selected.start) {
                    hit = true;
                    selected.right = answer.word === selected.word;
                    break;
                }
            }

            if (!hit) {
                selected.right = false;
            }
        }

        return selectedWords;
    }

    extractConsecutiveWord(
        indexes: number[],
        colorIndex: number,
    ): Word[] {
        if (!indexes.length) return [];

        const sorted = [...indexes].sort((a, b) => a - b);

        const ranges: Word[] = [];

        let start = sorted[0];
        let end = start;

        for (let i = 1; i < sorted.length; i++) {
            if (sorted[i] === end + 1) {
                end = sorted[i];
            } else {
                ranges.push(
                    new Word({
                        start,
                        end,
                        colorIndex,
                    }),
                );
                start = end = sorted[i];
            }
        }

        ranges.push(
            new Word({
                start,
                end,
                colorIndex,
            }),
        );

        return ranges;
    }

}