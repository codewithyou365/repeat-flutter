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
}


const TypeGame = {
    setConfig: async function (args) {
        try {
            let data = args.data;
            await Util.setConfig(data.key, data.value);
            return JSON.stringify({});
        } catch (error) {
            return JSON.stringify({
                status: 500,
                error: error.toString()
            });
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