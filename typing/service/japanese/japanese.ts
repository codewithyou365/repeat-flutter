declare function sendMessage(method: string, payload: string): any;

type Verse = {
    a?: string;
    q?: string;
    t?: string;
    n?: string;
    [key: string]: any;
};

const Util = {
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
            const answer = verse.a;
            return JSON.stringify({data: answer});
        } catch (error: any) {
            return JSON.stringify({status: 500, error: error.toString()});
        }
    },
    question: async function (): Promise<string> {
        try {
            const verse = await Util.getVerse();
            const question = verse.q;
            return JSON.stringify({data: question});
        } catch (error: any) {
            return JSON.stringify({status: 500, error: error.toString()});
        }
    },
    tip: async function (): Promise<string> {
        try {
            const verse = await Util.getVerse();
            const tip = verse.t;
            return JSON.stringify({data: tip});
        } catch (error: any) {
            return JSON.stringify({status: 500, error: error.toString()});
        }
    },
    note: async function (): Promise<string> {
        try {
            const verse = await Util.getVerse();
            const note = verse.n;
            return JSON.stringify({data: note});
        } catch (error: any) {
            return JSON.stringify({status: 500, error: error.toString()});
        }
    },
};
