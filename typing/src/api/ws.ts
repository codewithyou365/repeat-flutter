type MessageType = {
    REQUEST: 0,
    RESPONSE: 1,
};

export const MessageType: MessageType = {
    REQUEST: 0,
    RESPONSE: 1,
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
            path: json.path || '',
            headers: json.headers || {},
            data: json.data || '',
        });
    }

    toJson(): Record<string, any> {
        return {
            path: this.path,
            headers: this.headers,
            data: this.data,
        };
    }
}

export class Response {
    headers: Record<string, string>;
    data: any;
    error: string;
    status: number;

    constructor({headers = {}, data = '', error = '', status = 200}: Partial<Response> = {}) {
        this.headers = headers;
        this.data = data;
        this.error = error;
        this.status = status;
    }

    static fromJson(json: Partial<Response>): Response {
        return new Response({
            headers: json.headers || {},
            data: json.data || '',
            error: json.error || '',
            status: json.status || 200,
        });
    }

    toJson(): Record<string, any> {
        return {
            headers: this.headers,
            data: this.data,
            error: this.error,
            status: this.status,
        };
    }
}

export class Message {
    type: number;
    id: number;
    request: Request | null;
    response: Response | null;

    constructor({
                    type = MessageType.REQUEST,
                    id = 0,
                    request = null,
                    response = null,
                }: Partial<Message> = {}) {
        this.type = type;
        this.id = id;
        this.request = request;
        this.response = response;
    }

    static fromJson(json: any): Message {
        return new Message({
            type: json.type,
            id: json.id || 0,
            request: json.request ? Request.fromJson(json.request) : null,
            response: json.response ? Response.fromJson(json.response) : null,
        });
    }

    toJson(): Record<string, any> {
        return {
            type: this.type,
            id: this.id,
            request: this.request?.toJson(),
            response: this.response?.toJson(),
        };
    }
}

export class Node {
    sendId: number;
    sendId2Res: Map<number, { resolve: (value: any) => void; reject: (reason?: any) => void }>;
    webSocket: WebSocket;

    constructor(webSocket: WebSocket) {
        this.sendId = 0;
        this.sendId2Res = new Map();
        this.webSocket = webSocket;
    }

    receive(msg: Message) {
        const completer = this.sendId2Res.get(msg.id);
        if (completer) {
            completer.resolve(msg.response);
            this.sendId2Res.delete(msg.id);
        }
    }

    async send(req: Request): Promise<Response> {
        this.sendId++;
        const msg = new Message({
            id: this.sendId,
            type: MessageType.REQUEST,
            request: req,
        });

        this.webSocket.send(JSON.stringify(msg.toJson()));

        const completer = this._createCompleter();
        this.sendId2Res.set(this.sendId, completer);

        const timeout = setTimeout(() => {
            if (this.sendId2Res.delete(this.sendId)) {
                completer.resolve(new Response({error: 'timeout', status: 504}));
            }
        }, 10000);

        try {
            return await completer.promise;
        } finally {
            clearTimeout(timeout);
            this.sendId2Res.delete(this.sendId);
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

export class Client {
    logger: (msg: string) => void;
    node: Node | null;
    controllers: Record<string, (req: Request) => Promise<Response>>;

    constructor(logger: (msg: string) => void = console.log) {
        this.logger = logger;
        this.node = null;
        this.controllers = {};
    }

    async send(req: Request): Promise<Response | null> {
        if (!this.node) return null;
        return await this.node.send(req);
    }

    async start(url: string): Promise<boolean> {
        if (this.node) return false;
        const socket = new WebSocket(url);
        this.node = new Node(socket);
        socket.onmessage = async (event) => {
            try {
                const message = event.data;
                console.log('Message from server ', message);
                const msg = Message.fromJson(JSON.parse(message));
                if (msg.type === MessageType.RESPONSE) {
                    this.node!.receive(msg);
                } else if (msg.type === MessageType.REQUEST) {
                    await this._responseHandler(this.controllers, msg, socket);
                } else {
                    this.logger(`Unknown message type: ${msg.type}`);
                }
            } catch (e) {
                this.logger(`Error handling WebSocket message: ${e}`);
            }
        };

        socket.onclose = (event) => {
            this.node = null;
            this.logger(`Client disconnected. Close: ${JSON.stringify(event)}`);
        };

        socket.onerror = (error) => {
            this.node = null;
            this.logger(`Client disconnected. Error: ${JSON.stringify(error)}`);
        };

        return new Promise((resolve) => {
            socket.onopen = () => resolve(true);
        });
    }

    stop() {
        if (this.node) {
            this.node.webSocket.close();
        }
    }

    private async _responseHandler(
        controllers: Record<string, (req: Request) => Promise<Response>>,
        msg: Message,
        webSocket: WebSocket
    ) {
        const req = msg.request;
        let res: Response;
        const controller = req && controllers[req.path];
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

        webSocket.send(JSON.stringify(responseMessage.toJson()));
    }
}