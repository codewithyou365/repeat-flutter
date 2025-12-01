import {Kv} from './Kv.ts';

export class GetGameSettingsRes {
    list: Kv[];

    constructor(list: Kv[]) {
        this.list = list;
    }

    static fromJson(json: any): GetGameSettingsRes {
        return new GetGameSettingsRes(
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