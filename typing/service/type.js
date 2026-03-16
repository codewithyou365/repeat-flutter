const Util = {
    getConfig: async function () {
        try {
            let data = await sendMessage('getData', '{}');
            if (data == null || data === '') {
                return {"ignorePunctuation": true, "ignoreCase": true};
            }
            return JSON.parse(data);
        } catch (e) {
            return {"ignorePunctuation": true, "ignoreCase": true};
        }
    },

    setConfig: async function (key, value) {
        let data = await this.getConfig();
        data[key] = value;
        await sendMessage('setData', JSON.stringify(data));
    },

    getVerse: async function () {
        try {
            let data = await sendMessage('getVerse', '{}');
            if (data == null || data === '') {
                return {};
            }
            return JSON.parse(data);
        } catch (e) {
            return {};
        }
    },
    getLabel: function () {
        try {
            let left = sendMessage('uiLabel', JSON.stringify({'name': 'left'}));
            let right = sendMessage('uiLabel', JSON.stringify({'name': 'right'}));
            let middle = sendMessage('uiLabel', JSON.stringify({'name': 'middle'}));
            let ret = {
                'left': left,
                'right': right,
                'middle': middle,
            };
            return ret;
        } catch (e) {
            return {};
        }
    },
    uiTap: function (event) {
        try {
            return sendMessage('uiTap', JSON.stringify({'event': event}));
        } catch (e) {
            return '';
        }
    },
    adminId: function () {
        try {
            let userId = sendMessage('adminId', '{}');
            return parseInt(userId, 10);
        } catch (e) {
            return '';
        }
    },
    adminEnable: function () {
        try {
            let res = sendMessage('adminEnable', '{}');
            return res === 'true';
        } catch (e) {
            return false;
        }
    },
    broadcast: async function (path, data) {
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
}


const Game = {
    gameRefreshPath: 'gameRefresh',
    clear: async function () {
        if (!Util.adminEnable()) {
            await Util.broadcast(this.gameRefreshPath, {});
        }
    },
    setConfig: async function (args) {
        try {
            const userId = args.userId;
            const adminId = Util.adminId();
            const adminEnable = Util.adminEnable();
            if (userId === adminId && adminEnable) {
                let data = args.data;
                await Util.setConfig(data.key, data.value);
                return JSON.stringify({});
            } else {
                return JSON.stringify({status: 500, error: "not admin"});
            }
        } catch (e) {
            return JSON.stringify({status: 500, error: e.toString()});
        }
    },
    getConfig: async function () {
        try {
            let configData = await Util.getConfig();
            return JSON.stringify({
                data: configData,
            });
        } catch (error) {
            return JSON.stringify({
                status: 500,
                error: error.toString()
            });
        }
    },

    answer: async function () {
        try {
            let verse = await Util.getVerse();
            let answer = '';
            if (verse && verse.a) {
                answer = verse.a;
            }
            return JSON.stringify({
                data: answer,
            });
        } catch (error) {
            return JSON.stringify({
                status: 500,
                error: error.toString()
            });
        }
    },

    label: function () {
        try {
            let label = Util.getLabel();
            return JSON.stringify({
                data: label,
            });
        } catch (error) {
            return JSON.stringify({
                status: 500,
                error: error.toString()
            });
        }
    },

    tap: function (args) {
        try {
            let result = Util.uiTap(args.data);
            if (result !== 'success') {
                return JSON.stringify({
                    status: 500,
                    error: result + '',
                });
            }
            return JSON.stringify({});
        } catch (error) {
            return JSON.stringify({
                status: 500,
                error: error.toString()
            });
        }
    }
};