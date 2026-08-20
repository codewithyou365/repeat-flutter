import 'package:repeat_flutter/logic/ai/ai_catalog.dart';

/// 合成音色的显示名。
///
/// 清单里存的是 sherpa 那边的原始音色名（af_alloy、zm_yunxi……），下标就是 speaker id。
/// 直接把 "#0 #1 #2" 摆给用户等于让人挨个试 53 次，这里把名字拆成"人名 + 口音 + 性别"。
///
/// 命名规则来自 kokoro：第一个字母是口音/语种，第二个字母 f/m 是性别，下划线后面是人名。
class AiVoice {
  /// 首字母 -> 口音。跟 [AiLang.names] 一样写母语名，翻译过来反而要维护两份。
  static const Map<String, String> accents = {
    'a': 'English (US)',
    'b': 'English (UK)',
    'e': 'Español',
    'f': 'Français',
    'h': 'हिन्दी',
    'i': 'Italiano',
    'j': '日本語',
    'p': 'Português (BR)',
    'z': '中文',
  };

  /// 这个模型的音色名表。没写的（melo 这种单音色）是空表。
  static List<String> namesOf(AiModelEntry? entry) => entry?.voices ?? const [];

  /// 音色总数。以名字表为准，名字表为空才信清单里的 speakers。
  static int totalOf(AiModelEntry? entry) {
    final names = namesOf(entry);
    return names.isNotEmpty ? names.length : (entry?.speakers ?? 1);
  }

  /// 第 [sid] 个音色怎么显示。名字表里没有就退回编号——清单可能来自远程，
  /// 音色数比名字多的时候不能让列表少几行，那会让后面的 id 全部错位。
  static String label(List<String> names, int sid) {
    final raw = sid >= 0 && sid < names.length ? names[sid] : '';
    if (raw.isEmpty) {
      return '#$sid';
    }
    final cut = raw.indexOf('_');
    if (cut != 2) {
      // 不合命名规则的名字原样显示，别猜
      return '#$sid $raw';
    }
    final accent = accents[raw[0]];
    final gender = raw[1] == 'f' ? '♀' : (raw[1] == 'm' ? '♂' : '');
    final person = raw.substring(cut + 1);
    final who = person.isEmpty ? raw : person[0].toUpperCase() + person.substring(1);
    if (accent == null) {
      return '#$sid $who';
    }
    return '#$sid $who · $accent $gender';
  }
}
