import mitt, {Emitter} from 'mitt';

type Events = {
    wsStatus: number;
};

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
