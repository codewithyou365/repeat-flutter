export enum GameStepEnum {
    none,
    selectRule,
    started,
}

export class WordSlicerStatus {
    gameStep: GameStepEnum = GameStepEnum.none;
    colorIndexToUserId: number[][] = [[], [], []];
    userIds: number[] = [];
    userIdToUserName: Record<number, string> = {};
    currUserIndex: number = -1;
    judgeUserId: number = -1;

    static fromJson(json: any): WordSlicerStatus {
        const status = new WordSlicerStatus();

        if (json.gameStep) {
            status.gameStep = GameStepEnum[json.gameStep as keyof typeof GameStepEnum] ?? GameStepEnum.none;
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

        status.judgeUserId =
            typeof json.judgeUserId === "number"
                ? json.judgeUserId
                : -1;

        return status;
    }
}