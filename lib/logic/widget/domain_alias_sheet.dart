import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/common/domain_alias.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';
import 'package:repeat_flutter/widget/row/row_widget.dart';
import 'package:repeat_flutter/widget/sheet/sheet.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

/// 域名别名的管理弹层（首页 > 数据 进来）：新增、点一条编辑、删除，每次改动立刻落库。
class DomainAliasSheet {
  static Future<void> open() async {
    final list = List.of(await DomainAlias.loadAll()).obs;

    Future<void> persist() async {
      await DomainAlias.saveAll(list.toList());
      list.refresh();
    }

    await Sheet.showBottomSheet(
      Get.context!,
      head: SheetHead(
        height: RowWidget.rowHeight + RowWidget.dividerHeight,
        widgets: [
          RowWidget.buildMiddleText(I18nKey.domainAlias.tr),
          RowWidget.buildDivider(),
        ],
      ),
      Obx(() {
        return ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: RowWidget.paddingHorizontal, vertical: 8),
              child: Text(
                I18nKey.domainAliasDesc.tr,
                style: TextStyle(fontSize: 13, color: Theme.of(Get.context!).hintColor),
              ),
            ),
            if (list.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Center(child: Text(I18nKey.domainAliasEmpty.tr)),
              ),
            for (var i = 0; i < list.length; i++)
              ListTile(
                title: Text(list[i].name, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(list[i].targets.join('  '), maxLines: 2, overflow: TextOverflow.ellipsis),
                onTap: () async {
                  final edited = await _edit(list, list[i]);
                  if (edited == null) {
                    return;
                  }
                  list[i] = edited;
                  await persist();
                },
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () {
                    final alias = list[i];
                    MsgBox.yesOrNo(
                      title: I18nKey.btnDelete.tr,
                      desc: I18nKey.domainAliasDeleteConfirm.trArgs([alias.name]),
                      yes: () async {
                        Get.back();
                        list.remove(alias);
                        await persist();
                      },
                    );
                  },
                ),
              ),
            RowWidget.buildDividerWithoutColor(),
            RowWidget.buildButtons([
              Button(I18nKey.btnAdd.tr, () async {
                final created = await _edit(list, null);
                if (created == null) {
                  return;
                }
                list.add(created);
                await persist();
              }),
            ]),
          ],
        );
      }),
    );
  }

  /// 新增（[preset] 为 null）或编辑一条。目标一行一个。取消返回 null。
  /// 校验不过时弹提示、对话框不关，让用户接着改。
  static Future<DomainAlias?> _edit(List<DomainAlias> all, DomainAlias? preset) {
    final completer = Completer<DomainAlias?>();
    final name = TextEditingController(text: preset?.name ?? '');
    final targets = TextEditingController(text: preset?.targets.join('\n') ?? '');
    MsgBox.myDialog(
      title: preset == null ? I18nKey.btnAdd.tr : I18nKey.edit.tr,
      barrierDismissible: false,
      content: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: name,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                labelText: I18nKey.domainAliasName.tr,
                hintText: 'home-pc',
              ),
            ),
            TextFormField(
              controller: targets,
              keyboardType: TextInputType.multiline,
              minLines: 2,
              maxLines: 6,
              decoration: InputDecoration(
                labelText: I18nKey.domainAliasTargets.tr,
                hintText: '192.168.1.5\nmacbook-pro.local',
              ),
            ),
          ],
        ),
      ),
      action: MsgBox.yesOrNoAction(
        no: () {
          Get.back();
          completer.complete(null);
        },
        yes: () {
          final n = name.text.trim();
          final t = targets.text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
          if (n.isEmpty || t.isEmpty) {
            Snackbar.show(I18nKey.domainAliasInvalid.tr);
            return;
          }
          if (!DomainAlias.isValidName(n)) {
            Snackbar.show(I18nKey.domainAliasHostInvalid.trArgs([n]));
            return;
          }
          final bad = t.firstWhereOrNull((e) => !DomainAlias.isValidTarget(e));
          if (bad != null) {
            Snackbar.show(I18nKey.domainAliasHostInvalid.trArgs([bad]));
            return;
          }
          // 名字就是 URL 里的主机名，大小写不敏感，不能跟别的别名重。
          if (all.any((e) => !identical(e, preset) && e.name.toLowerCase() == n.toLowerCase())) {
            Snackbar.show(I18nKey.domainAliasDuplicated.trArgs([n]));
            return;
          }
          Get.back();
          completer.complete(DomainAlias(name: n, targets: t));
        },
      ),
    );
    return completer.future;
  }
}
