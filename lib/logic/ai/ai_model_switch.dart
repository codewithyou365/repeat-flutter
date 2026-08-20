import 'package:flutter/material.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/ai/ai_catalog.dart';
import 'package:repeat_flutter/logic/ai/ai_lang.dart';
import 'package:repeat_flutter/logic/ai/ai_model_help.dart';
import 'package:repeat_flutter/logic/ai/ai_remote.dart';
import 'package:repeat_flutter/logic/ai/ai_voice.dart';
import 'package:repeat_flutter/nav.dart';
import 'package:repeat_flutter/widget/select/select.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

/// 换模型。
///
/// 选中项存在 Kv 里，是全局的（[AiModelHelp.select]），所以录音页、复核页换的是
/// 同一份记录，换完下一次装配推理就按新的来。这里只负责"挑"，装/删仍然是模型管理页的事。
class AiModelSwitch {
  /// 角色 -> 当前实际生效的模型。没有可用模型的角色值为 null。
  ///
  /// 一律按**本机装好的**算。开了远程时这几个模型只用于本地回退，界面上显示的
  /// 是服务端的选择，走 [remoteNames]。
  static Future<Map<AiRole, AiModelEntry?>> current(
    AiCatalog catalog, {
    List<AiRole>? roles,
  }) async {
    final out = <AiRole, AiModelEntry?>{};
    for (final role in roles ?? AiRole.values) {
      out[role] = await AiModelHelp.selectedFor(role, catalog);
    }
    return out;
  }

  /// 服务端当前生效的模型名，按角色。连不上返回 null。
  ///
  /// 开了远程推理时用哪个模型由服务端决定，手机只显示——手机的清单里没有
  /// 服务端专属的大模型，让手机选的话那些模型永远用不上。
  static Future<Map<AiRole, String>?> remoteNames() async {
    if (!await AiRemote.enabled()) {
      return null;
    }
    try {
      final h = await AiRemote.health(await AiRemote.url());
      return {for (final r in [AiRole.asr, AiRole.mt, AiRole.tts]) r: h.nameOf(r)};
    } catch (e) {
      debugPrint('remoteNames failed: $e');
      return null;
    }
  }

  /// 给一个角色换模型。返回 true 表示选中项可能变了，调用方要重新读一次。
  ///
  /// 只列已经装好的：没装的先得下载，那是模型管理页的事，所以列表末尾始终留一项
  /// 通往管理页。**从管理页回来一律当"变了"处理**——那边能装新模型、能删模型、
  /// 也能直接改选中项，回来之后猜不出到底动没动。
  static Future<bool> pick(AiRole role) async {
    final catalog = await AiCatalog.load();
    final installed = <AiModelEntry>[];
    for (final e in catalog.byRole(role)) {
      if (await AiModelHelp.isInstalled(e.id)) {
        installed.add(e);
      }
    }
    // 一个都没装时不必弹只有一项的选择框，直接把人送去管理页
    if (installed.isEmpty) {
      Snackbar.show(I18nKey.aiModelMissing.trArgs([role.label]));
      await Nav.scSettingsAi.push();
      return true;
    }

    final currentId = (await AiModelHelp.selectedFor(role, catalog))?.id ?? '';
    final index = await Select.showSheet(
      title: I18nKey.aiSelectModel.trArgs([role.label]),
      keys: [
        ...installed.map((e) => e.name),
        I18nKey.aiModelManage.tr,
      ],
      leadings: [
        ...installed.map((e) => Icon(e.id == currentId ? Icons.check_circle : Icons.circle_outlined)),
        const Icon(Icons.settings),
      ],
    );
    if (index == null) {
      return false;
    }
    if (index >= installed.length) {
      await Nav.scSettingsAi.push();
      return true;
    }
    final picked = installed[index];
    if (picked.id == currentId) {
      return false;
    }
    await AiModelHelp.select(role, picked.id);
    Snackbar.show(I18nKey.aiModelSwitched.trArgs([role.label, picked.name]));
    return true;
  }

