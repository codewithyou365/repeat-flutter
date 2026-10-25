import 'dart:io';

import 'package:flutter/material.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/model/book_content.dart';
import 'package:repeat_flutter/page/repeat/logic/constant.dart';

/// 悬浮球动作的类型。类型决定了格子上的图标，也决定了表单里有哪几个参数。
///
/// 存进 classroom.content 的是 [code] 这个短串，不是枚举名、更不是下标——
/// 枚举改名/调顺序时老数据才不会指到别的类型上。读到不认识的 code 一律把整条动作丢掉
/// （见 [AtAction.fromJson]），不能抛异常：解析发生在复习页初始化的路上，抛出来整页就白了。
enum AtActionType {
  play('p', Icons.play_circle_outline, I18nKey.actionTypePlay),
  tts('t', Icons.record_voice_over, I18nKey.actionTypeTts),
  rewind('r', Icons.replay, I18nKey.actionTypeRewind),
  playPause('pp', Icons.play_arrow, I18nKey.actionTypePlayPause),
  net('n', Icons.auto_fix_high, I18nKey.actionTypeNet),
  adjust('aj', Icons.compress, I18nKey.actionTypeAdjust),
  delete('d', Icons.delete_outline, I18nKey.actionTypeDelete);

  final String code;
  final IconData icon;
  final I18nKey labelKey;

  const AtActionType(this.code, this.icon, this.labelKey);

  static AtActionType? fromCode(Object? code) {
    for (final t in AtActionType.values) {
      if (t.code == code) {
        return t;
      }
    }
    return null;
  }

  /// 有"作用位置"参数的类型。"删除当前节"没有；"朗读"也没有——
  /// 它改成了自己写朗读文本（[AtTtsConfig.template]），不再挑某个字段。
  bool get hasTarget => this != AtActionType.delete && this != AtActionType.tts;

  /// 作用位置里能不能选"当前"。net 是把请求结果覆盖到某个字段上，必须指到具体字段。
  bool get allowsCurrentTarget => this != AtActionType.net && this != AtActionType.delete;

  /// 有"后退秒数/播放时后退秒数"这个参数的类型。
  bool get hasSeconds => this == AtActionType.rewind || this == AtActionType.playPause;

  /// "当前"这一档在界面上怎么显示。两种类型的"当前"不是一回事：
  /// 播放取界面上当前选中的那条提示，后退/播放暂停取进度条现在绑着的那个字段。
  I18nKey get currentTargetLabelKey {
    return (this == AtActionType.play) //
        ? I18nKey.targetCurrentTip
        : I18nKey.targetCurrentPlaying;
  }
}

/// "调整时间"动作调的是区间的哪一头。存的是下标（跟 net 的 behavior 一个套路），
/// 读回来越界一律 clamp 回 [start]，不能抛——解析在复习页初始化的路上。
enum AtAdjustEdge {
  start(I18nKey.adjustEdgeStart),
  end(I18nKey.adjustEdgeEnd),
  both(I18nKey.adjustEdgeBoth);

  final I18nKey labelKey;

  const AtAdjustEdge(this.labelKey);

  static AtAdjustEdge fromIndex(int index) {
    return AtAdjustEdge.values[index.clamp(0, AtAdjustEdge.values.length - 1)];
  }
}

/// 作用位置里"当前"那一档存的值。空串在 JSON 里也读得回来，不用另造哨兵。
const String atCurrentTarget = '';

/// 一份可以直接灌给 FlutterTts 的 TTS 配置。engine/languageIndex/voiceIndex 是
/// "这台设备上的第几个"，Android 和 iOS 的引擎表、音色表完全不同，所以按平台分开存
/// （见 [AtTtsConfig]）；rate/pitch 是纯数值，两个平台共用一份。
class TtsSettings {
  String? engine;
  int? languageIndex;
  int? voiceIndex;
  int? rateIndex;
  int? pitchIndex;

