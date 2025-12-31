export enum GameStepEnum {
    none,
    selectRule,
    started,
    finished,
}

export class WordSlicerStatus {
    verseId: number = -1;
    gameStep: GameStepEnum = GameStepEnum.none;
    colorIndexToUserId: number[][] = [[], [], []];
    userIds: number[] = [];
    userIdToUserName: Record<number, string> = {};
    currUserIndex: number = -1;
    content: string = '';
    colorIndexToSelectedContentIndex: number[][] = [[], [], []];

    static fromJson(json: any): WordSlicerStatus {
        const status = new WordSlicerStatus();

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

        status.colorIndexToSelectedContentIndex =
            Array.isArray(json.colorIndexToSelectedContentIndex)
                ? json.colorIndexToSelectedContentIndex
                : [];

        return status;
    }
}