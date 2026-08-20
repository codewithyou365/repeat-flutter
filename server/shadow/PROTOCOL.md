# repeat-shadow 线协议 v1

手机端实现见 `lib/logic/ai/shadow_remote.dart`。明文 HTTP，无鉴权，只在可信
局域网里用。默认 `0.0.0.0:8766`。

## 错误契约

**和 `server/ai` 完全一致，手机端的降级逻辑依赖它：**

| 状态码 | 含义 | 手机怎么做 |
|---|---|---|
| 4xx | 业务错误（文本为空、音频太短、模型没装……） | **不要**回退本地，把 `error` 显示给人看 |
| 5xx / 连接超时 | 服务挂了 | 回退到本地 ASR 粗评分，并标 `degraded` |

所以服务端把所有引擎错误一律转成 **400 `{"error": "..."}`**，绝不让它冒成 500。
`HTTPException.detail` 也重命名成 `error`，客户端只需要解析一个字段。

## GET /v1/health

```json
{
  "name": "repeat-shadow",
  "proto": 1,
  "model": "facebook/wav2vec2-lv-60-espeak-cv-ft",
  "modelInstalled": true,
  "modelLoaded": true,
  "missing": [],
  "g2p": {"ok": true, "espeak": "1.52", "lang": "en-us", "error": ""},
  "calib": { ... },
  "device": "cpu", "frameMs": 20.0, "blank": 0,
  "vocabSize": 392, "phoneCount": 388
}
```

`modelInstalled` 和 `modelLoaded` **必须分开看**：模型 1.26 GB，「服务在但还在
加载」是个常见状态，设置页的「测试连接」要能说清是哪一种。

## POST /v1/score

`multipart/form-data`：

| 字段 | 必填 | 说明 |
|---|---|---|
| `audio` | 是 | **16 kHz 单声道 PCM16 wav**。手机端 `Wav.encode` 出来的就是这个格式 |
| `text` | 是 | 参考文本 |
| `lang` | 否 | espeak 方言，默认取 `calib.lang`（`en-us`） |
| `params` | 否 | JSON，覆盖本次的 calib 参数，不落盘 |

成功 200：

```json
{
  "overall": 78, "accuracy": 81, "completeness": 100, "fluency": 66,
  "durationMs": 3120, "speechMs": 2740,
  "degraded": false, "mismatch": false,
  "words": [
    {"w": "beautiful", "start": 1120, "end": 1740, "score": 88,
     "level": "good", "missed": false,
     "phones": [
       {"p": "b", "start": 1120, "end": 1180, "gop": -0.31,
        "score": 93, "status": "ok"}
     ]}
  ],
  "missedWords": [],
  "insertions": 2, "substitutions": 1, "deletions": 0,
  "per": 0.14, "voiced": 0.71, "pps": 11.4, "pauseCount": 0,
  "decoded":   "ð ə s k aɪ ɪ z ...",
  "reference": "ð ə s k aɪ ɪ z ...",
  "unmappedPhones": [],
  "timing": {"g2pMs": 4, "forwardMs": 820, "alignMs": 3, "totalMs": 840}
}
```

字段说明：

- `level` ∈ `good` / `fair` / `bad`，阈值来自 `calib.green` / `calib.amber`。
  UI 直接拿它上色，不要自己在前端定阈值——否则改校准要改两处。
- `status`（逐音素）∈ `ok` / `sub` / `del`，来自无约束解码和参考序列的编辑距离。
- `missed`（逐词）：这个词超过一半的音素是删除，即**漏读**。
- `mismatch`：`per > calib.perMismatch`，「读的根本不是这句」。为 true 时
  `accuracy` 已被封顶到 `calib.mismatchCap`。**UI 必须显式提示**，否则用户会
  以为是自己发音差。
- `unmappedPhones`：espeak 吐出了词表里没有的符号。非空说明 g2p 和模型词表
  有失配，分数不可全信。正常英文文本下应当**始终是空的**——切分走的是全覆盖
  DP，不是贪心最长匹配（贪心会在 `bjuːɾɪfəl` 这种地方拿走 `ju` 而把 `ː` 落单）。
- `degraded`：服务端**永远返回 false**。这个字段是给手机端降级路径用的——
  本地 ASR 粗评分时由手机自己置 true。

400 的常见 `error`：

```
参考文本是空的
音频是空的
读不了这个 wav（只收 16k 单声道 PCM16）：...
采样率必须是 16000，收到 44100
录音太长（35.2 秒 > 30 秒）
录音太短，放不下这段文本（需要至少 1.4 秒，实际 0.8 秒）
没录到有效语音（几乎全是静音）
这一条没有可跟读的文本
模型没装。跑 python install.py 装它。缺：...
```

### 时长约束

强制对齐的路径必须走完 `2P+1` 个状态（P = 音素数），每帧走一步，所以

```
帧数 T >= 2P + 1        帧长 20 ms
```

即**每个音素至少 40 ms**。30 音素的句子需要至少 1.24 秒音频。不满足时返回 400
而不是给一个数字——对齐在这种情况下会给出垃圾路径，而且不会报错。

## GET/POST /v1/calib

```bash
curl -s localhost:8766/v1/calib
curl -X POST -d 'key=m&value=-1.6' localhost:8766/v1/calib
```

改完立即生效并落盘（`~/.repeat-shadow/calib.json`）。键不认识返回 400。
全部键见 `calib.py` 的 `DEFAULTS`。

## 模型管理

```
GET    /v1/model            {"id","dir","installed","missing","onDisk","size","loaded"}
POST   /v1/model/download   开始下载，已经在下则 409
GET    /v1/model/download   {"state","done","total","file","error"}
                            state ∈ idle | running | done | failed
POST   /v1/model/cancel     取消（标志位，最多 ~10 秒生效）
DELETE /v1/model            删掉并卸载
```

**这里没有 `server/ai` 那套 `/v1/models/{id}/file|import|complete`**（手机往服务端
上传模型）。那套接口在 `server/ai` 有意义，因为手机上确实有那些模型；而这个
1.26 GB 的 wav2vec2 永远不会进手机，所以只有「让服务端自己去下」这一个方向。

## GET /v1/stats

最近 50 次打分的滚动平均，排查延迟用。

## GET /

内嵌调试页，不引任何外部资源（这台机器很可能没外网）。
