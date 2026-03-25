declare function sendMessage(method: string, payload: string): any;

type JsonRecord = Record<string, any>;

type Config = {
    ignorePunctuation: boolean;
    ignoreCase: boolean;
    [key: string]: any;
};

type Verse = {
    a?: string;
    [key: string]: any;
};

type GameArgs = {
    userId: number;
    data: any;
};

const Util = {
    getConfig: async function (): Promise<Config> {
        try {
            const data = await sendMessage('getData', '{}');
            if (data == null || data === '') {
                return {"ignorePunctuation": true, "ignoreCase": true};
            }
            return JSON.parse(data);
        } catch (e) {
            return {"ignorePunctuation": true, "ignoreCase": true};
        }
    },

    setConfig: async function (key: string, value: any): Promise<void> {
        const data = await this.getConfig();
        data[key] = value;
        await sendMessage('setData', JSON.stringify(data));
    },

    getVerse: async function (): Promise<Verse> {
        try {
            const data = await sendMessage('getVerse', '{}');
            if (data == null || data === '') {
                return {};
            }
            return JSON.parse(data);
        } catch (e) {
            return {};
        }
    },
    getLabel: function (): JsonRecord {
        try {
            const left = sendMessage('uiLabel', JSON.stringify({'name': 'left'}));
            const right = sendMessage('uiLabel', JSON.stringify({'name': 'right'}));
            const middle = sendMessage('uiLabel', JSON.stringify({'name': 'middle'}));
            const ret = {
                'left': left,
                'right': right,
                'middle': middle,
            };
            return ret;
        } catch (e) {
            return {};
        }
    },
    uiTap: function (event: string): string {
        try {
            return sendMessage('uiTap', JSON.stringify({'event': event}));
        } catch (e) {
            return '';
        }
    },
    adminId: function (): number {
        try {
            const userId = sendMessage('adminId', '{}');
            const parsed = parseInt(userId, 10);
            return Number.isNaN(parsed) ? -1 : parsed;
        } catch (e) {
            return -1;
        }
    },
    adminEnable: function (): boolean {
        try {
            const res = sendMessage('adminEnable', '{}');
            return res === 'true';
        } catch (e) {
            return false;
        }
    },
    broadcast: async function (path: string, data: any): Promise<string> {
        try {
            const payload = {
                path: path,
                data: typeof data === 'string' ? data : JSON.stringify(data)
            };
            return await sendMessage('broadcast', JSON.stringify(payload));
        } catch (e) {
            console.error("Broadcast failed:", e);
            return 'error';
        }
    },
};

const Game = {
    gameRefreshPath: 'gameRefresh',
    onNewVerse: async function () {
        await this.clear();
    },
    clear: async function (): Promise<void> {
        if (!Util.adminEnable()) {
            await Util.broadcast(this.gameRefreshPath, {});
        }
    },
    setConfig: async function (args: GameArgs): Promise<string> {
        try {
            const userId = args.userId;
            const adminId = Util.adminId();
            const adminEnable = Util.adminEnable();
            if (userId === adminId && adminEnable) {
                const data = args.data;
                await Util.setConfig(data.key, data.value);
                return JSON.stringify({});
            } else {
                return JSON.stringify({status: 500, error: "not admin"});
            }
        } catch (e: any) {
            return JSON.stringify({status: 500, error: e.toString()});
        }
    },
    getConfig: async function (): Promise<string> {
        try {
            const configData = await Util.getConfig();
            return JSON.stringify({
                data: configData,
            });
        } catch (error: any) {
            return JSON.stringify({
                status: 500,
                error: error.toString()
            });
        }
    },

    answer: async function (): Promise<string> {
        try {
            const verse = await Util.getVerse();
            let answer = '';
            if (verse && verse.a) {
                answer = verse.a;
            }
            return JSON.stringify({
                data: answer,
            });
        } catch (error: any) {
            return JSON.stringify({
                status: 500,
                error: error.toString()
            });
        }
    },

    label: function (): string {
        try {
            const label = Util.getLabel();
            return JSON.stringify({
                data: label,
            });
        } catch (error: any) {
            return JSON.stringify({
                status: 500,
                error: error.toString()
            });
        }
    },

    tap: function (args: GameArgs): string {
        try {
            const result = Util.uiTap(args.data);
            if (result !== 'success') {
                return JSON.stringify({
                    status: 500,
                    error: result + '',
                });
            }
            return JSON.stringify({});
        } catch (error: any) {
            return JSON.stringify({
                status: 500,
                error: error.toString()
            });
        }
    }
};