  /// 换识别语言。候选跟着当前选中的识别模型走：多语种模型给一串常见语言，
  /// 单语模型（paraformer-zh、whisper-small.en）就只有它自己那一门。
  static Future<bool> pickLanguage() async {
    final catalog = await AiCatalog.load();
    final asr = await AiModelHelp.selectedFor(AiRole.asr, catalog);
    final codes = [AiLang.auto, ...AiLang.langsOf(asr)];
    final current = await AiLang.current();
    final index = await Select.showSheet(
      title: I18nKey.aiAsrLanguage.tr,
      // 语言多的时候按内容算高度会顶出屏幕，交给 sheet 默认的可滚动高度
      autoHeight: codes.length <= 6,
      keys: codes.map(AiLang.label).toList(),
      leadings: codes
          .map((e) => Icon(e == current ? Icons.check_circle : Icons.circle_outlined))
          .toList(),
    );
    if (index == null) {
      return false;
    }
    final picked = codes[index];
    if (picked == current) {
      return false;
    }
    await AiLang.set(picked);
    Snackbar.show(I18nKey.aiModelSwitched.trArgs([I18nKey.aiAsrLanguage.tr, AiLang.label(picked)]));
    return true;
  }

  /// 当前合成音色，以及这个模型总共有几个音色。
  ///
  /// 音色存在 CrKv 里（跟着课堂走）：同一台设备上，英语课堂和日语课堂想要的声音
  /// 多半不是同一个。
  /// [names] 是音色名表，可能为空（模型没给名字），显示一律走 [AiVoice.label]。
  static Future<(int sid, int total, List<String> names)> voice([AiCatalog? catalog]) async {
    final tts = await AiModelHelp.selectedFor(AiRole.tts, catalog ?? await AiCatalog.load());
    final sid = await Db().db.crKvDao.getInt(Classroom.curr, CrK.aiTtsSpeakerId) ?? 0;
    final names = AiVoice.namesOf(tts);
    final total = AiVoice.totalOf(tts);
    // 换过模型的话存的 sid 可能超界（kokoro 有 53 个，melo 只有 1 个），越界当 0
    return (sid < total ? sid : 0, total, names);
  }

  /// 换合成音色。只有多音色模型（kokoro 53 个）才有意义，单音色的调用方根本不该露出入口。
  static Future<bool> pickVoice() async {
    final (current, total, names) = await voice();
    if (total <= 1) {
      return false;
    }
    final index = await Select.showSheet(
      title: I18nKey.aiTtsVoice.tr,
      autoHeight: false,
      keys: [for (var i = 0; i < total; i++) AiVoice.label(names, i)],
      leadings: [
        for (var i = 0; i < total; i++) Icon(i == current ? Icons.check_circle : Icons.circle_outlined),
      ],
    );
    if (index == null || index == current) {
      return false;
    }
    await Db().db.crKvDao.insertOrReplace(CrKv(Classroom.curr, CrK.aiTtsSpeakerId, '$index'));
    Snackbar.show(I18nKey.aiModelSwitched.trArgs([I18nKey.aiTtsVoice.tr, AiVoice.label(names, index)]));
    return true;
  }

  /// 先挑角色再挑模型。给只放得下一个入口的页面用（复核页的标题栏）。
  ///
  /// [roles] 由调用方给：复核页不跑 VAD，把判停列进去只会让人以为改了有用。
  static Future<bool> pickRole(List<AiRole> roles, {bool withParams = false}) async {
    final catalog = await AiCatalog.load();
    final selected = await current(catalog, roles: roles);
    final lang = withParams ? await AiLang.current() : AiLang.auto;
    // 单音色模型不露音色那一行：点开只有一项，等于骗人点一下
    final (sid, voices, voiceNames) = withParams ? await voice(catalog) : (0, 1, const <String>[]);
    final extras = <Future<bool> Function()>[
      if (withParams) pickLanguage,
      if (withParams && voices > 1) pickVoice,
    ];
    final index = await Select.showSheet(
      title: I18nKey.aiModel.tr,
      keys: [
        for (final role in roles) '${role.label}: ${selected[role]?.name ?? I18nKey.aiNotInstalled.tr}',
        if (withParams) '${I18nKey.aiAsrLanguage.tr}: ${AiLang.label(lang)}',
        if (withParams && voices > 1) '${I18nKey.aiTtsVoice.tr}: ${AiVoice.label(voiceNames, sid)}',
      ],
    );
    if (index == null) {
      return false;
    }
    if (index >= roles.length) {
      return await extras[index - roles.length]();
    }
    return await pick(roles[index]);
  }
}
