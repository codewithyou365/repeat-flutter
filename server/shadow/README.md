# repeat-shadow —— 跟读打分服务

给手机上的「跟读」游戏做发音评测：收一段录音和一句参考文本，返回逐音素、
逐词的分数。

和 `server/ai`（8765，翻译/识别/合成）是**两个独立进程**。分开跑的代价是各自
一份内存（这个约 1.5 GB，`server/ai` 挂着 SeamlessM4T 时约 9 GB，16 GB 的机器
上要心里有数），好处是一边崩了不影响另一边。

## 为什么不用 ASR 打分

最容易想到的做法是「识别一遍，跟参考文本比字符串」。这条路不通：whisper 这类
模型会**自动纠错**——你把 `think` 读成 `sink`，它照样转出 `think`。拿它当发音分
是在骗人，而且它讲不出「你的 /θ/ 读错了」。

这里走的是强制对齐 + GOP（Goodness of Pronunciation），和商用发音评测
（Azure、讯飞）同一套思路：

1. 参考文本 → 音素序列（espeak g2p）
2. 音频 → wav2vec2 的逐帧音素后验
3. 把音素序列**强制对齐**到帧上（CTC Viterbi）
4. 每个音素的 GOP = 它在自己那几帧上的后验，比这些帧上最强的那个音素差多少
5. 逐音素分聚合成逐词分、句子分

第 4 步是全部信息量所在：它直接问「这一帧的声学证据有多支持你声称在读的这个音」。

## 装

```bash
cd server/shadow

# 依赖。真正新增的只有 espeakng-loader + phonemizer-fork（espeak 的 g2p），
# 其余 server/ai/.venv 里已经有了，run.sh 默认就复用那个 venv。
../ai/.venv/bin/pip install -r requirements.txt -i https://mirrors.aliyun.com/pypi/simple

# 模型 1.26 GB。走 ModelScope 直连。
../ai/.venv/bin/python install.py
../ai/.venv/bin/python install.py --check
```

### 下载一定要绕开代理

`install.py` 内部全程走 `modelscope_dl.session()`，那里面 `trust_env = False`，
所以**不管你 shell 里有没有 `http_proxy`，下载都是直连**。检测到代理环境变量时
它会打一行提示说明这件事。

原因记在 `server/ai/modelscope_dl.py` 的文件头：实测 ModelScope 直连 16 MB/s，
挂着 `http_proxy` 只有 30 KB/s，**差两个多数量级**。这是 1.26 GB 的权重，走代理
既慢又白烧代理流量。

`espeakng-loader` 自带各平台的 espeak-ng 动态库，**不需要 `brew install espeak-ng`**。

> 注意：不要同时装 `phonemizer` 和 `phonemizer-fork`，两者 import 名相同会互相覆盖。
> 用 fork 是因为官方版有个 `EspeakWrapper` 库路径的 bug 还没合。

## 跑

```bash
./run.sh --preload          # 0.0.0.0:8766
./run.sh --port 9100
./run.sh --device mps       # 见下面「MPS」
```

自检：

```bash
curl -s localhost:8766/v1/health | python3 -m json.tool
```

浏览器打开 `http://127.0.0.1:8766/` 有个朴素的调试页：贴段文本、选个 wav、
直接看逐词红黄绿。

macOS 第一次绑端口会弹防火墙，要允许。手机填的是**局域网 IP**，不是 `127.0.0.1`。

## 打分

```bash
say -o /tmp/s.aiff "the sky is beautiful today"
afconvert -f WAVE -d LEI16@16000 -c 1 /tmp/s.aiff /tmp/s.wav

curl -s -F audio=@/tmp/s.wav -F text="the sky is beautiful today" \
     localhost:8766/v1/score | python3 -m json.tool
```

### 必须做的反向测试

```bash
curl -s -F audio=@/tmp/s.wav -F text="the quick brown fox jumps over" \
     localhost:8766/v1/score | python3 -c \
     "import json,sys; j=json.load(sys.stdin); print(j['overall'], j['per'], j['mismatch'])"
```

`accuracy` 必须塌下来、`per` 必须飙上去、`mismatch` 必须是 `true`。

**为什么这条测试比正向测试更重要**：强制对齐**永远会成功**。喂它静音、咳嗽、
或者一句完全不相干的话，它照样返回一条完整的、看着挺像样的逐音素 GOP。
`gop.py` 里那两道闸（PER 闸和有声帧占比闸）就是挡这个的——没有它们，
这个服务会心安理得地给背景噪音打 85 分。这条 curl 是证明闸还在的唯一手段。

## 校准

**开箱的分数一定是没校准的，而且偏悲观。** GOP 的绝对尺度取决于模型、录音通道
和说话人母语；手机麦克风的音频过了 AEC/NS/AGC，会系统性地比干净音频低分。

调法从省事到正经：

**1. 热改。** 服务起着就能改，立即生效并落盘，不用重启也不用重新打包 dist.zip：

```bash
curl -X POST -d 'key=m&value=-1.6' localhost:8766/v1/calib
curl -X POST -d 'key=s&value=0.8'  localhost:8766/v1/calib
curl -s localhost:8766/v1/calib | python3 -m json.tool
```

`score = 100 * sigmoid((gop - m)/s) / sigmoid(-m/s)`。`m` 往上调 = 整体更严，
往下 = 更松；`s` 越小两极分化越厉害。

