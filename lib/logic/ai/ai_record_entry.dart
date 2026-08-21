import 'package:get/get.dart';
import 'package:repeat_flutter/db/entity/book.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/ai/ai_catalog.dart';
import 'package:repeat_flutter/logic/ai/ai_pipeline.dart';
import 'package:repeat_flutter/nav.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';

/// 息屏录音建章的入口。两条路都走这里：素材页手点「添加章节 → 录音翻译生成」，
/// 以及课堂级的快速进入。
class AiRecordEntry {
  /// 开录之前先确认四个角色的模型都齐了——不齐就引导去下载，
  /// 而不是让用户录完一整段才发现合成不出声音。
  ///
  /// 开了远程推理时只查 VAD：识别/翻译/合成的模型装在电脑上，
  /// 拿"本机装没装"来拦会把纯远程这条路彻底堵死。见 [AiPipeline.missingRoles]。
  static Future<void> open(Book book) async {
    final catalog = await AiCatalog.load();
    final missing = await AiPipeline.missingRoles(catalog);
    if (missing.isNotEmpty) {
      MsgBox.yesOrNo(
        title: I18nKey.aiChapterFromRecord.tr,
        desc: I18nKey.aiModelMissing.trArgs([missing.map((e) => e.label).join('、')]),
        yesBtnTitle: I18nKey.aiGoDownload.tr,
        yes: () {
          Get.back();
          Nav.scSettingsAi.push();
        },
        no: () => Get.back(),
      );
      return;
    }
    await Nav.scCrMaterialRecord.push(arguments: [book]);
  }
}
