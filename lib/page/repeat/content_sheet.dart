import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/doc_help.dart';
import 'package:repeat_flutter/logic/model/book_content.dart';
import 'package:repeat_flutter/nav.dart';
import 'package:repeat_flutter/page/editor/editor_args.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';
import 'package:repeat_flutter/widget/row/row_widget.dart';
import 'package:repeat_flutter/widget/sheet/sheet.dart';

import 'logic/constant.dart';
import 'repeat_logic.dart';

/// 一个字段（'q'/'a'/'t1'…）内容数组的块编辑器。
///
/// 数组里每一项是一段正文、一张图或一个网页（见 [VerseContentItem]），**位置就是显示位置**，
/// 所以这里能做的就三件事：调顺序（拖手柄）、加一项（底部三个入口）、删一项。
/// 点正文那一行进编辑器改这一段，点网页那一行改它的显示高度。
///
/// 每一步都是"改完就存库"：一次操作对应一次 [Helper.editCurrItems]，没有攒着的草稿，
/// 半路关掉 sheet 也不会丢已经做完的那几步。存库时老的 'text' 会被升级成 'content'
/// （见 [VerseField.setItems]），所以只写过 'text' 的老数据点一下就完成了迁移。
class ContentSheet {
  static Future<void> show(RepeatLogic logic, String fieldRef, String title) async {
    await Sheet.withHeaderAndBody(
      Get.context!,
      Column(
        key: GlobalKey(),
        mainAxisSize: MainAxisSize.min,
        children: [
          RowWidget.buildMiddleText(title),
          RowWidget.buildDivider(),
        ],
      ),
      StatefulBuilder(
        builder: (context, setState) {
          final items = _items(logic, fieldRef);
          return ReorderableListView.builder(
            // 整行都能点（正文进编辑器、网页改高度），拖动只认右边那个手柄。
            buildDefaultDragHandles: false,
            itemCount: items.length,
            itemBuilder: (context, index) => _row(logic, fieldRef, items[index], index, setState),
            footer: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RowWidget.buildDividerWithoutColor(),
                RowWidget.buildSelect(
                  title: I18nKey.contentTextAdd.tr,
                  leading: const Icon(Icons.notes, size: 20, color: Colors.grey),
                  onTap: () => _addText(logic, fieldRef, setState),
                ),
                RowWidget.buildSelect(
                  title: I18nKey.verseImageAdd.tr,
                  leading: const Icon(Icons.image_outlined, size: 20, color: Colors.grey),
                  onTap: () => _addFile(logic, fieldRef, MediaType.image, setState),
                ),
                RowWidget.buildSelect(
                  title: I18nKey.contentWebAdd.tr,
                  leading: const Icon(Icons.public, size: 20, color: Colors.grey),
                  onTap: () => _addFile(logic, fieldRef, MediaType.web, setState),
                ),
              ],
            ),
            // onReorderItem 给的 newIndex 已经是"这一项挪走之后"的落点，不用自己减一
            // （老的 onReorder 要，已经废弃了）。
            onReorderItem: (oldIndex, newIndex) async {
              if (newIndex == oldIndex) {
                return;
              }
              await _edit(logic, fieldRef, (list) {
                if (oldIndex >= list.length || newIndex >= list.length) {
                  return;
                }
                list.insert(newIndex, list.removeAt(oldIndex));
              });
              setState(() {});
            },
          );
        },
      ),
    );
  }

  static List<VerseContentItem> _items(RepeatLogic logic, String fieldRef) {
    final map = logic.state.helper.getCurrVerseMap();
    if (map == null) {
      return const <VerseContentItem>[];
    }
    return VerseField.getItems(map, fieldRef);
  }

  /// 改一次内容数组并存库。[edit] 就地改的是**库里现读出来的那一份**（见 editCurrItems），
  /// 所以这里传的下标必须来自刚渲染的那一次，别拿旧列表的下标隔着几次操作再用。
  static Future<void> _edit(
    RepeatLogic logic,
    String fieldRef,
    void Function(List<VerseContentItem> items) edit, {
    DownloadContent? register,
  }) async {
    final ok = await logic.state.helper.editCurrItems(fieldRef, edit, register: register);
    if (ok) {
      logic.update([RepeatLogic.id]);
    }
  }

  static Widget _row(
    RepeatLogic logic,
    String fieldRef,
    VerseContentItem item,
    int index,
    StateSetter setState,
  ) {
    final text = item.text;
    final IconData icon;
    final String summary;
    VoidCallback? onTap;
    if (text != null) {
      icon = Icons.notes;
      summary = _summaryOfText(text);
      onTap = () => _editText(logic, fieldRef, index, text, setState);
    } else {
      final d = logic.state.helper.resolveItem(item);
      final ext = d?.extension.toLowerCase() ?? '';
      if (d == null) {
        // 文件被删了、'd' 里没登记——这一行还是要显示出来，不然用户看不见"这里有一项坏内容"，
        // 也就没法把它删掉。
        icon = Icons.help_outline;
        summary = '${I18nKey.contentItemMissing.tr}: ${item.hash}';
      } else if (MediaType.web.allowedExtensions.contains(ext)) {
        icon = Icons.public;
        summary = d.n ?? d.name;
        // 网页没有"内容多高"这一说，高度得手填，见 [VerseField.itemHeight]。
        onTap = () => _editHeight(logic, fieldRef, index, item, setState);
      } else if (MediaType.image.allowedExtensions.contains(ext)) {
        icon = Icons.image_outlined;
        summary = d.n ?? d.name;
      } else {
        icon = Icons.insert_drive_file_outlined;
        summary = d.n ?? d.name;
      }
    }
    return Padding(
      key: ValueKey('$index-${item.hash ?? item.text}'),
      padding: const EdgeInsets.symmetric(horizontal: RowWidget.paddingHorizontal),
      child: SizedBox(
        height: RowWidget.rowHeight,
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onTap,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    summary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: RowWidget.titleFontSize),
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.grey),
              onPressed: () => _delete(logic, fieldRef, index, setState),
            ),
            ReorderableDragStartListener(
              index: index,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.drag_handle, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 列表里这一项显示成一行：正文取第一段有字的，多行只看得见第一行。
  static String _summaryOfText(String text) {
    for (var line in text.split('\n')) {
      final t = line.trim();
      if (t.isNotEmpty) {
        return t;
      }
    }
    return text.trim();
  }

  static void _delete(RepeatLogic logic, String fieldRef, int index, StateSetter setState) {
    MsgBox.yesOrNo(
      title: I18nKey.labelWarning.tr,
      desc: I18nKey.contentDeleteItem.tr,
      yes: () async {
        Get.back();
        await _edit(logic, fieldRef, (list) {
          if (index < list.length) {
            list.removeAt(index);
          }
        });
        setState(() {});
      },
    );
  }

  /// 改第 [index] 段正文。清空就是删掉这一段——一段空正文在界面上是看不见的，
  /// 留着只会在列表里多一行点不出东西的空行。
  static Future<void> _editText(
    RepeatLogic logic,
    String fieldRef,
    int index,
    String value,
    StateSetter setState,
  ) async {
    await Nav.editor.push(
      arguments: EditorArgs(
        title: I18nKey.content.tr,
        value: value,
        save: (str) async {
          await _edit(logic, fieldRef, (list) {
            if (index >= list.length) {
              return;
            }
            if (str.trim().isEmpty) {
              list.removeAt(index);
            } else {
              list[index] = VerseContentItem.text(str);
            }
          });
        },
      ),
    );
    setState(() {});
  }

  static Future<void> _addText(RepeatLogic logic, String fieldRef, StateSetter setState) async {
    await Nav.editor.push(
      arguments: EditorArgs(
        title: I18nKey.content.tr,
        value: '',
        save: (str) async {
          if (str.trim().isEmpty) {
            return;
          }
          await _edit(logic, fieldRef, (list) => list.add(VerseContentItem.text(str)));
        },
      ),
    );
    setState(() {});
  }

  /// 网页项的显示高度，见 [VerseField.itemHeight]：小于等于 1 是正文区的比例，大于 1 是像素。
  /// 填空/填不出数字就是不写，回到自适应。
  static Future<void> _editHeight(
    RepeatLogic logic,
    String fieldRef,
    int index,
    VerseContentItem item,
    StateSetter setState,
  ) async {
    final model = RxString(item.height?.toString() ?? '');
    MsgBox.strInputWithYesOrNo(
      model,
      I18nKey.labelHeight.tr,
      null,
      yes: () async {
        Get.back();
        final h = double.tryParse(model.value.trim());
        await _edit(logic, fieldRef, (list) {
          if (index >= list.length) {
            return;
          }
          final cur = list[index];
          final hash = cur.hash;
          if (hash == null) {
            return;
          }
          list[index] = VerseContentItem.file(hash, height: h);
        });
        setState(() {});
      },
    );
  }

  /// 往内容末尾插一个文件（图或网页）。文件拷进课堂目录、登记进这一节的 'd'，
  /// 内容数组里只加一项 hash——**怎么渲染由扩展名决定**，所以图和网页走的是同一条路。
  static Future<void> _addFile(
    RepeatLogic logic,
    String fieldRef,
    MediaType type,
    StateSetter setState,
  ) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: type.allowedExtensions,
    );
    final d = await DocHelp.tryCopyToDocDir(
      result: result,
      allowedExtensions: type.allowedExtensions,
    );
    if (d == null) {
      return;
    }
    await _edit(
      logic,
      fieldRef,
      (list) => list.add(VerseContentItem.file(d.hash)),
      register: d,
    );
    setState(() {});
  }
}
