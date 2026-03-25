const { protocol, hostname, port } = window.location;
const wsProtocol = protocol === 'https:' ? 'wss:' : 'ws:';
const portPart = port ? `:${port}` : '';
export const url = `${wsProtocol}//${hostname}${portPart}`;
export const MessageType = {
    REQUEST: 0,
    RESPONSE: 1,
};

export const Header = {
    age: 'age',
};

export class Request {
    path: string;
    headers: Record<string, string>;
    data: any;

    constructor({path = '', headers = {}, data = ''}: Partial<Request> = {}) {
        this.path = path;
        this.headers = headers;
        this.data = data;
    }

    static fromJson(json: Partial<Request>): Request {
        return new Request({
            path: json.path ?? '',
            headers: json.headers ?? {},
            data: json.data ?? '',
        });
    }
}

export class Response {
    headers: Map<string, string>;
    data: any;
    error: string;
    status: number;
    age: number;

    constructor({headers = new Map(), data = '', error = '', status = 200, age = 0}: Partial<Response> = {}) {
        this.headers = headers;
        this.data = data;
        this.error = error;
        this.status = status;
        this.age = age;
    }

    static fromJson(json: Partial<Response>): Response {
        return new Response({
            headers: json.headers || new Map(),
            data: json.data ?? '',
            error: json.error ?? '',
            status: json.status ?? 200,
        });
    }
}

export class Message {
    type: number;
    id: number;
    age: number;
    request: Request | null;
    response: Response | null;

    constructor({
                    type = MessageType.REQUEST,
                    id = 0,
                    age = 0,
                    request = null,
                    response = null,
                }: Partial<Message> = {}) {
        this.type = type;
        this.id = id;
        this.age = age;
        this.request = request;
        this.response = response;
    }

    static fromJson(json: any): Message {
        return new Message({
            type: json.type,
            id: json.id || 0,
            age: json.age || 0,
            request: json.request ? Request.fromJson(json.request) : null,
            response: json.response ? Response.fromJson(json.response) : null,
        });
    }

}

export class Node {
    sendId: number;
    sendId2Res: Map<number, {
        completer: { promise: Promise<any>, resolve: (value: any) => void; reject: (reason?: any) => void },
        timeoutId: NodeJS.Timeout
    }>;
    sendId2Log: Map<number, boolean>;
    webSocket: WebSocket;
    age: number;

    constructor(webSocket: WebSocket, age: number) {
        this.sendId = 0;
        this.sendId2Res = new Map();
        this.sendId2Log = new Map();
        this.webSocket = webSocket;
        this.age = age;
    }

    destroy(reason: string = 'node destroyed') {
        for (const [_, req] of this.sendId2Res.entries()) {
            clearTimeout(req.timeoutId);
            req.completer.resolve(new Response({
                headers: new Map<string, string>(),
                error: reason,
                status: 504,
                age: this.age,
            }));
        }
        this.sendId2Res.clear();
        this.sendId2Log.clear();
    }

    receive(rawMsg: String, msg: Message) {
        if (msg.age !== this.age) {
            console.log(`[ws] ignoring message - age mismatch: ${msg.age} vs ${this.age}`);
            return;
        }

        const req = this.sendId2Res.get(msg.id);
        if (req) {
            clearTimeout(req.timeoutId);
            msg.response!.age = this.age;
            req.completer.resolve(msg.response);
            this.sendId2Res.delete(msg.id);
        }

        if (this.sendId2Log.get(msg.id)) {
            console.log('[ws] recv :', rawMsg);
            this.sendId2Log.delete(msg.id);
        }
    }

