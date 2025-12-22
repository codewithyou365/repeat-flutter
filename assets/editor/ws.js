export const url = `wss://${window.location.hostname}:${window.location.port}`;

export const MessageType = {
    REQUEST: 0,
    RESPONSE: 1,
};

export const Header = {
    age: 'age',
};

export class Request {
    constructor({path = '', headers = new Map(), data = ''} = {}) {
        this.path = path;
        this.headers = headers;
        this.data = data;
    }

    static fromJson(json) {
        return new Request({
            path: json.path ?? '',
            headers: json.headers || new Map(),
            data: json.data ?? '',
        });
    }
}

export class Response {
    constructor({headers = new Map(), data = '', error = '', status = 200} = {}) {
        this.headers = headers;
        this.data = data;
        this.error = error;
        this.status = status;
    }

    static fromJson(json) {
        return new Response({
            headers: json.headers || new Map(),
            data: json.data ?? '',
            error: json.error ?? '',
            status: json.status ?? 200,
        });
    }
}

export class Message {
    constructor({
                    type = MessageType.REQUEST,
                    id = 0,
                    age = 0,
                    request = null,
                    response = null,
                } = {}) {
        this.type = type;
        this.id = id;
        this.age = age;
        this.request = request;
        this.response = response;
    }

    static fromJson(json) {
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
    constructor(webSocket, age) {
        this.sendId = 0;
        this.sendId2Res = new Map();
        this.sendId2Log = new Map();
        this.webSocket = webSocket;
        this.age = age;
    }

    receive(msg) {
        if (msg.age !== this.age) {
            console.log(`[ws] ignoring message - age mismatch: ${msg.age} vs ${this.age}`);
            return;
        }

        const completer = this.sendId2Res.get(msg.id);
        if (completer) {
            const headers = new Map();
            headers.set(Header.age, `${this.age}`);
            msg.response.headers = headers;
            completer.resolve(msg.response);
            this.sendId2Res.delete(msg.id);
        }

        if (this.sendId2Log.get(msg.id)) {
            console.log('[ws] recv :', msg);
            this.sendId2Log.delete(msg.id);
        }
    }

    async send(req, log = true) {
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
            console.log('[ws] send :', msg);
        }
        this.webSocket.send(JSON.stringify(msg));

        const completer = this._createCompleter();
        this.sendId2Res.set(id, completer);
        this.sendId2Log.set(id, log);

        const timeout = setTimeout(() => {
            if (this.sendId2Res.delete(id)) {
                this.sendId2Log.delete(id);
                const headers = new Map();
                headers.set(Header.age, `${age}`);
                completer.resolve(new Response({headers: headers, error: 'timeout', status: 504}));
            }
        }, 10000);

        try {
            return await completer.promise;
        } finally {
            clearTimeout(timeout);
            this.sendId2Res.delete(id);
            this.sendId2Log.delete(id);
        }
    }

    _createCompleter() {
        let resolve;
        let reject;
        const promise = new Promise((res, rej) => {
            resolve = res;
            reject = rej;
        });
        return {promise, resolve: resolve, reject: reject};
    }
}

export const ClientStatus = {
    INIT: 0,
    CONNECT_START: 1,
    CONNECT_FAILED: 2,
    CONNECT_FINISH: 3,
    CONNECT_CLOSE: 4,
    STOP_START: 5,
    STOP_FINISH: 6,
    STOP_FOR_RECONNECT_START: 7,
    STOP_FOR_RECONNECT_FINISH: 8,
};
export const ClientStatusName = new Map([
    [0, 'INIT'],
    [1, 'CONNECT_START'],
    [2, 'CONNECT_FAILED'],
    [3, 'CONNECT_FINISH'],
    [4, 'CONNECT_CLOSE'],
    [5, 'STOP_START'],
    [6, 'STOP_FINISH'],
    [7, 'STOP_FOR_RECONNECT_START'],
    [8, 'STOP_FOR_RECONNECT_FINISH'],
]);

