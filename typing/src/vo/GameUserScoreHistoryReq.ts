export class GameUserScoreHistoryReq {
    readonly lastId?: number;
    readonly gameType: number;
    readonly pageSize: number;

    constructor(
        gameType: number,
        pageSize: number,
        lastId?: number
    ) {
        this.gameType = gameType;
        this.pageSize = pageSize;
        this.lastId = lastId;
    }
}