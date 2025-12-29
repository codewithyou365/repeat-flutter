import mitt, {Emitter} from 'mitt';
import {toNumber} from '../utils/convert';
import {WordSlicerStatus} from "../vo/WordSlicerStatus.ts";

export class RefreshGameType {
    id: number;
    time: number;
    verseId: number;

    constructor() {
        this.id = 0;
        this.time = 0;
        this.verseId = 0;
    }

    static from(other: any): RefreshGameType {
        const ret = new RefreshGameType();
        if (other) {
            ret.id = toNumber(other.id);
            ret.time = toNumber(other.time);
            ret.verseId = toNumber(other.verseId);
        }
        return ret;
    }
}

type Events = {
    wsStatus: number;
    refreshGame: RefreshGameType;
    wordSlicerStatusUpdate: WordSlicerStatus;
};

export enum EventName {
    WsStatus = 'wsStatus',
    RefreshGame = 'refreshGame',
    WordSlicerStatusUpdate = 'wordSlicerStatusUpdate',
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
