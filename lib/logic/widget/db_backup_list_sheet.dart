import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:repeat_flutter/common/file_util.dart';
import 'package:repeat_flutter/common/path.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';
import 'package:repeat_flutter/widget/overlay/overlay.dart';
import 'package:repeat_flutter/widget/row/row_widget.dart';
import 'package:repeat_flutter/widget/sheet/sheet.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

class DbBackupListSheet {
  static Future<void> show({required String dbPath}) {
    return Sheet.showBottomSheet(
      Get.context!,
      _DbBackupListBody(dbPath: dbPath),
      head: SheetHead(
        height: RowWidget.rowHeight + RowWidget.dividerHeight,
        widgets: [
          RowWidget.buildMiddleText(I18nKey.labelBackupListTitle.tr),
          RowWidget.buildDivider(),
        ],
      ),
      rate: 1,
    );
  }
}

class _DbBackupListBody extends StatefulWidget {
  final String dbPath;

  const _DbBackupListBody({required this.dbPath});

  @override
  State<_DbBackupListBody> createState() => _DbBackupListBodyState();
}

class _DbBackupListBodyState extends State<_DbBackupListBody> {
  List<_BackupItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    final dirPath = widget.dbPath.substring(0, widget.dbPath.lastIndexOf('/'));
    final dir = Directory(dirPath);
    final baseName = FileUtil.toFileName(widget.dbPath);
    final prefix = '$baseName.bak_';
    final List<_BackupItem> items = [];
    if (await dir.exists()) {
      await for (final entity in dir.list()) {
        if (entity is! File) continue;
        final name = FileUtil.toFileName(entity.path);
        if (!name.startsWith(prefix)) continue;
        int size = 0;
        try {
          size = await entity.length();
        } catch (_) {}
        items.add(_BackupItem(
          file: entity,
          name: name,
          timestamp: name.substring(prefix.length),
          size: size,
        ));
      }
    }
    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _saveAs(_BackupItem item) async {
    final permissionStatus = await Permission.manageExternalStorage.request();
    if (permissionStatus != PermissionStatus.granted) {
      Snackbar.show(I18nKey.labelStoragePermissionDenied.tr);
      return;
    }
    final selectedDirectory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: I18nKey.labelSelectDirectoryToSave.trArgs([item.name]),
    );
    if (selectedDirectory == null) {
      Snackbar.show(I18nKey.labelSaveCancel.tr);
      return;
    }
    try {
      await item.file.copy(selectedDirectory.joinPath(item.name));
      Snackbar.show(I18nKey.labelSaveSuccess.trArgs([item.name]));
    } catch (_) {
      Snackbar.show(I18nKey.labelDirectoryPermissionDenied.trArgs([selectedDirectory]));
    }
  }

  void _restore(_BackupItem item) {
    MsgBox.yesOrNo(
      title: I18nKey.labelTips.tr,
      desc: I18nKey.labelRestoreBackup.trArgs([item.name]),
      yes: () async {
        Get.back();
        bool ok = false;
        String? errMsg;
        await showOverlay(() async {
          try {
            final ts = DateTime.now().toIso8601String().replaceAll(RegExp(r'[:.-]'), '').substring(0, 15);
            await File(widget.dbPath).copy('${widget.dbPath}.bak_$ts');
          } catch (_) {}
          try {
            await Db().db.close();
            final cur = File(widget.dbPath);
            if (await cur.exists()) await cur.delete();
            await item.file.copy(widget.dbPath);
            await Db().init();
            ok = true;
          } catch (e) {
            errMsg = e.toString();
          }
          Get.back();
          Snackbar.show(ok ? I18nKey.labelRestoreSuccess.tr : errMsg ?? '');
        }, I18nKey.labelRestoring.tr);
        await _load();
      },
    );
  }

  void _delete(_BackupItem item) {
    MsgBox.yesOrNo(
      title: I18nKey.labelTips.tr,
      desc: I18nKey.labelDeleteBackup.trArgs([item.name]),
      yes: () async {
        Get.back();
        try {
          await item.file.delete();
        } catch (_) {}
        Snackbar.show(I18nKey.labelDeleted.tr);
        await _load();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_items.isEmpty) {
      return Center(child: Text(I18nKey.labelNoBackup.tr));
    }
    return ListView.separated(
      itemCount: _items.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = _items[index];
        return ListTile(
          title: Text(_formatTimestamp(item.timestamp)),
          subtitle: Text(
            '${_formatSize(item.size)}  ${item.name}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: I18nKey.btnRestore.tr,
                icon: const Icon(Icons.restore),
                onPressed: () => _restore(item),
              ),
              IconButton(
                tooltip: I18nKey.btnSaveAs.tr,
                icon: const Icon(Icons.save_alt),
                onPressed: () => _saveAs(item),
              ),
              IconButton(
                tooltip: I18nKey.btnDelete.tr,
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _delete(item),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTimestamp(String ts) {
    if (ts.length >= 15 && ts[8] == 'T') {
      final y = ts.substring(0, 4);
      final mo = ts.substring(4, 6);
      final d = ts.substring(6, 8);
      final h = ts.substring(9, 11);
      final mi = ts.substring(11, 13);
      final s = ts.substring(13, 15);
      return '$y-$mo-$d $h:$mi:$s';
    }
    return ts;
  }

  String _formatSize(int bytes) {
    const units = ['B', 'KB', 'MB', 'GB'];
    double v = bytes.toDouble();
    int unit = 0;
    while (v >= 1024 && unit < units.length - 1) {
      v /= 1024;
      unit++;
    }
    return '${v.toStringAsFixed(unit == 0 ? 0 : 1)} ${units[unit]}';
  }
}

class _BackupItem {
  final File file;
  final String name;
  final String timestamp;
  final int size;

  _BackupItem({
    required this.file,
    required this.name,
    required this.timestamp,
    required this.size,
  });
}