除以 `sigmoid(-m/s)` 是为了让 GOP 的理论上界（0，即对齐音素在自己每一帧上都是
argmax）正好对应 100 分——不归一化的话默认参数下满分只到 90，`star3=90` 就
变成了"声学上完美无瑕"，真人永远拿不到三星。默认参数下的对照：

| GOP | 0 | -0.5 | -1 | -1.5 | -2 | -3 | -4 |
|---|---|---|---|---|---|---|---|
| 分数 | 100 | 93 | 83 | 70 | 55 | 28 | 11 |

**2. 自录十条。** 五条正常读，五条故意读错（文件名带 `bad`），配同名 `.txt`：

```bash
../ai/.venv/bin/python calibrate.py ~/shadow-calib --apply
```

它打印两组的逐音素 GOP 分位数，并给出建议的 `m`（两组中位数的中点）和
`s`（两组间距的四分之一）。

**3. 正经语料。** [speechocean762](https://huggingface.co/datasets/mispeech/speechocean762)：
5000 条中国人说的英语，音素/词/句三级人工 0-10 标注，约 500 MB，CC-BY。

```bash
../ai/.venv/bin/python calibrate.py --corpus /path/to/speechocean762 --apply
```

它网格搜 `m`/`s`，最大化句级 Pearson 相关并把系数打出来。已发表的 GOP-CTC 基线
大致 **0.55~0.65 PCC**。低于 0.4 说明链路有问题（多半是 espeak 方言或词表切分
失配），不是调 `m`/`s` 能救的——先看 `/v1/score` 返回里的 `unmappedPhones`。

**判断校准好没好的经验法则**：正常读一句，词色应该**在句内有差异**。
全绿或全红都说明校准不对，不是你读得完美或者一塌糊涂。

> UI 上不要出现绝对准确度的说法。星级和红黄绿是相对的、自洽的，可以展示；
> 「你的发音准确率 87%」这种话我们没有依据说。

## 参数

`~/.repeat-shadow/calib.json`（在 models 目录**旁边**，删模型重下不会丢）。
全部键和默认值见 `calib.py` 的 `DEFAULTS`，几个要紧的：

| 键 | 默认 | 说明 |
|---|---|---|
| `m` / `s` | -2.0 / 0.9 | GOP → 0..100 的 logistic 参数 |
| `gopOffset` | 0.0 | 压缩前的偏移，给「这台手机麦克风偏小声」用 |
| `wAccuracy` / `wCompleteness` / `wFluency` | .60 / .25 / .15 | 总分权重 |
| `green` / `amber` | 80 / 60 | 词的红黄绿阈值 |
| `lang` | en-us | **espeak 方言，必须和参考 TTS 的口音一致**（en-us vs en-gb 光是 r 音色化就差 10 分） |
| `perMismatch` | 0.8 | 音素错误率超过它判定「读的不是这句」 |
| `minVoiced` | 0.20 | 非 blank 帧占比低于它判定「没录到人声」 |
| `maxSeconds` | 30 | 录音上限 |

## 环境变量

| 变量 | 默认 | 说明 |
|---|---|---|
| `REPEAT_SHADOW_MODELS` | `~/.repeat-shadow/models` | 模型根目录 |
| `REPEAT_SHADOW_DEVICE` | `cpu` | `cpu` / `mps` |
| `REPEAT_SHADOW_WORKERS` | `2` | 并发打分数 |

### MPS

默认 **cpu**。wav2vec2 的 group norm 和大一维卷积在 MPS 上历史性地算错过——
不是崩，是安静地给出不同的数，而发音评测全靠后验的细微差别。

`--device mps` 会先跑一次数值自检（同一段噪声在 CPU 和 MPS 上各跑一遍比最大绝对
误差），超过 1e-2 就自动退回 CPU 并打日志。CPU 上一句话的前向大约 0.8~1.5 秒，
已经够用了。

## 排错

| 症状 | 多半是 |
|---|---|
| `/v1/health` 里 `g2p.ok` 是 false | `pip install -r requirements.txt` 没跑，或者同时装了 `phonemizer` 和 `phonemizer-fork` |
| 打分返回「模型没装」 | `python install.py --check` 看缺什么 |
| 分数全是 90+ 或者全是 20- | 没校准，见上面「校准」 |
| 用 `say` 合成的音频每个词都 100 分 | 正常。合成音在声学上几乎无瑕，GOP 全部贴着 0。**别拿 TTS 音频校准 `m`/`s`**，一定要用真人录音 |
| 真人录音报「没录到有效语音」 | `minVoiced` 调太高了。CTC 输出是尖峰的，正常朗读的非 blank 帧占比只有 0.19~0.27，而静音是干净的 0.000，所以默认 0.05 |
| 词色全绿或全红 | 同上，`s` 太大或太小 |
| `unmappedPhones` 非空 | espeak 吐出了词表里没有的符号，多半是 `lang` 和文本语言对不上 |
| 「录音太短，放不下这段文本」 | 帧数必须 ≥ 2×音素数+1，即每个音素至少 40 ms |
| 手机连不上 | 防火墙；填的是不是局域网 IP；`--host` 是不是 0.0.0.0 |
| 下载慢得离谱 | 不应该发生（内部强制直连）。确认跑的是 `install.py` 而不是 `huggingface-cli` |

协议细节见 `PROTOCOL.md`。