    async send(req: Request, log: boolean = true): Promise<Response> {
        this.sendId++;
        const id = this.sendId;
        const age = this.age;
        const msg = new Message({
            id: id,
            age: age,
            type: MessageType.REQUEST,
            request: req,
        });
        if (log) {
            console.log('[ws] send :', JSON.stringify(msg));
        }
        const completer = this._createCompleter();
        this.sendId2Log.set(id, log);

        const timeoutId = setTimeout(() => {
            if (this.sendId2Res.has(id)) {
                console.warn(`[ws] TIMEOUT - ID: ${id}, Age: ${age} (Wait for 10s)`);
                this.sendId2Res.delete(id);
                this.sendId2Log.delete(id);
                completer.resolve(new Response({
                    headers: new Map<string, string>(),
                    error: 'timeout_' + id,
                    status: 504,
                    age: age,
                }));
            }
        }, 10000);

        this.sendId2Res.set(id, {completer, timeoutId});

        try {
            if (this.webSocket.readyState !== WebSocket.OPEN) {
                throw new Error('WebSocket is not open');
            }
            const payload = JSON.stringify(msg);
            this.webSocket.send(payload);

            return await completer.promise;
        } catch (error) {
            clearTimeout(timeoutId);
            this.sendId2Res.delete(id);
            this.sendId2Log.delete(id);
            throw error;
        }
    }

    private _createCompleter() {
        let resolve: (value: any) => void;
        let reject: (reason?: any) => void;
        const promise = new Promise<any>((res, rej) => {
            resolve = res;
            reject = rej;
        });
        return {promise, resolve: resolve!, reject: reject!};
    }
}

export const ClientStatus = {
    INIT: 0,
    CONNECT_START: 1,
    CONNECT_FAILED: 2,
    CONNECT_FINISH: 3,
    CONNECT_CLOSE: 4,
    CONNECT_CLOSE_FOR_TOKEN_INVALID: 5,
    STOP_START: 6,
    STOP_FINISH: 7,
    STOP_FOR_RECONNECT_START: 8,
    STOP_FOR_RECONNECT_FINISH: 9,
};
const ClientStatusName: Map<number, string> = new Map<number, string>([
    [0, 'INIT'],
    [1, 'CONNECT_START'],
    [2, 'CONNECT_FAILED'],
    [3, 'CONNECT_FINISH'],
    [4, 'CONNECT_CLOSE'],
    [5, 'CONNECT_CLOSE_FOR_TOKEN_INVALID'],
    [6, 'STOP_START'],
    [7, 'STOP_FINISH'],
    [8, 'STOP_FOR_RECONNECT_START'],
    [9, 'STOP_FOR_RECONNECT_FINISH'],
]);

type ClientStatusRelationship = Map<
    number,
    {
        incAge: boolean;
        to: number;
        from: Map<number, boolean>;
    }
>;

const clientStatusProperties: ClientStatusRelationship = new Map();

function add(to: number, incAge: boolean, from: number[]): void {
    const froms = new Map<number, boolean>();
    for (const f of from) {
        froms.set(f, true);
    }
    clientStatusProperties.set(to, {to, incAge: incAge, from: froms});
}


add(ClientStatus.INIT, false, [],);
add(ClientStatus.CONNECT_START, true, [ClientStatus.INIT, ClientStatus.STOP_FOR_RECONNECT_FINISH, ClientStatus.CONNECT_CLOSE]);
add(ClientStatus.CONNECT_FAILED, false, [ClientStatus.CONNECT_START, ClientStatus.CONNECT_FINISH]);
add(ClientStatus.CONNECT_FINISH, false, [ClientStatus.CONNECT_START]);
add(ClientStatus.CONNECT_CLOSE, true, [ClientStatus.CONNECT_FINISH]);
add(ClientStatus.CONNECT_CLOSE_FOR_TOKEN_INVALID, true, [ClientStatus.CONNECT_FINISH]);
add(ClientStatus.STOP_START, true, [ClientStatus.CONNECT_FAILED, ClientStatus.CONNECT_FINISH, ClientStatus.CONNECT_CLOSE_FOR_TOKEN_INVALID]);
add(ClientStatus.STOP_FINISH, true, [ClientStatus.STOP_START]);
add(ClientStatus.STOP_FOR_RECONNECT_START, true, [ClientStatus.CONNECT_FAILED, ClientStatus.CONNECT_FINISH]);
add(ClientStatus.STOP_FOR_RECONNECT_FINISH, true, [ClientStatus.STOP_FOR_RECONNECT_START]);

class Arg {
    url: string = '';
    statusChange: (status: number) => void = () => {
    };
    heartSender: () => Promise<Response> = async () => {
        return new Response({
            status: 200,
        });
    };
    reason: string = '';
}

