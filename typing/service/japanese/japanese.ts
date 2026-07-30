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
    t?: VerseField;
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
    // q/a/t 的正文在字段块里（{text,start,end,mediaHash,showType}），
    // n 这类没有媒体的字段仍然是平铺的字符串。
    fieldText: function (verse: Verse | null | undefined, acronym: string): string {
        const v = verse ? verse[acronym] : null;
        if (typeof v === 'string') return v;
        return (v && v.text) ? v.text : '';
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
