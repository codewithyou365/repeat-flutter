export class Kv {
    k: string;
    v: string;

    constructor(k: string, v: string) {
        this.k = k;
        this.v = v;
    }

    static fromJson(json: any): Kv {
        return new Kv(
            json.k as string,
            json.v as string
        );
    }

    toJson(): Record<string, any> {
        return {
            k: this.k,
            v: this.v
        };
    }
}