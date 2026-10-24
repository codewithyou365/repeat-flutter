# repeat-ai 协议 v1

手机端实现：`lib/logic/ai/ai_remote.dart` + `lib/logic/ai/infer_engine.dart`
服务端实现：`server/ai/server.py`

明文 HTTP，无鉴权，只面向可信局域网。所有响应体为 JSON；出错时是 `{"error": "..."}`。

**错误语义很重要**：

| 状态码 | 含义 | 手机端行为 |
|---|---|---|
| 4xx | 业务错误（模型没装、参数不对、wav 格式不对） | **不回退本地**，该段标 failed，用户去复核页重跑 |
| 5xx / 连接失败 / 超时 | 服务端不可用 | **自动回退到机内模型**，并提示一次 |

---

## GET /v1/health

连通性探测。手机设置页的「测试连接」用它，顺便量往返延迟。

```json
{
  "name": "repeat-ai",
  "proto": 1,
  "catalogVersion": 3,
  "threads": 8,
  "models": {"vad": [], "asr": ["whisper-small-int8"], "mt": ["whisper-small-int8"], "tts": ["vits-melo-tts-zh_en"]},
  "selection": {"asr": {"id": "...", "name": "...", "speakers": 1, "fellBack": false}, "mt": {...}, "tts": {...}}
}
```

`models` 是服务端**已装好**（有 `.ok`）的模型 id，按角色分组。
`selection` 是当前生效的模型，手机拿它显示"服务器在用什么"——一次调用就拿全，
不用再多打一趟 `/v1/selection`。

## POST /v1/infer

`multipart/form-data`：

| 字段 | 类型 | 说明 |
|---|---|---|
| `kind` | text | `full` / `asr` / `mt` / `tts`，对应 Dart 的 `InferJobKind` |
| `params` | text (JSON) | 见下 |
| `audio` | file | 16 kHz 单声道 PCM16 wav。`full/asr` 必需；`kind=mt` 时可选（见下） |
| `text` | text | `kind=tts` 是待合成文本；`kind=mt` 是待翻译的**原文**（文本翻译模型用） |

`params`：

```json
{
  "asr": {"model": "whisper-small-int8", "language": "zh"},
  "mt":  {"model": "whisper-small-int8", "language": "zh"},
  "tts": {"model": "vits-melo-tts-zh_en", "sid": 0, "speed": 1.0}
}
```

只有该 `kind` 用得到的角色是必需的。**请求里不传 cfg**——服务端从自己那份 catalog 读，
这样它能自行把 `numThreads` 从手机的 2 提到 8，而不受手机清单约束。

`language` 是**源语言**。whisper 的 translate 任务里不给它，模型会自己猜一遍，
猜错了译文就跟着错，所以手机端钉死的识别语言要一并传上来。

响应：

```json
{"src": "今天天气不错", "dst": "The weather is nice today", "ttsMs": 1840, "ttsWav": "<base64 wav>"}
```

没产出的项为 `null`。`ttsWav` 是完整 wav 文件的 base64（采样率跟 TTS 模型走，
melo 是 44.1 k，不是录音的 16 k）。局域网上几百 KB 走 base64 完全够用，
客户端因此少一套 multipart 解析。

## GET / POST /v1/tts

对外的朗读接口，直接回 `audio/wav`（不是 JSON）。手机悬浮球「自定义动作 → 朗读 → TTS 设置」
里填 `http://<IP>:8767/v1/tts` 就走它；浏览器、curl 也能直接用。

| 参数 | 说明 |
|---|---|
| `text` | 待合成文本，必需。`GET` 走 query，`POST` 走 form（长文本用 POST） |
| `sid` | 可选，音色。不给用网页上选的 `ttsSid` |
| `speed` | 可选，语速。不给用网页上选的 `ttsSpeed` |

模型由服务端选（同 `/v1/infer`）。**每次现合成、只在内存里**，不落盘也不缓存。
出错仍是 `{"error": "..."}`：空文本 / 没产出 / 没有 tts 模型 → 400。

```bash
curl -o a.wav 'http://127.0.0.1:8767/v1/tts?text=hello%20world'
curl -F text=你好 http://127.0.0.1:8767/v1/tts -o b.wav
```

## GET /v1/models

```json
{"whisper-small-int8": {"ok": true, "archive": false, "missing": []}}
```

手机上传模型前先打这个对账，只传服务端缺的。

## POST /v1/models/{id}/file

