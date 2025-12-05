export class BlankItRightSubmitReq {
    verseId: number;
    content: string;

    constructor() {
        this.verseId = 0;
        this.content = '';
    }
}

export class BlankItRightSubmitRes {
    score: number;
    answer: string;

    constructor(score: number, answer: string) {
        this.score = score;
        this.answer = answer;
    }

    static fromJson(json: any): BlankItRightSubmitRes {
        return new BlankItRightSubmitRes(
            json.score as number,
            json.answer as string
        );
    }
}