class Client {
    logger: (msg: string) => void;
    age: number = 0;
    node: Node | null;
    status: number = ClientStatus.INIT;
    url: string = '';
    retry: NodeJS.Timeout | null = null;
    statusChange: (status: number) => void = () => {
    };
    controllers: Map<string, (req: Request) => Promise<Response>>;

    heart: NodeJS.Timeout | null = null;
    heartSender: () => Promise<Response> = async () => {
        return new Response({
            status: 200,
        });
    };

    private async _loopHeart() {
        if (this.heart) {
            clearTimeout(this.heart);
        }
        let age = -1;
        try {
            const res = await this.heartSender();
            age = res.age;
            if (res.status === 200 && res.error === '') {
                this.heart = setTimeout(() => {
                    this._loopHeart();
                }, 2000);
            } else if (age === this.age) {
                this.stop(true, 'heart error:' + res.error);
            }
        } catch (e) {
            if (age === this.age) {
                this.stop(true, 'heart exception');
            }
        }

    }

    constructor(logger: (msg: string) => void = console.log) {
        this.logger = logger;
        this.node = null;
        this.controllers = new Map();
    }

    async send(req: Request): Promise<Response | null> {
        if (!this.node) return null;
        return await this.node.send(req);
    }

    start(url: string, statusChange: (status: number) => void, heartSender: () => Promise<Response>) {
        if (this.status === ClientStatus.INIT
            || this.status === ClientStatus.CONNECT_CLOSE
            || this.status === ClientStatus.STOP_FOR_RECONNECT_FINISH) {
            const arg = new Arg();
            arg.url = url;
            arg.statusChange = statusChange;
            arg.heartSender = heartSender;
            this.setStatus(ClientStatus.CONNECT_START, arg);
            return true;
        } else {
            this.logger(`[ws] start: status error :${ClientStatusName.get(this.status)}`);
            return false;
        }
    }

    stop(needToReconnect: boolean, stopReason: string) {
        if (this.status == ClientStatus.CONNECT_FAILED
            || this.status == ClientStatus.CONNECT_FINISH) {
            const arg = new Arg();
            arg.reason = stopReason;
            if (needToReconnect) {
                this.setStatus(ClientStatus.STOP_FOR_RECONNECT_START, arg);
            } else {
                this.setStatus(ClientStatus.STOP_START, arg);
            }
            return true;
        } else {
            this.logger(`[ws] stop: status error :${ClientStatusName.get(this.status)} ${stopReason}`);
            return false;
        }
    }

    private _close() {
        if (this.node) {
            this.node.destroy('client close');
            this.node.webSocket.close();
        }
    }

    private _start(url: string, statusChange: (status: number) => void, heartSender: () => Promise<Response>) {

        this.url = url;
        this.statusChange = statusChange;
        this.heartSender = heartSender;

        if (this.node) {
            this.node.destroy('reconnecting');
        }

        const socket = new WebSocket(url);
        this.node = new Node(socket, this.age);
        socket.onmessage = async (event) => {
            if (this.status !== ClientStatus.CONNECT_FINISH) {
                return;
            }
            try {
                const message = event.data;
                const msg = Message.fromJson(JSON.parse(message));
                if (msg.type === MessageType.RESPONSE) {
                    if (msg.age !== this.age) {
                        return;
                    }
                    this.node!.receive(message, msg);

                } else if (msg.type === MessageType.REQUEST) {
                    console.log('[ws] recv :', message);
                    await this._responseHandler(this.controllers, msg, socket);
                } else {
                    console.log('[ws] recv :', message);
                    this.logger(`Unknown message type: ${msg.type}`);
                }
            } catch (e) {
                this.logger(`Error handling WebSocket message: ${e}`);
            }
        };

        socket.onclose = (event) => {
            const closeEvent = event as CloseEvent;
            if (closeEvent.code === 4001) {
                this.node?.destroy('token-invalid');
            } else {
                this.node?.destroy('socket-closed');
            }
            if (this.status === ClientStatus.CONNECT_FINISH) {
                if (closeEvent.code === 4001) {
                    this.setStatus(ClientStatus.CONNECT_CLOSE_FOR_TOKEN_INVALID, null);
                } else {
                    this.setStatus(ClientStatus.CONNECT_CLOSE, null);
                }
            } else if (this.status === ClientStatus.STOP_START) {
                this.setStatus(ClientStatus.STOP_FINISH, null);
            } else if (this.status === ClientStatus.STOP_FOR_RECONNECT_START) {
                this.setStatus(ClientStatus.STOP_FOR_RECONNECT_FINISH, null);
            } else {
                this.logger(`[ws] socket.onclose: status error :${ClientStatusName.get(this.status)}`);
            }
        };

        socket.onerror = (_) => {
            if (this.status == ClientStatus.CONNECT_START
                || this.status == ClientStatus.CONNECT_FINISH) {
                this.setStatus(ClientStatus.CONNECT_FAILED, null);
            } else {
                this.logger(`[ws] socket.onerror: status error :${ClientStatusName.get(this.status)}`);
            }
        };

        socket.onopen = () => {
            if (this.status == ClientStatus.CONNECT_START) {
                this.setStatus(ClientStatus.CONNECT_FINISH, null);
            } else {
                this.logger(`[ws] socket.onopen: status error :${ClientStatusName.get(this.status)}`);
            }
        };
    }