  /// 远程 TTS 服务链接（server/ai 的 /v1/tts）。非空时朗读改走服务端实时合成，
  /// 失败才回落本机。只有悬浮球朗读动作有这一项，按字段类型存的那套没有。
  /// 不进 [cacheKey]：那个只管 FlutterTts 要不要重灌。
  String? remoteUrl;

  TtsSettings({
    this.engine,
    this.languageIndex,
    this.voiceIndex,
    this.rateIndex,
    this.pitchIndex,
    this.remoteUrl,
  });

  /// 判断"配置有没有变"用的缓存串（见 TtsHelper.cacheConfig）。
  /// Android 才有引擎/语言/音色，iOS 只比语速和音高。
  String get cacheKey {
    if (Platform.isAndroid) {
      return '$engine-$languageIndex-$voiceIndex-$rateIndex-$pitchIndex';
    }
    return '$rateIndex-$pitchIndex';
  }
}

/// 一个 tts 动作自己那份 TTS 配置。
/// 引擎/语言/音色按平台分成两套（同一个课堂在安卓机和苹果机上各存各的，互不覆盖），
/// 语速/音高不分平台。
class AtTtsConfig {
  /// 平台 -> {'e': 引擎名, 'l': 语言下标, 'v': 音色下标}
  final Map<String, Map<String, dynamic>> byPlatform;
  int? rateIndex;
  int? pitchIndex;

  /// 朗读文本的模版原文（不是渲染结果），写法跟 net 的指令模版一样：
  /// {{question}}/{{answer}}/{{note}}/{{tip1}}..{{tip8}} 取当前小节的正文，
  /// {{current}} 取界面上当前选中的那条提示，{{input1}}..{{input10}} 执行前弹框填。
  /// 空串表示老数据（那时朗读是挑字段的），执行时按 AtAction.target 走老路子。
  String template;

  /// 远程 TTS 服务链接，见 [TtsSettings.remoteUrl]。不分平台：两台手机连的是同一台服务器。
  String remoteUrl;

  AtTtsConfig({
    Map<String, Map<String, dynamic>>? byPlatform,
    this.rateIndex,
    this.pitchIndex,
    this.template = '',
    this.remoteUrl = '',
  }) : byPlatform = byPlatform ?? {};

  static String get _platformKey => Platform.isAndroid ? 'a' : 'i';

  TtsSettings get settings {
    final p = byPlatform[_platformKey] ?? const {};
    return TtsSettings(
      engine: p['e'] is String ? p['e'] as String : null,
      languageIndex: p['l'] is int ? p['l'] as int : null,
      voiceIndex: p['v'] is int ? p['v'] as int : null,
      rateIndex: rateIndex,
      pitchIndex: pitchIndex,
      remoteUrl: remoteUrl,
    );
  }

  /// 只改当前平台那一套，另一个平台存着的引擎/音色原样留着。
  void apply(TtsSettings s) {
    byPlatform[_platformKey] = {
      if (s.engine != null) 'e': s.engine,
      if (s.languageIndex != null) 'l': s.languageIndex,
      if (s.voiceIndex != null) 'v': s.voiceIndex,
    };
    rateIndex = s.rateIndex;
    pitchIndex = s.pitchIndex;
    remoteUrl = s.remoteUrl ?? '';
  }

  static AtTtsConfig fromJson(Object? json) {
    if (json is! Map) {
      return AtTtsConfig();
    }
    final byPlatform = <String, Map<String, dynamic>>{};
    for (final key in ['a', 'i']) {
      final v = json[key];
      if (v is Map) {
        byPlatform[key] = Map<String, dynamic>.from(v);
      }
    }
    return AtTtsConfig(
      byPlatform: byPlatform,
      rateIndex: json['r'] is int ? json['r'] as int : null,
      pitchIndex: json['p'] is int ? json['p'] as int : null,
      template: json['tp'] is String ? json['tp'] as String : '',
      remoteUrl: json['u'] is String ? json['u'] as String : '',
    );
  }

