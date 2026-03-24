declare function sendMessage(method: string, payload: string): any;

type Verse = {
  answer?: string;
  [key: string]: any;
};

const Util = {
  getVerse: async function (): Promise<Verse> {
    try {
      const data = await sendMessage('getVerse', '{}');
      if (data == null || data === '') {
        return {};
      }
      return typeof data === 'string' ? JSON.parse(data) : data;
    } catch (e) {
      return {};
    }
  },
};

const Game = {
  answer: async function (): Promise<string> {
    try {
      const verse = await Util.getVerse();
      const answer = verse.answer || '';
      return JSON.stringify({data: answer});
    } catch (error: any) {
      return JSON.stringify({status: 500, error: error.toString()});
    }
  },
};