`multipart/form-data`：`path`（模型目录内的相对路径）+ `data`（文件）。
服务端先写 `.part` 再改名，传一半断掉不会留下看着完整的坏文件。
`path` 越出模型目录一律 400。

## POST /v1/models/{id}/import

网页上传用。`multipart/form-data`，只有一个 `data` 字段。

和 `/file` 的区别：那边要显式给相对路径（手机知道自己的目录结构），
而浏览器的文件选择器只给一个文件名。这里**按文件名归位**——清单里每个模型的
文件名都是唯一的（melo-tts 那 16 个带子目录的也是）。认不出的文件名一律 400，
并在错误里列出这个模型要哪些文件。

文件名是压缩包扩展名（`.zip` / `.tar.bz2` / `.tar.gz` / `.tar.xz` / `.tgz`）时
自动解压并拍平外层目录。包里出现绝对路径或 `../` 一律 400（zip slip）。

## DELETE /v1/models/{id}

删掉模型目录并清该模型的实例缓存。

### 翻译的两条路

服务端选中的 `mt` 模型有两种 `kind`：

- **`sherpa`**（whisper）：拿**音频**重跑一遍 `task=translate`。`kind=mt` 时必须带 `audio`，
  带了 `text` 也会被忽略——改了原文它不看。
- **`text`**（opus-mt）：拿**文字**去翻。`kind=full` 用刚识别出来的 `src`；
  `kind=mt` 用请求里的 `text`；两者都没有时会先对 `audio` 跑一遍识别。

所以 `kind=mt` 到底需不需要 `audio`，取决于服务端选的是哪种。客户端两样都带上最省事。

## GET / POST /v1/selection

服务端当前用哪几个模型。

`GET` → `{"asr":"...","mt":"...","tts":"...","ttsSid":0,"ttsSpeed":1.0,"resolved":{...}}`

- 顶层是**存的值**，可能指向一个已经被删掉的模型。
- `resolved` 是**实际会生效**的：`{role: {id, name, speakers, fellBack}}`，
  没有可用模型时该角色为 `null`。`fellBack` 为真表示存的那个不在了、换成了别的。

回退链和手机端 `AiModelHelp.selectedFor` 一致：存的 id 装好了且担得起这个角色就用它，
否则退到"任意一个装好的该角色模型"，都没有就是 `null`。**这条很重要**：用户在网页上
删掉正在用的模型时，推理不该直接崩。

`POST` form 字段：`role` + `model`（`model` 为空串表示清掉，回到自动挑），
或 `ttsSid` / `ttsSpeed`。会 `engine.drop_cache()`——换了模型还留着旧实例就白换了。

拒绝的情况：未知 role → 400，未知 model → 404，模型担不了这个角色 / 还没装好 → 400。

## GET /v1/stats

最近 50 次推理的分阶段平均：`{count, totalMs, asrMs, mtMs, ttsMs, audioMs, last}`。
只在内存里，重启清零。概览页靠它显示"到底哪一步慢"。

## GET / POST /v1/source

下载源。`GET` 返回 `{"kind":"official|cn|custom","hfHost":"","ghPrefix":""}`；
`POST` 用 form 字段 `kind` / `hfHost` / `ghPrefix`。存盘，重启后还在。
`/v1/catalog` 返回的链接会按当前源改写。

## GET /v1/catalog

网页要的一切，一次给全：每个模型的 name/size/note/roles/urls/missing/ok/localOnly，
外加 root、threads、diskUsage、source。`/v1/models` 保持精简，那是给手机对账用的。

## 下载任务

- `POST /v1/models/{id}/download` — 后台开下。已有任务在跑返回 **409**（一次只跑一个）。
- `POST /v1/models/{id}/cancel` — 取消。**最多要十几秒才生效**：下载线程卡在 socket
  读上，取消标志只有收到数据块时才检查。已下的 `.part` 保留，下次续传。
- `GET /v1/downloads` — `{id: {state, fileIndex, fileTotal, file, done, total, error}}`，
  `state` 为 `running|done|failed`，idle 的不返回。

## GET /

管理网页，单文件内联，不引任何 CDN——这台机器很可能正是因为下不动东西才要用它。

## POST /v1/models/{id}/complete

按 catalog 里的 `h`/`s` 校验全部文件，通过才写 `.ok` 并清掉该模型的实例缓存。

```json
{"ok": false, "missing": ["small-decoder.int8.onnx"]}
```

压缩包类模型（kokoro）没有逐文件清单可校验，目录非空即认。
