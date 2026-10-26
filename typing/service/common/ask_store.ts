// 「单词提问并朗读」的结果表，打字游戏（问）和 Word Ask 提示页（看、删）共用。
// 存在作用位置那个字段块的 'asks' 里：{'<指令>': {'w': '<重点词>', 'text': '<结果>'}}。
// 每次提问只标一个词、指令各自独立，所以按指令当 key 一条条攒着，同一条指令再问就直接读存好的。
// 有它时字段正文只是 "重点词: like, apple" 这样的摘要，完整内容交给提示页展示。

type AskItem = { w: string; text: string };

const AskStore = {
    key: 'asks',

    // 字段块里的结果表（拷一份，改了不影响原块）。没有或格式不对返回 {}
    of: function (block: BridgeJson | null): Record<string, AskItem> {
        const raw = block && block[AskStore.key];
        const ret: Record<string, AskItem> = {};
        if (!raw || typeof raw !== 'object') return ret;
        for (const ins of Object.keys(raw)) {
            const item = raw[ins];
            const w = item && typeof item.w === 'string' ? item.w : '';
            const text = item && typeof item.text === 'string' ? item.text : '';
            if (w !== '' && text !== '') ret[ins] = {w, text};
        }
        return ret;
    },

    // 按提问先后、去重的重点词
    words: function (all: Record<string, AskItem>): string[] {
        const ret: string[] = [];
        for (const item of Object.values(all)) {
            if (!ret.includes(item.w)) ret.push(item.w);
        }
        return ret;
    },

    // 结果表改完后该怎么写回：表和正文摘要一起换；一条不剩就把表删掉、正文清空
    patchOf: function (all: Record<string, AskItem>, prefix: string): BridgePatch {
        const words = AskStore.words(all);
        if (words.length === 0) {
            return {remove: [AskStore.key], text: null};
        }
        return {set: {[AskStore.key]: all}, text: `${prefix}: ${words.join(', ')}`};
    },
};
