import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:repeat_flutter/common/folder.dart';
import 'package:repeat_flutter/common/hash.dart';
import 'package:repeat_flutter/common/path.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/logic/classroom_help.dart';
import 'package:repeat_flutter/logic/model/book_content.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';
import 'package:repeat_flutter/widget/overlay/overlay.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

import 'game_list_item.dart';
import 'game_list_state.dart';

/// 一个刚落地的游戏包：zip 已经拷进课堂的文件目录并解压好了。
class _StagedZip {
  final DownloadContent dc;

  /// 解压目录顶层的 js 文件，给用户挑入口用。可能是空的（zip 里没有顶层 js）。
  final List<String> jsFiles;

  _StagedZip(this.dc, this.jsFiles);

  String get defaultService {
    if (jsFiles.contains('index.js')) return 'index.js';
    return jsFiles.isEmpty ? 'index.js' : jsFiles.first;
  }
}

/// 课堂游戏的增删改。
///
/// 数据都在 [Classroom.content] 里：宣告是 'g' 数组，zip 文件对象在课堂自己的 'd' 里，
/// 文件落在 [DocPath.getFilesRelativePathOf]。本页只改这份 JSON，
/// Game 表的登记、zip 解压、'i' 回写一律交给 [ClassroomHelp.registerRes]。
class GameListLogic extends GetxController {
  static const String id = "GameListLogic";
  final GameListState state = GameListState();

  final int classroomId = Classroom.curr;

  /// 课堂内容的原始 map。所有写操作都在它身上就地改，保住未知 key。
  Map<String, dynamic> _classroomMap = {};

  @override
  void onInit() {
    super.onInit();
    load();
  }

  List<dynamic> get _games {
    final v = _classroomMap['g'];
    return v is List ? v : <dynamic>[];
  }

  List<DownloadContent> get _downloads {
    return DownloadContent.toList(_classroomMap['d']) ?? [];
  }

  Future<void> load() async {
    state.loading.value = true;

    final classroom = await Db().db.classroomDao.getById(classroomId);
    _classroomMap = _decode(classroom?.content);

    final rootPath = await DocPath.getContentPath();
    final resPath = rootPath.joinPath(DocPath.getFilesRelativePathOf(classroomId));
    final downloads = _downloads;

    final games = _games;
    final items = <GameItem>[];
    for (var i = 0; i < games.length; i++) {
      final raw = games[i];
      if (raw is! Map<String, dynamic>) continue;
      final entry = ContentEntry.fromJson(raw);
      final dc = downloads.firstWhereOrNull((e) => e.hash == entry.hash);
      var zipExists = false;
      var unpacked = false;
      if (dc != null) {
        zipExists = await File(resPath.joinPath(dc.path)).exists();
        unpacked = await Folder.exists(resPath.joinPath(dc.folder).joinPath(dc.pureName));
      }
      items.add(GameItem(
        index: i,
        id: entry.id,
        hash: entry.hash,
        name: entry.name,
        key: entry.key,
        service: entry.service,
        zipName: dc?.url,
        zipExists: zipExists,
        unpacked: unpacked,
      ));
    }

    state.items.assignAll(items);
    state.loading.value = false;
    update([id]);
  }

  static Map<String, dynamic> _decode(String? content) {
    if (content == null || content.isEmpty) return {};
    try {
      final decoded = jsonDecode(content);
      return decoded is Map<String, dynamic> ? decoded : {};
    } catch (e) {
      return {};
    }
  }

  /// 写回课堂内容并重新登记：updateContent 会把 contentVersion +1，
  /// registerRes 的版本指纹因此变化，不会被缓存挡住。
  Future<void> _save() async {
    await Db().db.classroomDao.updateContent(classroomId, jsonEncode(_classroomMap));
    await ClassroomHelp.registerRes();
    await load();
  }

  // ---------------------------------------------------------------- 新增

  Future<void> add() async {
    final staged = await _pickAndUnzip();
    if (staged == null) return;
    _openAddDialog(staged);
  }

  /// 选一个 zip，算 sha1，拷进课堂的文件目录并解压。失败会把拷进去的文件清掉。
  Future<_StagedZip?> _pickAndUnzip() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    if (result == null || result.files.single.path == null) {
      Snackbar.show(I18nKey.labelLocalImportCancel.tr);
      return null;
    }
    final pickedPath = result.files.single.path!;

