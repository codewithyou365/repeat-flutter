declare function sendMessage(method: string, payload: string): any;

// 「单词提问并朗读」的提示服务：把挂着的字段块里 'asks' 攒下的结果（打字游戏按词问出来的）整份展示出来，
// 也能删掉某个重点词。字段正文只是"重点词: like, apple"的摘要，每个词问到了什么得看这里。
// 'asks' 的结构和摘要的写法见 common/ask_store.ts。

const Util = {
    // 挂在哪个字段上：'q'/'a'/'n'/'t'/'t1'…，拿不到当第 1 条提示
    tipField: async function (): Promise<string> {
        try {
            const ret = await sendMessage('tipField', '{}');
            return typeof ret === 'string' && ret !== '' ? ret : 't';
        } catch (e) {
            return 't';
        }
    },
    tts: async function (payload: any): Promise<any> {
        try {
            return await sendMessage('tts', JSON.stringify(payload ?? {}));
        } catch (e) {
            return '';
        }
    },
    isMute: function (): boolean {
        try {
            return sendMessage('isMute', '{}') === 'true';
        } catch (e) {
            return true;
        }
    },
};

const Tip = {
    // 返回 {field, answer, items: [{word, text}]}：answer 是本节答案（网页拿来标重点词），
    // items 按提问先后排，同一个词问过好几次（答案改过、模版改过）就有好几条，都留着。
    asks: async function (): Promise<string> {
        try {
            const verse = await Bridge.verseGet();
            const field = await Util.tipField();
            const content = verse ? verse.content : {};
            const items = Object.values(AskStore.of(BridgeField.block(content, field))).map((e) => ({word: e.w, text: e.text}));
            const answer = BridgeField.text(BridgeField.block(content, 'a'));
            return JSON.stringify({data: {field, answer, items}});
        } catch (error: any) {
            return JSON.stringify({status: 500, error: error.toString()});
        }
    },
    // data = {word, prefix}：把这个重点词问过的每一条都删掉，prefix 是摘要正文前面的"重点词"字样
    removeWord: async function (payload: any): Promise<string> {
        try {
            const data = payload?.data || {};
            const word = typeof data.word === 'string' ? data.word : '';
            const prefix = typeof data.prefix === 'string' ? data.prefix : '';
            if (word === '') {
                return JSON.stringify({status: 500, error: 'invalid_args'});
            }
            const field = await Util.tipField();
            const ret = await Bridge.fieldUpdate(field, (verse) => {
                const all = AskStore.of(BridgeField.block(verse.content, field));
                const left: Record<string, AskItem> = {};
                for (const ins of Object.keys(all)) {
                    if (all[ins].w !== word) left[ins] = all[ins];
                }
                if (Object.keys(left).length === Object.keys(all).length) return null;
                return AskStore.patchOf(left, prefix);
            });
            if (ret !== 'ok') {
                return JSON.stringify({status: 500, error: ret});
            }
            return JSON.stringify({data: 'ok'});
        } catch (error: any) {
            return JSON.stringify({status: 500, error: error.toString()});
        }
    },
    // data = {text, type}：type 是字段引用串，App 按那个字段大类的 TTS 配置读
    tts: async function (payload: any): Promise<string> {
        try {
            const data = payload?.data || {};
            const text = typeof data.text === 'string' ? data.text : '';
            const type = typeof data.type === 'string' ? data.type : '';
            await Util.tts({text, type});
            return JSON.stringify({data: 'ok'});
        } catch (error: any) {
            return JSON.stringify({status: 500, error: error.toString()});
        }
    },
    isMute: function (): string {
        try {
            return JSON.stringify({data: Util.isMute()});
        } catch (error: any) {
            return JSON.stringify({status: 500, error: error.toString()});
        }
    },
};
