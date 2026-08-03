// 打字游戏的共享打字进度，字段与 service/type/type.ts 里 Game.getBroadcastData() 逐字对应。
// 只存在服务端内存里，换一条 verse（Game.clear）就清空。
export class TypeState {
    // 轮次：每换一条 verse +1。客户端拿它判断收到的快照是不是当前这一条的
    roundId: number = -1;
    // 本轮写入版本号，用来定序：只应用比本地更新的快照
    seq: number = -1;
    // 共享的已输入串（含打错的字符）
    userInput: string = '';
    // 下标 -> 敲下这个字符的 userId，用来给字符上色
    indexToUserId: Record<number, number> = {};
    userIdToUserName: Record<number, string> = {};
    // 服务端拒绝了本次上报（轮次或版本号对不上），随快照一起回来，客户端据此重新同步
    stale: boolean = false;

    static fromJson(json: any): TypeState {
        const state = new TypeState();
        if (!json || typeof json !== 'object') {
            return state;
        }
        state.roundId = typeof json.roundId === 'number' ? json.roundId : -1;
        state.seq = typeof json.seq === 'number' ? json.seq : -1;
        state.userInput = typeof json.userInput === 'string' ? json.userInput : '';
        state.indexToUserId =
            json.indexToUserId && typeof json.indexToUserId === 'object'
                ? json.indexToUserId
                : {};
        state.userIdToUserName =
            json.userIdToUserName && typeof json.userIdToUserName === 'object'
                ? json.userIdToUserName
                : {};
        state.stale = json.stale === true;
        return state;
    }
}
