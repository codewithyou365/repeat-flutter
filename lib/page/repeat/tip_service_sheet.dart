import 'dart:convert';

import 'package:get/get.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/classroom_help.dart';
import 'package:repeat_flutter/logic/model/book_content.dart';
import 'package:repeat_flutter/widget/select/select.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

import 'logic/constant.dart';
import 'repeat_logic.dart';

/// 给一个字段（'q'/'a'/'n'/'t'/'t1'…）挂上或摘掉提示服务。
///
/// 可选的服务来自课堂 'ts'（订阅装出来的提示服务，见 GameListLogic），选中后把它的
/// 'h'/'s'/'k' 抄到字段块上，Tip 表的登记交给 [ClassroomHelp.registerRes]。
/// 提示（'t'/'t1'/…）的配置在课堂那一层，'q'/'a'/'n' 在当前这本书上。
class TipServiceSheet {
  /// 字段块上跟提示服务有关的 key。'i' 是 Tip 行的 id，关掉时一起摘，下次挂上重新登记。
  static const List<String> _keys = ['h', 's', 'k', 'i'];

  static Future<void> show(RepeatLogic logic, String fieldRef, String title) async {
    final helper = logic.state.helper;
    final classroomMap = helper.getClassroomMap();
    if (classroomMap == null) {
      Snackbar.show(I18nKey.labelDataAnomaly.trArgs(["classroom"]));
      return;
    }
    final services = _services(classroomMap);
    if (services.isEmpty) {
      Snackbar.show(I18nKey.tipServiceEmpty.tr);
      return;
    }

    final isTip = VerseField.baseOf(fieldRef) == QaType.tip.acronym;
    final verse = helper.getCurrVerse();
    final map = isTip ? classroomMap : helper.getCurrBookMap();
    if (map == null || (!isTip && verse == null)) {
      Snackbar.show(I18nKey.labelDataAnomaly.trArgs(["book"]));
      return;
    }

    final block = VerseField.of(map, fieldRef);
    final currHash = block?['h'];
    final currService = block?['s'];
    final keys = [
      for (final e in services) '${e.hash == currHash && e.service == currService ? '✓ ' : ''}${e.name}',
      '${block?['h'] == null ? '✓ ' : ''}${I18nKey.tipServiceOff.tr}',
    ];
    final index = await Select.showSheet(title: '$title · ${I18nKey.tipService.tr}', keys: keys);
    if (index == null) return;

    if (index == services.length) {
      VerseField.remove(map, fieldRef, _keys);
    } else {
      final service = services[index];
      VerseField.setStr(map, fieldRef, 'h', service.hash);
      VerseField.setStr(map, fieldRef, 's', service.service);
      // manifest 里提示服务的 contentKey 是前缀，网页按字段分页面：'Japanese' + 'T' → 'JapaneseT'。
      final base = VerseField.baseOf(fieldRef);
      VerseField.setStr(map, fieldRef, 'k', service.key.isEmpty ? null : '${service.key}${base.toUpperCase()}');
      if (!isTip) {
        // 书本级字段从书自己的 'd' 里找 zip（文件跟课堂的在同一个目录），这里把那条记录抄过去。
        final dc = (DownloadContent.toList(classroomMap['d']) ?? []).firstWhereOrNull((e) => e.hash == service.hash);
        final downloads = DownloadContent.toList(map['d']) ?? [];
        if (dc != null && !downloads.any((e) => e.hash == dc.hash)) {
          downloads.add(dc);
          map['d'] = downloads.map((e) => e.toJson()).toList();
        }
      }
    }

    if (isTip) {
      // remove 会把末尾连着的空块截掉，补回来才不会让这一条提示整体消失（同 deleteTip）。
      VerseField.ensureTipCount(classroomMap, VerseField.indexOf(fieldRef) + 1);
      await Db().db.classroomDao.updateContent(Classroom.curr, jsonEncode(classroomMap));
    } else {
      await Db().db.bookDao.updateBookContent(verse!.bookId, jsonEncode(map));
    }
    await logic.reloadTips();
    Snackbar.show(I18nKey.labelSaved.tr);
  }

  /// 课堂 'ts' 里能用的提示服务（解析不了或没 hash 的跳过）。
  static List<ContentEntry> _services(Map<String, dynamic> classroomMap) {
    final raw = classroomMap['ts'];
    if (raw is! List) return [];
    return [
      for (final e in raw)
        if (e is Map<String, dynamic>) ContentEntry.fromJson(e),
    ].where((e) => e.hash.isNotEmpty && e.service.isNotEmpty).toList();
  }
}
