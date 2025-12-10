export class GameUserScoreHistoryReq {
    readonly lastId?: number;
    readonly pageSize: number;

    constructor(
        pageSize: number,
        lastId?: number
    ) {
        this.pageSize = pageSize;
        this.lastId = lastId;
    }
}