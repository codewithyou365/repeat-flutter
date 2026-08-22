# server/ai — 局域网推理服务

把录音建章的 ASR / 翻译 / TTS 从手机挪到电脑上跑。手机端只需要在
**设置 → AI 模型 → 远程推理** 里填一个 `http://<电脑IP>:8765`。

同一批 sherpa-onnx 模型、同一份 `assets/ai/catalog.json`，所以结果和手机端一致，
只是 Mac M1 比手机快 5~10 倍。连不上时手机会自动回退到机内模型，录音不中断。

VAD 不在这里跑：它决定「切好一句」的震动反馈时机，必须实时，而且模型只有 0.6 MB。

## 装

```bash
cd server/ai
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
```

Apple Silicon 上 `sherpa-onnx` 有预编译 wheel，不用自己编。

**要 Python 3.10+**。macOS 自带的 3.9 链的是 LibreSSL 2.8.3，连 HuggingFace 会直接
`SSLEOFError`，模型一个都下不下来。装了 Homebrew 的话用它那个：

```bash
/opt/homebrew/bin/python3.12 -m venv .venv
```

## 网页管理

起服务后浏览器打开 **http://<本机IP>:8765/**，三个标签页：

**概览**（默认）
- 服务状态、线程数、磁盘占用
- **当前生效**：识别 / 翻译 / 合成三行，下拉直接换，换完即时生效。
  存的模型被删掉时会显示实际回退到了哪个。多音色的 TTS 模型还多一行音色。
- 手机该填的连接地址（带复制按钮）
- 最近推理：次数、平均总耗时、分阶段 asr/mt/tts 平均，**最慢的那一步标红**

**模型** — 每个模型一张卡片，按角色分组：

- **下载** — 服务端后台下，带进度条，可取消。已下的 `.part` 保留，再点从断点续传。
  一次只跑一个（并发只会互抢带宽）。
- **下载链接** — 列出直链，逐条或一键复制，丢进迅雷 / aria2 之类的加速器。
  缺的文件会标红「缺」，只下缺的那几个就行。
- **上传文件** — 拖进去或点选。**按文件名自动归位**，不用还原目录结构；
  压缩包直接丢进去会自动解压并拍平外层目录。
- **设为识别 / 翻译 / 合成** — 装好的模型才有，正在用的角色打勾。
  和概览页的下拉是同一份状态。

**设置** — 下载源（官方 / 国内镜像 / 自定义，存 `~/.repeat-ai/source.json`，
重启还在，命令行也跟着走；切换后列出的链接立刻按新源改写）、模型目录、线程数。

**下载速度不行就别硬等。** 大模型近 1 GB，直连和镜像都可能只有几十 KB/s——
复制链接去加速器下，下完从「上传文件」传回来，这条路快得多。

## 灌模型（命令行）

模型统一放 `~/.repeat-ai/models/<id>/`，布局和手机端的 `m/` 完全一致。

```bash
python download_models.py --list                 # 看清单和安装状态
python download_models.py --preset quality       # 按预设装
python download_models.py whisper-turbo-int8     # 按 id 装
python download_models.py --preset lite --source cn   # 走国内镜像
```

还可以**从手机传上来**（手机上已经下好了，不想再下一遍）：起服务后在手机
设置页点「上传模型到服务器」，它会先对账，只传服务端缺的文件。

## 谁决定用哪个模型

**服务端。** 网页上选，存 `~/.repeat-ai/selection.json`。手机每次请求只带
`{"language": "..."}`，带了 model id 也会被忽略。

这么定是因为手机的清单是 `assets/ai/catalog.json`，里面没有 `catalog.local.json`
那几个服务端专属大模型——让手机指定的话，那些模型下下来也永远用不上。算力在哪，
模型就在哪选。手机上那三行会**只读显示**服务器的选择。

**语言仍归手机**：它说的是"我在说什么话"，跟算力无关。
**音色 sid 归服务端**：它只对特定 TTS 模型有意义，模型换了 sid 就可能越界。

## 服务端专属模型