const clientStatusProperties = new Map();

function add(to, incAge, from) {
    const froms = new Map();
    for (const f of from) {
        froms.set(f, true);
    }
    clientStatusProperties.set(to, {to, incAge: incAge, from: froms});
}


add(ClientStatus.INIT, false, []);
add(ClientStatus.CONNECT_START, true, [ClientStatus.INIT, ClientStatus.STOP_FOR_RECONNECT_FINISH, ClientStatus.CONNECT_CLOSE]);
add(ClientStatus.CONNECT_FAILED, false, [ClientStatus.CONNECT_START, ClientStatus.CONNECT_FINISH]);
add(ClientStatus.CONNECT_FINISH, false, [ClientStatus.CONNECT_START]);
add(ClientStatus.CONNECT_CLOSE, true, [ClientStatus.CONNECT_FINISH]);
add(ClientStatus.STOP_START, true, [ClientStatus.CONNECT_FAILED, ClientStatus.CONNECT_FINISH]);
add(ClientStatus.STOP_FINISH, true, [ClientStatus.STOP_START]);
add(ClientStatus.STOP_FOR_RECONNECT_START, true, [ClientStatus.CONNECT_FAILED, ClientStatus.CONNECT_FINISH]);
add(ClientStatus.STOP_FOR_RECONNECT_FINISH, true, [ClientStatus.STOP_FOR_RECONNECT_START]);

class Arg {
    constructor() {
        this.url = '';
        this.statusChange = () => {
        };
        this.heartSender = async () => {
            return new Response({
                status: 200,
            });
        };
        this.reason = '';
    }
}

class Client {
    constructor(logger = console.log) {
        this.logger = logger;
        this.age = 0;
        this.node = null;
        this.status = ClientStatus.INIT;
        this.url = '';
        this.retry = null;
        this.statusChange = () => {
        };
        this.controllers = new Map();

        this.heart = null;
        this.heartSender = async () => {
            return new Response({
                status: 200,
            });
        };
    }

    async _loopHeart() {
        if (this.heart) {
            clearTimeout(this.heart);
        }
        let age = -1;
        try {
            const res = await this.heartSender();
            age = parseInt(res.headers.get(Header.age) ?? '-1');
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

    async send(req, log = true) {
        if (!this.node) return null;
        return await this.node.send(req, log);
    }

    start(url, statusChange, heartSender) {
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

    stop(needToReconnect, stopReason) {
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

    _close() {
        this.node.webSocket.close();
    }

    _start(url, statusChange, heartSender) {

        this.url = url;
        this.statusChange = statusChange;
        this.heartSender = heartSender;
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
                    this.node.receive(msg);

                } else if (msg.type === MessageType.REQUEST) {
                    console.log('[ws] recv :', msg);
                    await this._responseHandler(this.controllers, msg, socket);
                } else {
                    console.log('[ws] recv :', msg);
                    this.logger(`Unknown message type: ${msg.type}`);
                }
            } catch (e) {
                this.logger(`Error handling WebSocket message: ${e}`);
            }
        };

        socket.onclose = (_) => {
            if (this.status === ClientStatus.CONNECT_FINISH) {
                this.setStatus(ClientStatus.CONNECT_CLOSE, null);
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

    setStatus(toStatus, arg) {
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
                this._start(arg.url, arg.statusChange, arg.heartSender);
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
                if (this.heart) {
                    clearTimeout(this.heart);
                }
                if (this.retry) {
                    clearTimeout(this.retry);
                }
                if (toStatus === ClientStatus.STOP_FOR_RECONNECT_FINISH
                    || toStatus === ClientStatus.CONNECT_CLOSE) {
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

    async _responseHandler(
        controllers,
        msg,
        webSocket
    ) {
        const req = msg.request;
        let res;
        const controller = req && controllers.get(req.path);
        if (controller) {
            try {
                res = (await controller(req)) || new Response({status: 501});
            } catch (e) {
                let errorMessage;
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