    return await showOverlay<_StagedZip?>(() async {
      final hash = await Hash.toSha1(pickedPath);
      if (hash.isEmpty) {
        Snackbar.show(I18nKey.labelDataAnomalyWithArg.trArgs(['91']));
        return null;
      }
      final dc = DownloadContent(url: p.basename(pickedPath), hash: hash);

      final rootPath = await DocPath.getContentPath();
      final resPath = rootPath.joinPath(DocPath.getFilesRelativePathOf(classroomId));
      final zipPath = resPath.joinPath(dc.path);
      final destPath = resPath.joinPath(dc.folder).joinPath(dc.pureName);

      await Folder.ensureExists(resPath.joinPath(dc.folder));
      await File(pickedPath).copy(zipPath);

      final ok = await ClassroomHelp.unzipGame(zipPath, destPath);
      if (!ok) {
        // 解压不了就不留垃圾：这个 zip 还没写进 'd'，没人会再引用它。
        await _deleteFileQuietly(zipPath);
        await Folder.delete(destPath);
        Snackbar.show(I18nKey.gameUnzipFailed.tr);
        return null;
      }
      return _StagedZip(dc, await _listJsFiles(destPath));
    }, I18nKey.labelImporting.tr);
  }

  /// 解压目录顶层的 js 文件名，按字母序。
  static Future<List<String>> _listJsFiles(String dirPath) async {
    try {
      final dir = Directory(dirPath);
      if (!await dir.exists()) return [];
      final ret = <String>[];
      await for (final f in dir.list()) {
        if (f is File && f.path.toLowerCase().endsWith('.js')) {
          ret.add(p.basename(f.path));
        }
      }
      ret.sort();
      return ret;
    } catch (e) {
      return [];
    }
  }

  void _openAddDialog(_StagedZip staged) {
    final nameTec = TextEditingController();
    final keyTec = TextEditingController();
    final serviceTec = TextEditingController(text: staged.defaultService);
    MsgBox.myDialog(
      title: I18nKey.manageGame.tr,
      barrierDismissible: false,
      content: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: nameTec,
              maxLines: 1,
              decoration: InputDecoration(labelText: I18nKey.gameName.tr),
            ),
            TextFormField(
              controller: keyTec,
              maxLines: 1,
              decoration: InputDecoration(labelText: I18nKey.gameKey.tr),
            ),
            TextFormField(
              controller: serviceTec,
              maxLines: 1,
              decoration: InputDecoration(
                labelText: I18nKey.gameService.tr,
                helperText: staged.jsFiles.isEmpty ? null : staged.jsFiles.join(' / '),
              ),
            ),
          ],
        ),
      ),
      action: MsgBox.yesOrNoAction(
        yes: () {
          final name = nameTec.text.trim();
          if (!_checkName(name, null)) {
            return;
          }
          Get.back();
          _commitAdd(staged, name, keyTec.text.trim(), serviceTec.text.trim());
        },
        no: () {
          Get.back();
          // 取消就把刚落地的包清掉，别在磁盘上留个没人引用的 zip。
          _dropStaged(staged);
        },
      ),
    );
  }

  Future<void> _commitAdd(_StagedZip staged, String name, String key, String service) async {
    _addDownload(staged.dc);
    final games = _classroomMap['g'] is List ? _classroomMap['g'] as List<dynamic> : <dynamic>[];
    games.add(<String, dynamic>{
      'h': staged.dc.hash,
      'n': name,
      'k': key,
      // 入口没填就按 index.js 走，跟 defaultService 的兜底一致。
      's': service.isEmpty ? 'index.js' : service,
      // 不写 'i'，交给 registerRes 回写
    });
    _classroomMap['g'] = games;
    await _save();
  }

  Future<void> _dropStaged(_StagedZip staged) async {
    if (_downloads.any((e) => e.hash == staged.dc.hash)) {
      // 这个 hash 已经在课堂 'd' 里了（用户选了个已有的包），文件不能删。
      return;
    }
    await _deleteZipFiles(staged.dc);
  }

  // ---------------------------------------------------------------- 修改

  /// 改名。'i' 和 'h' 原样留着——registerRes 按 'i' 找到 Game 行就地改 name，
  /// 存档和分数都保得住；'i' 一丢就会变成删旧建新。
  Future<void> rename(GameItem item, String name) async {
    name = name.trim();
    if (!_checkName(name, item.index)) return;
    final raw = _rawAt(item.index);
    if (raw == null) return;
    raw['n'] = name;
    await _save();
  }

  Future<void> setKey(GameItem item, String key) async {
    final raw = _rawAt(item.index);
    if (raw == null) return;
    raw['k'] = key.trim();
    await _save();
  }

  Future<void> setService(GameItem item, String service) async {
    service = service.trim();
    if (service.isEmpty) return;
    final raw = _rawAt(item.index);
    if (raw == null) return;
    raw['s'] = service;
    await _save();
  }

  /// 解压目录里的 js 文件，给「改入口」用；没解压出来就是空的。
  Future<List<String>> listJsFiles(GameItem item) async {
    final dc = _downloads.firstWhereOrNull((e) => e.hash == item.hash);
    if (dc == null) return [];
    final rootPath = await DocPath.getContentPath();
    final resPath = rootPath.joinPath(DocPath.getFilesRelativePathOf(classroomId));
    return await _listJsFiles(resPath.joinPath(dc.folder).joinPath(dc.pureName));
  }

  /// 换包：新包落地后把 'h' 指过去，旧包没人引用了就连文件一起清掉。
  Future<void> replaceZip(GameItem item) async {
    final staged = await _pickAndUnzip();
    if (staged == null) return;
    final raw = _rawAt(item.index);
    if (raw == null) {
      await _dropStaged(staged);
      return;
    }
    final oldHash = item.hash;
    raw['h'] = staged.dc.hash;
    _addDownload(staged.dc);
    if (oldHash != staged.dc.hash) {
      await _dropUnreferencedZip(oldHash);
    }
    await _save();
  }

  // ---------------------------------------------------------------- 删除

  Future<void> delete(GameItem item) async {
    final games = _classroomMap['g'];
    if (games is! List || item.index >= games.length) return;
    games.removeAt(item.index);
    await _dropUnreferencedZip(item.hash);

    // lastGameIndex 存的是下标不是 id：删掉一个游戏会让后面的整体前移，
    // 原来选中的下标不越界也不报错，只是静默指向了另一个游戏。所以这里归零。
    await Db().db.crKvDao.insertOrReplace(CrKv(classroomId, CrK.lastGameIndex, '0'));

    await _save();
  }

  // ---------------------------------------------------------------- 公共

  Map<String, dynamic>? _rawAt(int index) {
    final games = _classroomMap['g'];
    if (games is! List || index < 0 || index >= games.length) return null;
    final raw = games[index];
    return raw is Map<String, dynamic> ? raw : null;
  }

  /// 名字非空且在 'g' 里唯一（[skipIndex] 是自己那一条，改名时要跳过）。
  bool _checkName(String name, int? skipIndex) {
    if (name.isEmpty) {
      Snackbar.show(I18nKey.gameNameEmpty.tr);
      return false;
    }
    final games = _games;
    for (var i = 0; i < games.length; i++) {
      if (i == skipIndex) continue;
      final raw = games[i];
      if (raw is Map<String, dynamic> && raw['n'] == name) {
        Snackbar.show(I18nKey.gameNameDuplicated.tr);
        return false;
      }
    }
    return true;
  }

  void _addDownload(DownloadContent dc) {
    final list = _downloads;
    if (list.any((e) => e.hash == dc.hash)) return;
    list.add(dc);
    _classroomMap['d'] = list.map((e) => e.toJson()).toList();
  }

  /// 没有任何游戏再引用这个 hash 了，就把它从 'd' 里摘掉，文件也删干净。
  Future<void> _dropUnreferencedZip(String hash) async {
    if (hash.isEmpty) return;
    if (_games.any((e) => e is Map<String, dynamic> && e['h'] == hash)) return;
    final list = _downloads;
    final dc = list.firstWhereOrNull((e) => e.hash == hash);
    if (dc == null) return;
    list.removeWhere((e) => e.hash == hash);
    _classroomMap['d'] = list.map((e) => e.toJson()).toList();
    await _deleteZipFiles(dc);
  }

  Future<void> _deleteZipFiles(DownloadContent dc) async {
    final rootPath = await DocPath.getContentPath();
    final resPath = rootPath.joinPath(DocPath.getFilesRelativePathOf(classroomId));
    await _deleteFileQuietly(resPath.joinPath(dc.path));
    await Folder.delete(resPath.joinPath(dc.folder).joinPath(dc.pureName));
  }

  static Future<void> _deleteFileQuietly(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) {
        await f.delete();
      }
    } on FileSystemException catch (_) {}
  }
}
