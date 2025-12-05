export class BlankItRightBlankReq {
    verseId: number;
    content: string;
    clearBeforeAdd: boolean;

    constructor() {
        this.verseId = 0;
        this.content = '';
        this.clearBeforeAdd = true;
    }
}