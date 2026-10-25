declare function sendMessage(method: string, payload: string): any;

// 「单词提问并朗读」的提示服务：把字段块里 'asks' 攒下的结果（打字游戏按词问出来的）整份展示出来。
// 字段正文只是"重点词: like, apple"的摘要，每个词问到了什么得看这里。
// 'asks' 的结构见 Dart 侧 VerseField.asks：{'<指令>': {'w': '<重点词>', 'text': '<结果>'}}。

type JsonRecord = Record<string, any>;

type AskItem = {
    word: string;
    text: string;
};

const Util = {
    getVerse: async function (): Promise<JsonRecord> {
        try {
            const data = await sendMessage('getVerse', '{}');
            if (data == null || data === '') return {};
            return typeof data === 'string' ? JSON.parse(data) : data;
        } catch (e) {
            return {};
        }
    },
    // 挂在哪个字段上：'q'/'a'/'n'/'t'/'t1'…，拿不到当第 1 条提示
    tipField: async function (): Promise<string> {
        try {
            const ret = await sendMessage('tipField', '{}');
            return typeof ret === 'string' && ret !== '' ? ret : 't';
        } catch (e) {
            return 't';
        }
    },
    // 跟 Dart 侧 VerseField.of 一致：'t1' 是 't' 数组的第 2 条，老内容的 't' 还是个 map 时只有第 1 条
    fieldBlock: function (verse: JsonRecord, ref: string): JsonRecord | null {
        const m = /^([a-z]+)(\d*)$/.exec(ref);
        if (!m) return null;
        const v = verse[m[1]];
        const index = m[2] === '' ? 0 : parseInt(m[2], 10);
        if (Array.isArray(v)) {
            const ret = v[index];
            return ret && typeof ret === 'object' ? ret : null;
        }
        if (v && typeof v === 'object') {
            return index === 0 ? v : null;
        }
        return null;
    },
    // 字段块的正文，跟 Dart 侧 VerseField.getText 一致：'content' 数组里的裸字符串用 \n 拼起来，没有就看 'text'
    blockText: function (block: JsonRecord | string | null | undefined): string {
        if (typeof block === 'string') return block;
        if (!block) return '';
        const items = block.content;
        if (Array.isArray(items)) {
            return items.filter((e: any) => typeof e === 'string' && e !== '').join('\n');
        }
        return typeof block.text === 'string' ? block.text : '';
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
            const verse = await Util.getVerse();
            const field = await Util.tipField();
            const block = Util.fieldBlock(verse, field);
            const raw = block && block.asks && typeof block.asks === 'object' ? block.asks : {};
            const items: AskItem[] = [];
            for (const ins of Object.keys(raw)) {
                const item = raw[ins];
                const word = item && typeof item.w === 'string' ? item.w : '';
                const text = item && typeof item.text === 'string' ? item.text : '';
                if (word !== '' && text !== '') {
                    items.push({word, text});
                }
            }
            const answer = Util.blockText(Util.fieldBlock(verse, 'a'));
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
            const field = await Util.tipField();
            const ret = await sendMessage('removeAskWord', JSON.stringify({field, word, prefix}));
            if (ret !== 'ok') {
                return JSON.stringify({status: 500, error: String(ret)});
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