  Map<String, dynamic> toJson() => {
        ...byPlatform,
        if (rateIndex != null) 'r': rateIndex,
        if (pitchIndex != null) 'p': pitchIndex,
        if (template.isNotEmpty) 'tp': template,
        if (remoteUrl.isNotEmpty) 'u': remoteUrl,
      };
}

/// net 类型独有的参数：请求助手服务，把结果写回作用位置。
class AtNetParams {
  /// 助手服务地址。主机可以写域名别名或 xxx.local，请求前由 [DomainAlias.resolveUrl] 展开。
  /// 以前服务地址是全局一份（K.expandServiceUrl），老动作这里是空的，执行时回落到那一份。
  String url;

  /// 指令模版原文（不是渲染结果）：里面可以放 {{question}}/{{answer}}/{{tip1}}..{{tip8}}
  /// （取当前小节的正文）和 {{input1}}..{{input10}}（执行前弹框让用户填）。
  String template;

  /// ExpandBehavior 的下标：0 请求并覆盖到作用位置，1 作用位置有内容则播放否则覆盖，
  /// 2 不保存（结果只在对话框里显示）。
  int behavior;

  /// 拿到结果后要不要朗读：覆盖写入时读写进作用位置的文本，不保存时读 result['text']。
  bool speak;

  /// 朗读用的 TTS 配置，跟朗读动作同一个结构（按平台分开存引擎/音色）。
  final AtTtsConfig tts;

  AtNetParams({
    this.url = '',
    this.template = '',
    this.behavior = 0,
    this.speak = false,
    AtTtsConfig? tts,
  }) : tts = tts ?? AtTtsConfig();

  static AtNetParams fromJson(Object? json) {
    if (json is! Map) {
      return AtNetParams();
    }
    return AtNetParams(
      url: json['u'] is String ? json['u'] as String : '',
      template: json['tp'] is String ? json['tp'] as String : '',
      behavior: json['bh'] is int ? json['bh'] as int : 0,
      speak: json['sp'] is bool ? json['sp'] as bool : false,
      tts: AtTtsConfig.fromJson(json['ts']),
    );
  }

  Map<String, dynamic> toJson() => {
        if (url.isNotEmpty) 'u': url,
        'tp': template,
        'bh': behavior,
        if (speak) 'sp': speak,
        if (speak) 'ts': tts.toJson(),
      };
}

/// 悬浮球上的一个动作。全部动作（包括以前的"内置动作"）都是这一种，
/// 存在 classroom.content 的 [AtAction.contentKey] 数组里，跟着课堂走。
class AtAction {
  /// 稳定 id：手柄绑定和游戏脚本按它引用这个动作（`action:<id>` / `custom:<id>`），
  /// 所以新建时取一次时间戳就固定下来，改名/改类型都不动它。
  final int id;
  String name;
  AtActionType type;

  /// 作用位置的字段引用串：[atCurrentTarget]（当前）/ 'q' / 'a' / 'n' / 't' / 't1'...
  String target;

  /// rewind: 后退多少秒；playPause: 开始播放前先后退多少秒（0 就是原地接着播）。
  int seconds;

  /// adjust: 调区间的哪一头，[AtAdjustEdge] 的下标。
  int edge;

  /// adjust: 端点挪多少毫秒，负数往前、正数往后。档位见 [offsetMsOptions]。
  int offsetMs;

  final AtTtsConfig tts;
  final AtNetParams net;

  AtAction({
    required this.id,
    required this.name,
    required this.type,
    this.target = atCurrentTarget,
    this.seconds = 0,
    this.edge = 0,
    this.offsetMs = defaultOffsetMs,
    AtTtsConfig? tts,
    AtNetParams? net,
  })  : tts = tts ?? AtTtsConfig(),
        net = net ?? AtNetParams();

  /// 这个动作里能写 {{inputN}} 的那份模版：朗读是朗读文本，联网是指令，其它类型没有。
  /// 游戏那边靠它算出要准备几个参数（见 js_runtime 的 assistiveTouchActions）。
  String get inputTemplate {
    switch (type) {
      case AtActionType.tts:
        return tts.template;
      case AtActionType.net:
        return net.template;
      default:
        return '';
    }
  }

