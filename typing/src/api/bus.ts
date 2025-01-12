import mitt, {Emitter} from 'mitt';
import {toNumber} from '../utils/convert';

export class RefreshGameType {
    id: number;
    time: number;

    constructor() {
        this.id = 0;
        this.time = 0;
    }

    static from(other: any): RefreshGameType {
        const ret = new RefreshGameType();
        if (other) {
            ret.id = toNumber(other.id);
            ret.time = toNumber(other.time);
        }
        return ret;
    }
}

type Events = {
    wsStatus: number;
    refreshGame: RefreshGameType;
};

export enum EventName {
    WsStatus = 'wsStatus',
    RefreshGame = 'refreshGame',
}

const b = {
    value: null as Emitter<Events> | null,
};

export function check(): boolean {
    return b.value != null;
}

export function busReset(): void {
    b.value = mitt<Events>();
}

export function bus(): Emitter<Events> {
    return b.value!;
}
