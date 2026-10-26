// 各个 service 共用的 App 桥接口封装。gen.sh 用 tsc --outFile 把这个文件跟每个 service 拼成一个脚本
// （QuickJS 里是普通脚本，没有模块加载），所以这里只能放全局声明，名字统一带 Bridge 前缀，
// 免得跟各个 service 自己的 Util / VerseField 之类撞名。
// Dart 那边的对应实现见 lib/logic/js_bridge/js_bridge.dart。

declare function sendMessage(method: string, payload: string): any;

type BridgeJson = Record<string, any>;

type BridgeVerse = {
    verseId: number;
    // 整份内容的 sha1，写的时候原样带回去，对不上就是读和写之间被改过
    version: string;
    content: BridgeJson;
};

// fieldPatch 的改法：先删 remove 再写 set（值为 null 就是删）；带了 text 这个键（哪怕是 null）才换正文。
// set/remove 不能碰 App 的键（text/content/ins/mediaHash/start/end/showType/font* 和所有单字母键）。
type BridgePatch = {
    set?: BridgeJson;
    remove?: string[];
    text?: string | null;
};

type BridgeNetRender = { instruction: string; target: string };

// 字段块的读法，跟 Dart 侧 VerseField 一致
const BridgeField = {
    // 'q'/'a'/'t'/'t1'… 对应的字段块：'t1' 是 't' 数组的第 2 条，老内容的 't' 还是个 map 时只有第 1 条
    block: function (content: BridgeJson, ref: string): BridgeJson | null {
        const m = /^([a-z]+)(\d*)$/.exec(ref);
        if (!m) return null;
        const v = content[m[1]];
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
    // 字段块的正文：'content' 数组里的裸字符串用 \n 拼起来，没有就看 'text'
    text: function (block: BridgeJson | string | null | undefined): string {
        if (typeof block === 'string') return block;
        if (!block) return '';
        const items = block.content;
        if (Array.isArray(items)) {
            return items.filter((e: any) => typeof e === 'string' && e !== '').join('\n');
        }
        return typeof block.text === 'string' ? block.text : '';
    },
};

const Bridge = {
    // 每次都从库里读当前小节。没挂着游戏/没有当前小节返回 null。
    verseGet: async function (): Promise<BridgeVerse | null> {
        try {
            const ret = await sendMessage('verseGet', '{}');
            const data = typeof ret === 'string' ? JSON.parse(ret || '{}') : ret;
            if (!data || typeof data.version !== 'string' || !data.content) return null;
            return data as BridgeVerse;
        } catch (e) {
            return null;
        }
    },
    // 返回 'ok' / 'conflict' / 错误码
    fieldPatch: async function (ref: string, version: string, patch: BridgePatch): Promise<string> {
        try {
            return String(await sendMessage('fieldPatch', JSON.stringify({ref, version, ...patch})));
        } catch (e: any) {
            return String(e);
        }
    },
    // 写小节顶层的游戏私有键，value 为 null 就是删。返回 'ok' / 'conflict' / 错误码
    verseKeySet: async function (version: string, key: string, value: any): Promise<string> {
        try {
            return String(await sendMessage('verseKeySet', JSON.stringify({version, key, value})));
        } catch (e: any) {
            return String(e);
        }
    },
    // 读-改-写一条龙：make 拿到最新的小节算出这次的改法，返回 null 就是不用改（返回 'ok'）。
    // 版本冲突就重新读再算，最多试 retries 次。
    fieldUpdate: async function (
        ref: string,
        make: (verse: BridgeVerse) => BridgePatch | null,
        retries: number = 3,
    ): Promise<string> {
        let ret = 'conflict';
        for (let i = 0; i < retries && ret === 'conflict'; i++) {
            const verse = await Bridge.verseGet();
            if (!verse) return 'no_verse';
            const patch = make(verse);
            if (!patch) return 'ok';
            ret = await Bridge.fieldPatch(ref, verse.version, patch);
        }
        return ret;
    },
    // 只渲染 net 动作的指令不请求。id 形如 'custom:<动作id>'，inputs 按位置对应 input1..inputN
    netRender: async function (id: string, inputs: string[] = []): Promise<BridgeNetRender | { error: string }> {
        return await Bridge._json('netRender', {id, inputs});
    },
    // 拿指令请求 net 动作的服务，只返回结果，不写库不朗读。要等大模型，调它的方法得放长超时
    netSend: async function (id: string, instruction: string): Promise<{ text: string } | { error: string }> {
        return await Bridge._json('netSend', {id, instruction});
    },
    // 用朗读动作的 TTS 配置读 text，动作找不到就不读。返回 'ok' / 'not_found' / 'empty'
    ttsWith: async function (id: string, text: string): Promise<string> {
        try {
            return String(await sendMessage('ttsWith', JSON.stringify({id, text})));
        } catch (e: any) {
            return String(e);
        }
    },
    _json: async function (method: string, payload: any): Promise<any> {
        try {
            const ret = await sendMessage(method, JSON.stringify(payload));
            const data = typeof ret === 'string' ? JSON.parse(ret) : ret;
            return data && typeof data === 'object' ? data : {error: 'invalid_result'};
        } catch (e: any) {
            return {error: String(e)};
        }
    },
};
