declare function sendMessage(method: string, payload: string): any;

type VerseField = {
    text?: string;
    start?: string;
    end?: string;
    mediaHash?: string;
    showType?: string;
    [key: string]: any;
};

type Verse = {
    a?: VerseField;
    q?: VerseField;
    t?: VerseField[];
    n?: string;
    [key: string]: any;
};

const Util = {
    tts: async function (payload: any): Promise<any> {
        try {
            return await sendMessage('tts', JSON.stringify(payload ?? {}));
        } catch (e) {
            return '';
        }
    },
    isMute: function (): boolean {
        try {
            const result = sendMessage('isMute', '{}');
            return result === 'true';
        } catch (e) {
            return true;
        }
    },
    // 字段块（{text|content,start,end,mediaHash,showType}）的正文。
    // 新形态是有序的 'content' 数组（正文串 + 文件项），老形态是平铺的 'text'，两者二选一。
    // 跟 Dart 侧 VerseField.getText 保持一致：只把裸字符串项按顺序拼起来（\n 连接），文件项跳过。
    blockText: function (block: VerseField | string | null | undefined): string {
        if (typeof block === 'string') return block;
        if (!block) return '';
        const items = block.content;
        if (Array.isArray(items)) {
            const buf: string[] = [];
            for (const item of items) {
                if (typeof item === 'string' && item !== '') buf.push(item);
            }
            return buf.join('\n');
        }
        return block.text ? block.text : '';
    },
    fieldText: function (verse: Verse | null | undefined, acronym: string): string {
        const v = verse ? verse[acronym] : null;
        if (typeof v === 'string') return v;
        // 提示('t')是数组，一节可以挂好几条，这里取第 1 条。
        if (Array.isArray(v)) return Util.blockText(v[0]);
        return Util.blockText(v);
    },
    getVerse: async function (): Promise<Verse> {
        try {
            let data = await sendMessage('getVerse', '{}');
            if (data == null || data === '') return {} as Verse;
            return typeof data === 'string' ? JSON.parse(data) : data;
        } catch (e) {
            return {} as Verse;
        }
    },
};

const Tip = {
    answer: async function (): Promise<string> {
        try {
            const verse = await Util.getVerse();
            const answer = Util.fieldText(verse, 'a');
            return JSON.stringify({data: answer});
        } catch (error: any) {
            return JSON.stringify({status: 500, error: error.toString()});
        }
    },
    question: async function (): Promise<string> {
        try {
            const verse = await Util.getVerse();
            const question = Util.fieldText(verse, 'q');
            return JSON.stringify({data: question});
        } catch (error: any) {
            return JSON.stringify({status: 500, error: error.toString()});
        }
    },
    tip: async function (): Promise<string> {
        try {
            const verse = await Util.getVerse();
            const tip = Util.fieldText(verse, 't');
            return JSON.stringify({data: tip});
        } catch (error: any) {
            return JSON.stringify({status: 500, error: error.toString()});
        }
    },
    note: async function (): Promise<string> {
        try {
            const verse = await Util.getVerse();
            const note = Util.fieldText(verse, 'n');
            return JSON.stringify({data: note});
        } catch (error: any) {
            return JSON.stringify({status: 500, error: error.toString()});
        }
    },
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
            const result = Util.isMute();
            return JSON.stringify({data: result});
        } catch (error: any) {
            return JSON.stringify({status: 500, error: error.toString()});
        }
    },
};