    private setStatus(toStatus: number, arg: Arg | null) {
        const toStatusProperties = clientStatusProperties.get(toStatus);
        if (toStatusProperties === undefined) throw new Error(`Unknown status: ${toStatus}`);
        const from = toStatusProperties.from;
        if (!from.get(this.status)) {
            this.logger(`[ws] status error : cant from ${ClientStatusName.get(this.status)} to ${ClientStatusName.get(toStatus)} ${arg?.reason}`);
            return;
        }
        if (toStatusProperties.incAge) {
            this.age++;
        }
        this.logger(`[ws] status from ${ClientStatusName.get(this.status)} to ${ClientStatusName.get(toStatus)} ${arg?.reason}`);
        this.status = toStatus;

        switch (toStatus) {
            case ClientStatus.CONNECT_START:
                this._start(arg!.url, arg!.statusChange, arg!.heartSender);
                break;
            case ClientStatus.CONNECT_FAILED:
                this.stop(true, 'connect failed');
                break;

            case ClientStatus.CONNECT_FINISH:
                this._loopHeart();
                break;
            case ClientStatus.STOP_FOR_RECONNECT_START:
            case ClientStatus.STOP_START:
                this._close();
                break;
            case ClientStatus.STOP_FINISH:
            case ClientStatus.STOP_FOR_RECONNECT_FINISH:
            case ClientStatus.CONNECT_CLOSE:
            case ClientStatus.CONNECT_CLOSE_FOR_TOKEN_INVALID:
                if (this.heart) {
                    clearTimeout(this.heart);
                    this.heart = null;
                }
                if (this.retry) {
                    clearTimeout(this.retry);
                    this.retry = null;
                }
                if (toStatus === ClientStatus.STOP_FOR_RECONNECT_FINISH) {
                    this.retry = setTimeout(() => {
                        this.start(this.url, this.statusChange, this.heartSender);
                    }, 1000);
                }
                break;
            default:
                break;
        }

        this.statusChange(this.status);
    }

    private async _responseHandler(
        controllers: Map<string, (req: Request) => Promise<Response>>,
        msg: Message,
        webSocket: WebSocket
    ) {
        const req = msg.request;
        let res: Response;
        const controller = req && controllers.get(req.path);
        if (controller) {
            try {
                res = (await controller(req)) || new Response({status: 501});
            } catch (e) {
                let errorMessage: string;
                if (e instanceof Error) {
                    errorMessage = e.message;
                } else {
                    errorMessage = String(e);
                }
                res = new Response({status: 500, error: errorMessage});
            }
        } else {
            res = new Response({status: 404});
        }

        const responseMessage = new Message({
            id: msg.id,
            type: MessageType.RESPONSE,
            response: res,
        });

        webSocket.send(JSON.stringify(responseMessage));
    }
}

export const client = new Client();