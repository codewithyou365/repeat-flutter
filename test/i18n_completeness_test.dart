import 'package:flutter_test/flutter_test.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/i18n/i18n_translations.dart';

/// 12 门语言的文案表很容易改漏：往 I18nKey 加一条、只补了 en/zh 就提交，
/// 剩下 10 份要等用户切到那门语言才发现（虽然有英文兜底，但界面会中英夹杂）。
/// 这里把"每门语言都得覆盖全部 key"钉死在测试里。
void main() {
  final data = I18nTranslations.data;
  // none 是枚举结尾的哨兵值（i18n_key.dart 里写作 `none;`），不是给人看的文案，
  // 三份 config 里都没有它，也不该有。
  final allKeys = I18nKey.values.map((e) => e.name).toSet()..remove(I18nKey.none.name);

  test('每门语言都在 I18nTranslations 里注册了', () {
    expect(
      data.keys.toSet(),
      I18nLocal.values.map((e) => e.name).toSet(),
      reason: '加语言时 _builders 漏了一行',
    );
  });

  for (final locale in I18nLocal.values) {
    test('${locale.name} 覆盖了全部 I18nKey', () {
      final missing = allKeys.difference(data[locale.name]!.keys.toSet());
      expect(missing, isEmpty, reason: 'config_${locale.name}.dart 缺这些 key');
    });
  }

  test('各语言之间没有多余的 key', () {
    for (final entry in data.entries) {
      expect(
        entry.value.keys.toSet().difference(allKeys),
        isEmpty,
        reason: 'config_${entry.key}.dart 里有 I18nKey 已经没有的 key',
      );
    }
  });

  test('占位符数量与英文底本一致', () {
    // %s 走 trArgs、@N 走 trParams，两边对不上就会漏参数或把字面量甩到界面上
    final en = data[I18nLocal.en.name]!;
    int countS(String v) => RegExp(r'%s').allMatches(v).length;
    Set<String> atArgs(String v) => RegExp(r'@(\d)').allMatches(v).map((m) => m.group(1)!).toSet();

    for (final entry in data.entries) {
      if (entry.key == I18nLocal.en.name) continue;
      for (final key in allKeys) {
        final a = en[key]!;
        final b = entry.value[key]!;
        expect(countS(b), countS(a), reason: '${entry.key} 的 $key 里 %s 数量与英文不一致');
        expect(atArgs(b), atArgs(a), reason: '${entry.key} 的 $key 里 @N 参数与英文不一致');
      }
    }
  });

  test('语言设置页每一行都有母语显示名', () {
    for (final locale in I18nLocal.values) {
      expect(locale.displayName, isNot(locale.name), reason: '${locale.name} 没在 _names 里写显示名');
    }
  });
}
