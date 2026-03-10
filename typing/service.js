const Util = {
    getConfig: async function () {
        console.log("DEBUG: [JS] >>> 进入 getConfig 函数");
        try {
            console.log("DEBUG: [JS] >>> 准备调用 sendMessage('getData')");

            // 确保参数是 JSON 字符串，防止底层崩溃
            let data = await sendMessage('getData', '{}');

            console.log("DEBUG: [JS] <<< sendMessage 返回了: " + data);

            if (data == null || data === '') {
                console.log("DEBUG: [JS] <<< 数据为空，返回默认配置");
                return {"ignorePunctuation": true, "ignoreCase": true};
            }

            return JSON.parse(data);
        } catch (e) {
            console.log("DEBUG: [JS] !!! getConfig 报错: " + e.message);
            return {"ignorePunctuation": true, "ignoreCase": true};
        }
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
}


const TypeGame = {
    totalProcessed: 0,
    settings: async function () {
        try {
            let configData = await Util.getConfig(); // 加上 await
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
    }
};