`catalog.local.json` 里的模型只在服务端生效，手机读的是 `assets/ai/catalog.json`，
看不到它们。放的是手机装不下、但 Mac 随便跑的大模型，网页上标着「仅服务端」：

| id | 大小 | 说明 |
|---|---|---|
| `whisper-turbo-int8` | 988 MB | large-v3 的精度、极小的 decoder，服务端首选 |
| `whisper-medium-int8` | 902 MB | 比 small 准不少 |
| `whisper-distil-large-v2-int8` | 937 MB | 蒸馏版 large，只认英文 |
| `opus-mt-zh-en` | 80 MB | **文本翻译**，见上一节 |

**换来的是精度不是速度**，那几个 whisper 都比 small 慢。上游没提供 sha1，
校验退回按文件大小比对（见 `catalog.py` 的 `missing_files`）。

**turbo 和 distil 只能做识别。** 它们是只为转写蒸馏的，`translate` 任务在蒸馏时
被砍掉了，强行跑出来是退化的乱码（实测 `'明天天天天天天天…'`）。所以它们的
`role` 只标 `asr`。要 whisper 翻译就用 `small` 或 `medium`；要好译文就用 `opus-mt-zh-en`。

顺带一提：**turbo 的转写比 small 明显准**（同一句中文，small 把「今天」听成「明天」，
turbo 是对的）。识别用 turbo、翻译用 opus-mt，是目前最好的搭配。

要加别的模型，照着 `catalog.local.json` 的格式往 `models` 里追加即可；
用到 sherpa 新模型类型的话还要改 `engine.py`，见下面。

## 文本翻译（推荐，译文质量的关键）

**默认的「翻译」并不是在翻译文本**，而是 whisper 拿同一段音频再解码一遍
（`task=translate`）。所以识别换多准的模型，译文都不会跟着变准——两条路是独立的。
而且 whisper-small 的翻译能力本来就弱，「霉斑」这类词基本必错。

`opus-mt-zh-en` 是真的文本翻译：拿**识别出来的文字**去翻。识别越准译文越准，
用户在复核页改了原文之后重翻也只有这条路做得到。

```bash
cd server/ai && source .venv/bin/activate
pip install -r requirements-mt.txt      # ctranslate2 + sentencepiece + 转换用的 torch
python setup_mt.py                      # 从 ModelScope 下载并转成 CT2 int8
pip uninstall -y torch transformers     # 可选，转完就用不着了，省 ~2GB
```

装完在网页「概览 → 当前生效 → 翻译」里把它选上。

`setup_mt.py` 从 **ModelScope** 拉（国内直连十几 MB/s），并且会自己**摘掉代理**
再连——挂着 `http_proxy` 的话速度会掉两个数量级。

要加别的语言方向：照 `catalog.local.json` 里 `opus-mt-zh-en` 那条加一份
（`kind` 必须是 `"text"`），再改 `setup_mt.py` 的 `REPO`。

### 翻译专用 LLM（目前最好的一档）

`hy-mt2-7b-mlx-8bit` 是腾讯混元二代翻译模型，**只做翻译**，不是通用 LLM。
跑苹果 GPU（MLX），约 8 GB。

```bash
cd server/ai && source .venv/bin/activate
pip install -r requirements-llm.txt -i https://mirrors.aliyun.com/pypi/simple
python setup_mt.py --model hymt2        # 约 8 GB，ModelScope 直连
```

比通用 LLM（`qwen2.5-7b-instruct-mlx-4bit`）强在两点：口语和习语更准；
基本不会中英混着吐——通用模型碰到识别成乱码的病句时容易半译半抄，
译文里夹几个中文字。

**选 8bit 不选 4bit**：同一个模型，低比特量化最先掉的就是「别混语言」这类
指令遵循能力，而 8 GB 权重对 Mac 不算负担。

它的 prompt 形状跟通用 LLM **完全不同**：不吃 system role，也不吃 few-shot，
官方用法就是一条 user 消息（指令和原文写在一起）。所以清单里必须写
`"promptStyle": "hunyuan-mt"`，`llm_mt.py` 按这个字段分派。漏了它不会报错，
只是模型跑在没见过的输入形状上，效果白白变差。

