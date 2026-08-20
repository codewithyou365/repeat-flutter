import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/kv.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/ai/ai_catalog.dart';

/// 识别语言。
///
/// 多语种模型（Whisper、SenseVoice）默认自己判断语种，判错的代价很大：整句会被按
/// 另一门语言硬解，出来的原文完全不沾边。用户明确知道自己在说哪门语言时，把它钉死
/// 比换更大的模型有用得多，而且还快一点（Whisper 省掉一次语种检测解码）。
class AiLang {
  /// 空串 = 自动判断。sherpa 那边 whisper/senseVoice 的 language 都是空表示自动。
  static const String auto = '';

  /// 多语种模型（清单里 langs 写 "*"）露出来的候选。
  ///
  /// **不含 yue**：Whisper 只有 large-v3 认得 yue，base/small 传进去会直接报错；
  /// SenseVoice 认 yue，但它在清单里把语言逐个写明了，走的是 [langsOf] 的另一条分支。
  static const List<String> common = ['zh', 'en', 'ja', 'ko', 'fr', 'de', 'es', 'ru'];

  /// 语言的本地写法。故意不做 i18n：写母语名的列表谁都认得出自己那一行，
  /// 翻译过来反而要在两份配置里各维护一遍。
  static const Map<String, String> names = {
    'zh': '中文',
    'en': 'English',
    'ja': '日本語',
    'ko': '한국어',
    'yue': '粤语',
    'fr': 'Français',
    'de': 'Deutsch',
    'es': 'Español',
    'ru': 'Русский',
    'it': 'Italiano',
    'pt': 'Português',
  };

  static String label(String code) => code.isEmpty ? I18nKey.aiLangAuto.tr : (names[code] ?? code);

  /// 这个模型能选哪些语言。清单里写死了语言的（SenseVoice、只认一门语言的专用模型）
  /// 就照它的来，多语种的用 [common]。
  static List<String> langsOf(AiModelEntry? entry) {
    final langs = entry?.langs ?? const <String>[];
    if (langs.isEmpty || langs.contains('*')) {
      return common;
    }
    return langs;
  }

  static Future<String> current() async => (await Db().db.kvDao.getStr(K.aiAsrLanguage)) ?? auto;

  static Future<void> set(String code) async {
    await Db().db.kvDao.insertOrReplace(Kv(K.aiAsrLanguage, code));
  }

  /// 这个模型实际用得上的语言。
  ///
  /// 存的值可能是换模型之前选的（选了中文再换成 whisper-small.en），
  /// 模型不支持就退回自动，而不是把一个它不认识的语种码传给 sherpa 让它报错。
  static String effective(AiModelEntry entry, String code) {
    if (code.isEmpty) {
      return auto;
    }
    return langsOf(entry).contains(code) ? code : auto;
  }
}
