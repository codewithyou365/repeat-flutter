import {Kv} from './Kv.ts';

export class KvList {
    list: Kv[];

    constructor(list: Kv[]) {
        this.list = list;
    }

    static fromJson(json: any): KvList {
        return new KvList(
            (json.list ?? []).map((e: any) => Kv.fromJson(e))
        );
    }

    convertMap(): Map<string, string> {
        const map = new Map<string, string>();

        for (const item of this.list) {
            map.set(item.k, item.v);
        }

        return map;
    }
}