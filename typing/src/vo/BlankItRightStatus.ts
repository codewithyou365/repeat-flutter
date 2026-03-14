export class PlayerStatus {
    userId: number = 0;
    name: string = '';
    step: string = 'blanking';
    submit: string = '';
    score: number = 0;

    constructor(init?: Partial<PlayerStatus>) {
        Object.assign(this, init);
    }
}

export class GameConfig {
    autoBlank: boolean = true;
    blankContentPercent: number = 5;
    ignorePunctuation: boolean = true;
    [key: string]: any;

    constructor(init?: Partial<GameConfig>) {
        Object.assign(this, init);
    }
}

export class BlankItRightStatus {
    gameStatus: string = 'init';
    config: GameConfig | null = null;
    blankContent: string = '';

    // Lists and Mappings
    players: PlayerStatus[] = [];
    userIds: number[] = [];
    userIdToUserName: Record<number, string> = {};

    // Helper index for the local user
    currUserIndex: number = -1;

    constructor(init?: Partial<BlankItRightStatus>) {
        if (init) {
            Object.assign(this, init);

            // Explicitly cast nested objects to classes if needed
            if (init.players) {
                this.players = init.players.map(p => new PlayerStatus(p));
            }
            if (init.config) {
                this.config = new GameConfig(init.config);
            }
        }
    }

    /**
     * Helper: Get the current player's status object
     */
    get self(): PlayerStatus | null {
        if (this.currUserIndex >= 0 && this.currUserIndex < this.players.length) {
            return this.players[this.currUserIndex];
        }
        return null;
    }
}