## 方言识别（四川话等）

`whisper` 和 `paraformer` 都只见过普通话，四川话这类方言只能当"带口音的普通话"
硬认，出来的原文是病句——**而译文再好也救不回一句本来就识别错的话**。

`qwen3-asr-1.7b-mlx-8bit` 支持 30 种语言 + 22 种中国方言（四川话、云南、贵州、
湖北、陕西、东北……都在列），自带语种判断，普通话和方言混着说不用切档。
跑苹果 GPU，约 2.3 GB。

```bash
cd server/ai && source .venv/bin/activate
pip install -r requirements-llm.txt -i https://mirrors.aliyun.com/pypi/simple
python setup_mt.py --model qwen3asr       # 约 2.3 GB，ModelScope 直连
```

装完在网页「概览 → 当前生效 → 识别」里选上。

它的运行时是 **mlx-audio**，跟 `whisper-*-mlx` 那几个用的 mlx-whisper **不是一个包**，
所以单独有个 `kind`（`mlx-audio-stt`）和单独一个模块 `mlx_audio_asr.py`。
音频是直接喂 numpy 数组进去的，不落临时 wav——mlx-audio 只在输入是路径时才去解码文件。

## 试 S2ST（端到端语音翻译）

`bench_s2st.py` 是个**一次性的测量脚本，不接进服务**。它回答三个问题：

1. SeamlessM4T v2 一段话要多久？（现在整条链 4.2 秒，其中 kokoro 合成占 2.4 秒）
2. 译文质量比 whisper translate 好多少？靶子是实际翻错的那句「这个键盘有霉斑」
3. 出语音时能不能**同时**拿到译文文本？

```bash
pip install -r requirements-s2st.txt -i https://mirrors.aliyun.com/pypi/simple
python bench_s2st.py --download-only    # 先拉 8.6 GB，可与 pip 并行
python bench_s2st.py                    # 跑测试
```

只下 HF transformers 那套 8.62 GB——仓库里还有 19.5 GB 的 fairseq2 `.pt`，
是另一套加载路径，下了白下。

判定门槛：热态每段 ≤ 6 秒**且**译文明显更好才值得做集成；> 10 秒或质量没提升，
就退回上一节的 `opus-mt-zh-en`（80 MB，代码已经写好）。

**跑之前想清楚**：S2ST 只给译文语音，`verse` 的原文/译文两栏会是空的。
`RecordCommit.commit` 现在会跳过 src/dst 都空的段——真要集成，那条得先放宽。

## 换一个更自然的 TTS

`seamless-m4t-v2-large` 可以**只当 TTS 用**（文本 -> 语音），翻译仍走 mt 那一档。
人声比 kokoro 自然（这个只能自己听，`bench_s2st.py` 会把两边的语音都写到 /tmp 对比）。

```bash
pip install -r requirements-s2st.txt -i https://mirrors.aliyun.com/pypi/simple
python bench_s2st.py --install     # 下 8.6 GB 并标记为可用
```

装完在网页「概览 → 当前生效 → 合成」里选。实测（同一句英文）：

| TTS | 单段热态 | 实时率 | 并发吞吐 | 有效每段 | 有效实时率 |
|---|---|---|---|---|---|
| kokoro | 3032 ms | 0.85 | 1.73x | 1756 ms | 0.49 |
| SeamlessM4T | 3426 ms | 1.00 | 1.42x | 2416 ms | 0.70 |

**注意单实例时它的实时率正好是 1.0**——连续说话会卡在临界点上堆队列。
是上面那套并发（TTS 实例池 + 手机端 maxInFlight=2）把有效实时率压到 0.70，
它才变成一个能用的选项。代价：常驻约 9 GB 内存，比 kokoro 慢 38%。

它和 sherpa 那几个 TTS 的并发方式不同：torch 的权重可以多线程共享，
所以只加载一份、用信号量限流；sherpa 的实例不是线程安全的，只能各建一份。
**但 HF 的快速分词器有可变状态**（设 src_lang 时会改写 post-processor），
那一步必须单独上锁，否则并发直接 `RuntimeError: Already borrowed`。