  /// classroom.content 里存动作列表的键。
  static const String contentKey = 'at';

  /// "后退"默认退 3 秒——档位见 [secondsOptions]。
  static const int defaultRewindSeconds = 3;

  /// 秒数只给几档常用值，比让用户自己敲数字省事，也避免敲出负数。
  /// playPause 的"播放时后退秒数"可以是 0（不后退），rewind 不行（退 0 秒没有意义）。
  static const List<int> secondsOptions = [0, 3, 5, 10, 15, 20, 30];

  /// "调整时间"默认往前借 300 毫秒——句首的辅音被切掉时最常见的就是这个量级。
  static const int defaultOffsetMs = -300;

  /// 端点偏移的档位。负数把端点往前挪（起点往前 = 多播一点前面），正数往后。
  /// 不给 0（挪 0 毫秒没有意义），也不让用户自己敲，免得敲出个把整段甩到几分钟外的数。
  static const List<int> offsetMsOptions = [-2000, -1000, -500, -300, -200, -100, -50, 50, 100, 200, 300, 500, 1000, 2000];

  static AtAction? fromJson(Object? json) {
    if (json is! Map) {
      return null;
    }
    final type = AtActionType.fromCode(json['t']);
    final id = json['i'];
    if (type == null || id is! int) {
      return null;
    }
    return AtAction(
      id: id,
      name: json['n'] is String ? json['n'] as String : '',
      type: type,
      target: json['g'] is String ? json['g'] as String : atCurrentTarget,
      seconds: json['s'] is int ? json['s'] as int : 0,
      edge: json['ae'] is int ? json['ae'] as int : 0,
      offsetMs: json['ms'] is int ? json['ms'] as int : defaultOffsetMs,
      tts: AtTtsConfig.fromJson(json['ts']),
      net: AtNetParams.fromJson(json['nt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'i': id,
        'n': name,
        't': type.code,
        // 朗读改成写模版之后不再有作用位置，但老动作存的 'g' 要留着：
        // 模版为空时执行还按它走（见 AssistiveTouchLogic.execute）。
        if (type.hasTarget || (type == AtActionType.tts && target != atCurrentTarget)) 'g': target,
        if (type.hasSeconds) 's': seconds,
        if (type == AtActionType.adjust) 'ae': edge,
        if (type == AtActionType.adjust) 'ms': offsetMs,
        if (type == AtActionType.tts) 'ts': tts.toJson(),
        if (type == AtActionType.net) 'nt': net.toJson(),
      };

  /// 新建一个动作。id 用时间戳，同一毫秒内连点两次也不至于撞——列表本来就是顺序追加的。
  static AtAction create(AtActionType type) {
    return AtAction(
      id: DateTime.now().millisecondsSinceEpoch,
      name: '',
      type: type,
      seconds: type == AtActionType.rewind ? defaultRewindSeconds : 0,
    );
  }

  /// 头一次进课堂时给的两个动作：播放/暂停、后退 3 秒。
  static List<AtAction> defaults() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return [
      AtAction(id: now, name: I18nKey.actionTypePlayPause.tr, type: AtActionType.playPause),
      AtAction(id: now + 1, name: I18nKey.actionTypeRewind.tr, type: AtActionType.rewind, seconds: defaultRewindSeconds),
    ];
  }

  /// 作用位置里能选的字段引用串，按界面上的顺序排。
  /// [tipCount] 是这一节实际有几条提示——超出的不列，免得指到根本不存在的提示上。
  static List<String> targetsOf(AtActionType type, int tipCount) {
    return [
      if (type.allowsCurrentTarget) atCurrentTarget,
      QaType.question.acronym,
      QaType.answer.acronym,
      for (var i = 0; i < tipCount; i++) VerseField.ref(QaType.tip.acronym, i),
    ];
  }
}
