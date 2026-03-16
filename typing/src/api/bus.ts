import mitt, {Emitter} from 'mitt';
import {toNumber} from '../utils/convert';
import {WordSlicerStatus} from "../vo/WordSlicerStatus.ts";
import {BlankItRightStatus} from "../vo/BlankItRightStatus.ts";

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
    wordSlicerStatusUpdate: WordSlicerStatus;
    blankItRightStatusUpdate: BlankItRightStatus;
};

export enum EventName {
    WsStatus = 'wsStatus',
    WordSlicerStatusUpdate = 'wordSlicerStatusUpdate',
    BlankItRightStatusUpdate = 'blankItRightStatusUpdate',
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