## 关于「苹果加速」

**CoreML 在这批 int8 模型上是负优化，别开。** 实测 whisper-small 解码同一段
3.5 秒音频：

| provider | 加载 | 解码 |
|---|---|---|
| `cpu` | 0.7s | ~600 ms |
| `coreml` | 4.2s | ~2800 ms |

慢 5 倍。原因是 CoreML EP 吃不下 int8 量化算子，会逐节点回退到 CPU，
来回搬数据反而更亏。真要用 Metal 得换运行时（whisper.cpp / MLX），
那是另一套模型格式，而且**它们都不管 TTS——而 TTS 才是这条链路的大头**。

## 跑

```bash
./run.sh                          # 0.0.0.0:8765
./run.sh --port 9000
./run.sh --models /path/to/models --catalog /path/to/catalog.json
```

macOS 首次会弹防火墙授权，要允许，否则手机连不上。
`ifconfig | grep 'inet '` 拿局域网 IP 填到手机上。

自检：

```bash
curl -s localhost:8765/v1/health | python3 -m json.tool
```

## 调线程数 / 并行度

默认 `min(8, CPU核数)`。清单里写的 `numThreads: 2` 是照手机来的，服务端一律覆盖。

**但线程加多了不会更快。** M1 Max（8 性能核 + 2 能效核）实测（`bench_threads.py`）：

| 线程 | 识别 | 翻译 | 合成 | 合计 |
|---:|---:|---:|---:|---:|
| 1 | 59 | 117 | 3300 | 3476 ms |
| 4 | 29 | 111 | 2608 | 2748 ms |
| **6** | 25 | 115 | 2509 | **2649 ms** |
| 8 | 29 | 156 | 2490 | 2675 ms |
| 10 | 41 | 409 | 2932 | **3382 ms（反而更慢）** |

开满 10 线程比 6 慢 28%——那两个能效核拖后腿。默认的 8 已经在最优点 1% 以内。

**真正的加速是多开实例，不是多给线程。** 合成占整段 94%，而且几乎不吃线程
（6 倍的核只快 1.3 倍）。所以 TTS 走实例池，默认 2 个各分一半线程：

```
串行 4 段:  墙钟 10892 ms
并发 4 段:  墙钟  5332 ms     吞吐 2.04x
```

代价是单段延迟变高（两段抢同一批核心），单独说一句时慢约 4%（实例分到 4 线程而非 8）。
录音是连续的，吞吐比单段延迟重要。要调：

```bash
REPEAT_AI_TTS_WORKERS=3 REPEAT_AI_THREADS=6 ./run.sh
```

实例是**懒建**的：并发真上来了才建第二个，一直单发就只有一份模型驻留。

手机端要配合并发才有意义——`RemoteInferEngine` 默认同时发 2 个请求
（`maxInFlight`，和这里的默认值对齐）。手机严格串行的话池子永远只有一个实例在动。

## 环境变量

| 变量 | 默认 | 说明 |
|---|---|---|
| `REPEAT_AI_THREADS` | `min(8, cpu)` | 推理线程数 |
| `REPEAT_AI_PROVIDER` | `cpu` | onnxruntime provider（**别改成 coreml**，见上） |
| `REPEAT_AI_TTS_WORKERS` | `2` | 并行的 TTS 实例数，见下 |
| `REPEAT_AI_CATALOG` | `../../assets/ai/catalog.json` | 清单路径（`uvicorn server:app` 直接起时用） |
| `REPEAT_AI_MODELS` | `~/.repeat-ai/models` | 模型目录 |

## 加新模型类型时

`catalog.json` 里加了 sherpa 的新模型类型（现在支持 whisper / senseVoice / paraformer /
vits / kokoro），要在 `engine.py` 的 `_build_recognizer` / `_build_tts` 里补一个分支；
新的路径字段还要在 `catalog.py` 的 `PATH_KEYS` 和 `lib/logic/ai/ai_model_paths.dart`
的 `pathKeys` 里各加一条，两边必须一致。

协议细节见 [PROTOCOL.md](PROTOCOL.md)。
