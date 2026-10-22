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
import 'package:repeat_flutter/logic/game_subscription_help.dart';
import 'package:repeat_flutter/logic/model/book_content.dart';
import 'package:repeat_flutter/logic/model/game_manifest.dart';
import 'package:repeat_flutter/nav.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';
import 'package:repeat_flutter/widget/overlay/overlay.dart';
import 'package:repeat_flutter/widget/select/select.dart';
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

/// 课堂游戏（和订阅装出来的提示服务）的增删改。
///
/// 数据都在 [Classroom.content] 里：游戏宣告是 'g' 数组，订阅里的提示服务入口是 'ts' 数组，
/// zip 文件对象在课堂自己的 'd' 里，
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

  /// 订阅装出来的提示服务入口：{'h','n','s','k','u','ek'}。
  ///
  /// 只是个目录，不登记任何表；提示字段真正用的是字段块自己的 'h'/'s'/'k'
  /// （见 [ClassroomHelp._registerTips]），这里记着是为了列表显示和给提示挑服务。
  List<dynamic> get _tipServices {
    final v = _classroomMap['ts'];
    return v is List ? v : <dynamic>[];
  }

  /// 升级/换包时改过的书本内容，[_save] 时一起写回。
  final Map<int, Map<String, dynamic>> _dirtyBooks = {};

  List<DownloadContent> get _downloads {
    return DownloadContent.toList(_classroomMap['d']) ?? [];
  }

  /// 课堂 'gs' 里的订阅。返回的是新对象，改完要用 [_saveSubscriptions] 写回去。
  List<GameSubscription> get _subscriptions {
    return GameSubscription.toList(_classroomMap['gs']);
  }

  void _saveSubscriptions(List<GameSubscription> list) {
    _classroomMap['gs'] = list.map((e) => e.toJson()).toList();
  }

  Future<void> load() async {
    state.loading.value = true;

    final classroom = await Db().db.classroomDao.getById(classroomId);
    _classroomMap = _decode(classroom?.content);

    final rootPath = await DocPath.getContentPath();
    final resPath = rootPath.joinPath(DocPath.getFilesRelativePathOf(classroomId));
    final downloads = _downloads;
    final subs = _subscriptions;

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
      final sub = entry.subUrl.isEmpty ? null : subs.firstWhereOrNull((e) => e.url == entry.subUrl);
      items.add(
        GameItem(
          index: i,
          id: entry.id,
          hash: entry.hash,
          name: entry.name,
          key: entry.key,
          service: entry.service,
          zipName: dc?.url,
          zipExists: zipExists,
          unpacked: unpacked,
          subUrl: entry.subUrl,
          entryKey: entry.entryKey,
          subName: sub?.name ?? '',
          subVersion: sub?.version ?? 0,
        ),
      );
    }

    final tipServices = <TipServiceItem>[];
    for (final raw in _tipServices) {
      if (raw is! Map<String, dynamic>) continue;
      final entry = ContentEntry.fromJson(raw);
      final dc = downloads.firstWhereOrNull((e) => e.hash == entry.hash);
      var unpacked = false;
      if (dc != null) {
        unpacked = await Folder.exists(resPath.joinPath(dc.folder).joinPath(dc.pureName));
      }
      final sub = subs.firstWhereOrNull((e) => e.url == entry.subUrl);
      tipServices.add(
        TipServiceItem(
          hash: entry.hash,
          name: entry.name,
          service: entry.service,
          unpacked: unpacked,
          subUrl: entry.subUrl,
          entryKey: entry.entryKey,
          subName: sub?.name ?? '',
          subVersion: sub?.version ?? 0,
        ),
      );
    }

    state.items.assignAll(items);
    state.tipServices.assignAll(tipServices);
    state.subscriptions.assignAll(subs);
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
    for (final e in _dirtyBooks.entries) {
      await Db().db.bookDao.updateBookContent(e.key, jsonEncode(e.value));
    }
    _dirtyBooks.clear();
    await Db().db.classroomDao.updateContent(classroomId, jsonEncode(_classroomMap));
    await ClassroomHelp.registerRes();
    await load();
  }

  // ---------------------------------------------------------------- 新增

  /// 本地 zip 和订阅地址二选一。
  Future<void> add() async {
    final index = await Select.showSheet(
      title: I18nKey.manageSubscription.tr,
      keys: [
        I18nKey.gameAddFromLocal.tr,
        I18nKey.gameAddFromSubscription.tr,
      ],
    );
    if (index == null) return;
    if (index == 0) {
      await addFromLocal();
    } else {
      await addFromSubscription();
    }
  }

  Future<void> addFromLocal() async {
    final staged = await _pickAndUnzip();
    if (staged == null) return;
    _openAddDialog(staged);
  }

  /// 让用户填一个 manifest.json 的地址（支持扫码），然后订阅。
  Future<void> addFromSubscription() async {
    final RxString model = ''.obs;
    MsgBox.strInputWithYesOrNo(
      model,
      I18nKey.gameSubscriptionUrl.tr,
      null,
      qrPagePath: Nav.scan.path,
      yes: () {
        Get.back();
        subscribe(model.value);
      },
    );
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
      title: I18nKey.gameAddFromLocal.tr,
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
      // 本地导入的显式标空，别让它被当成某个订阅的条目
      'u': '',
      'ek': '',
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

  // ---------------------------------------------------------------- 订阅

  /// 订阅一个 manifest 地址：抓 manifest → 下包 → 把包里的游戏全装上。
  ///
  /// 已经订阅过的地址不重复订阅，直接对它跑一次更新。
  Future<void> subscribe(String url) async {
    url = url.trim();
    if (url.isEmpty) return;

    if (_subscriptions.any((e) => e.url == url)) {
      Snackbar.show(I18nKey.gameAlreadySubscribed.tr);
      await checkUpdates();
      return;
    }

    final installed = await showOverlay<int?>(() async {
      final manifest = await GameSubscriptionHelp.fetchManifest(url);
      if (manifest == null) return null;
      final dc = await GameSubscriptionHelp.download(classroomId, url, manifest);
      if (dc == null) return null;
      await _applyManifest(url, manifest, dc);
      // 提示服务不算游戏，提示里只报装上了几个游戏。
      return manifest.games.where((e) => !e.isTip).length;
    }, I18nKey.labelImporting.tr);

    if (installed == null) return;
    await _save();
    Snackbar.show(I18nKey.gameSubscribed.trArgs(['$installed']));
  }

  /// 逐个订阅去问服务器要 manifest，版本变大（或者本地条目跟 manifest 对不上）就更新。
  ///
  /// 单个订阅失败不打断整轮，最后汇总提示。
  Future<void> checkUpdates() async {
    final subs = _subscriptions;
    if (subs.isEmpty) {
      Snackbar.show(I18nKey.gameSubscriptionEmpty.tr);
      return;
    }

    final result = await showOverlay<List<int>>(() async {
      var updated = 0;
      var failed = 0;
      for (final sub in subs) {
        final manifest = await GameSubscriptionHelp.fetchManifest(sub.url);
        if (manifest == null) {
          failed++;
          continue;
        }
        if (!_needsApply(sub, manifest)) continue;
        // 包没换（version 变了但 hash 没变，或者只是本地条目被删过）时，
        // download 会命中已有文件直接返回，不会真的走网络。
        final dc = await GameSubscriptionHelp.download(classroomId, sub.url, manifest);
        if (dc == null) {
          failed++;
          continue;
        }
        await _applyManifest(sub.url, manifest, dc);
        updated++;
      }
      return [updated, failed];
    }, I18nKey.gameCheckUpdate.tr);

    final updated = result[0];
    final failed = result[1];
    if (updated > 0) {
      await _save();
      Snackbar.show(I18nKey.gameUpdateDone.trArgs(['$updated']));
    } else if (failed == 0) {
      Snackbar.show(I18nKey.gameUpdateNone.tr);
    }
    if (failed > 0) {
      Snackbar.show(I18nKey.gameUpdateFailed.trArgs(['$failed']));
    }
  }

  /// 要不要动这个订阅：版本变大要动；版本没变但本地条目跟 manifest 对不上
  /// （用户删过某个游戏）也要动——manifest 是唯一真相，删掉的下次更新会加回来。
  /// 游戏和提示服务分开比：同一个 key 从游戏变成提示服务（老包升级上来）也算对不上。
  bool _needsApply(GameSubscription sub, GameManifest manifest) {
    if (manifest.version > sub.version) return true;
    bool same(List<dynamic> list, bool tip) {
      final local = <String>{};
      for (final raw in list) {
        if (raw is Map<String, dynamic> && raw['u'] == sub.url) {
          local.add((raw['ek'] ?? '').toString());
        }
      }
      final remote = manifest.games.where((e) => e.isTip == tip).map((e) => e.key).toSet();
      return local.length == remote.length && local.containsAll(remote);
    }

    return !same(_games, false) || !same(_tipServices, true);
  }

  /// 把 manifest 落到课堂内容里：manifest 是唯一真相，本地按 (订阅, ek) 对齐。
  ///
  /// 已装的就地改 'h'/'s'，**'i' 和 'n' 一律不动**——'i' 一丢 registerRes 就会走
  /// 「删旧建新」，游戏存档和分数就没了；'n' 是用户可能改过的名字，以用户的为准。
  Future<void> _applyManifest(String subUrl, GameManifest manifest, DownloadContent dc) async {
    _addDownload(dc);

    final oldSubs = _subscriptions;
    final oldHash = oldSubs.firstWhereOrNull((e) => e.url == subUrl)?.hash ?? '';

    final games = _classroomMap['g'] is List ? _classroomMap['g'] as List<dynamic> : <dynamic>[];
    final existing = <String, Map<String, dynamic>>{};
    for (final raw in games) {
      if (raw is Map<String, dynamic> && raw['u'] == subUrl) {
        existing[(raw['ek'] ?? '').toString()] = raw;
      }
    }

    for (final entry in manifest.games.where((e) => !e.isTip)) {
      final raw = existing[entry.key];
      if (raw != null) {
        raw['h'] = dc.hash;
        raw['s'] = entry.service;
        // 'k' 跟 's' 一样是包定义的（网页靠它决定进哪个游戏页面）。
        // manifest 没写就别动本地的，用户可能自己填过。
        if (entry.contentKey.isNotEmpty) {
          raw['k'] = entry.contentKey;
        }
      } else {
        games.add(<String, dynamic>{
          'h': dc.hash,
          'n': _uniqueName(entry.name),
          'k': entry.contentKey,
          's': entry.service,
          'u': subUrl,
          'ek': entry.key,
          // 不写 'i'，交给 registerRes 回写
        });
      }
    }

    // manifest 里没有的游戏入口就从课堂移除（变成提示服务的也算，比如老包里的 japanese）。
    final remote = manifest.games.where((e) => !e.isTip).map((e) => e.key).toSet();
    final beforeRemove = games.length;
    games.removeWhere((raw) => raw is Map<String, dynamic> && raw['u'] == subUrl && !remote.contains((raw['ek'] ?? '').toString()));
    _classroomMap['g'] = games;
    if (games.length != beforeRemove) {
      await _resetLastGameIndex();
    }

    // 提示服务没有存档和用户改名，直接按 manifest 整组重写。
    // 换包前先记下旧入口的 's'，下面迁移提示字段时把入口也一起跟上。
    final oldServices = <String, String>{};
    for (final raw in _tipServices) {
      if (raw is Map<String, dynamic> && raw['u'] == subUrl) {
        oldServices[(raw['ek'] ?? '').toString()] = (raw['s'] ?? '').toString();
      }
    }
    final tipServices = _tipServices.where((raw) => !(raw is Map<String, dynamic> && raw['u'] == subUrl)).toList();
    final serviceMoves = <String, String>{};
    for (final entry in manifest.games.where((e) => e.isTip)) {
      tipServices.add(<String, dynamic>{
        'h': dc.hash,
        'n': entry.name,
        's': entry.service,
        // 提示服务的 'k' 是前缀，挂到字段上时再按字段补字母（见 TipServiceSheet）。
        'k': entry.contentKey,
        'u': subUrl,
        'ek': entry.key,
      });
      final old = oldServices[entry.key];
      if (old != null && old.isNotEmpty && old != entry.service) {
        serviceMoves[old] = entry.service;
      }
    }
    _classroomMap['ts'] = tipServices;

    // 名字跟游戏的 'n' 一样以用户的为准：已有订阅且名字非空就留着，
    // 只有新订阅（或用户清空过名字）才拿 manifest 的。
    final oldName = oldSubs.firstWhereOrNull((e) => e.url == subUrl)?.name ?? '';
    oldSubs.removeWhere((e) => e.url == subUrl);
    oldSubs.add(
      GameSubscription(
        url: subUrl,
        version: manifest.version,
        hash: dc.hash,
        name: oldName.isNotEmpty ? oldName : (manifest.name.isEmpty ? subUrl : manifest.name),
      ),
    );
    _saveSubscriptions(oldSubs);

    if (oldHash.isNotEmpty && oldHash != dc.hash) {
      // 提示字段手里攥的是 zip 的 hash，不跟着换的话旧包一删提示就打不开了。
      await _moveTipFields(oldHash, dc, serviceMoves);
      await _dropUnreferencedZip(oldHash);
    }
  }

  /// 把还指着旧包的提示字段挪到新包上：课堂级的 't'/'t1'/… 和每本书的 'q'/'a'/'n'。
  ///
  /// [serviceMoves] 是旧入口 → 新入口，包里的入口文件改了路径时用；字段的 'k' 不动。
  /// 书本级的字段从书自己的 'd' 里找 zip，所以那边的 'd' 也要换成新包。
  Future<void> _moveTipFields(String oldHash, DownloadContent dc, Map<String, String> serviceMoves) async {
    void move(Map<String, dynamic>? block) {
      if (block == null || block['h'] != oldHash) return;
      block['h'] = dc.hash;
      final to = serviceMoves[(block['s'] ?? '').toString()];
      if (to != null) block['s'] = to;
    }

    for (final ref in ClassroomHelp.classroomTipRefs(_classroomMap)) {
      move(VerseField.of(_classroomMap, ref));
    }

    for (final bookId in await _bookIdsReferencing(oldHash)) {
      final bookMap = _dirtyBooks[bookId] ?? _decode(await Db().db.bookDao.getContentById(bookId));
      for (final ref in ClassroomHelp.bookFieldRefs) {
        move(VerseField.of(bookMap, ref));
      }
      final downloads = DownloadContent.toList(bookMap['d']) ?? [];
      downloads.removeWhere((e) => e.hash == oldHash);
      if (!downloads.any((e) => e.hash == dc.hash)) downloads.add(dc);
      bookMap['d'] = downloads.map((e) => e.toJson()).toList();
      _dirtyBooks[bookId] = bookMap;
    }
  }

  /// 'q'/'a'/'n' 字段块的 'h' 指着 [hash] 的书。还没写回库的改动（[_dirtyBooks]）以内存为准。
  Future<List<int>> _bookIdsReferencing(String hash) async {
    final ret = <int>[];
    for (final book in await Db().db.bookDao.getAll(classroomId)) {
      final bookMap = _dirtyBooks[book.id!] ?? _decode(book.content);
      if (ClassroomHelp.bookFieldRefs.any((ref) => VerseField.of(bookMap, ref)?['h'] == hash)) {
        ret.add(book.id!);
      }
    }
    return ret;
  }

  /// 退订：订阅本身、它装出来的游戏、以及没人再引用的包，一起清掉。
  Future<void> unsubscribe(GameSubscription sub) async {
    final games = _classroomMap['g'] is List ? _classroomMap['g'] as List<dynamic> : <dynamic>[];
    final before = games.length;
    games.removeWhere((raw) => raw is Map<String, dynamic> && raw['u'] == sub.url);
    _classroomMap['g'] = games;
    _classroomMap['ts'] = _tipServices.where((raw) => !(raw is Map<String, dynamic> && raw['u'] == sub.url)).toList();

    final subs = _subscriptions;
    subs.removeWhere((e) => e.url == sub.url);
    _saveSubscriptions(subs);

    await _dropUnreferencedZip(sub.hash);
    if (games.length != before) {
      await _resetLastGameIndex();
    }
    await _save();
  }

  /// 改订阅地址（服务器换了 IP/域名之类）。
  ///
  /// 订阅以 url 为主键，'g' 里的条目靠 'u' 回指，所以两边一起改；条目的 'i' 不动，存档保得住。
  /// 改完先去新地址拿一次 manifest：拿到了就顺手按它对齐（换了包会更新，不同包的入口会增删）；
  /// 拿不到就问用户还存不存——服务器暂时没开也该能先把地址改了。
  Future<void> changeSubscriptionUrl(GameSubscription sub, String url) async {
    url = url.trim();
    if (url.isEmpty || url == sub.url) return;
    if (_subscriptions.any((e) => e.url == url)) {
      Snackbar.show(I18nKey.gameSubscriptionUrlDuplicated.tr);
      return;
    }

    final manifest = await showOverlay<GameManifest?>(
      () => GameSubscriptionHelp.fetchManifest(url),
      I18nKey.gameCheckUpdate.tr,
    );
    if (manifest == null) {
      MsgBox.yesOrNo(
        title: I18nKey.gameSubscriptionUrl.tr,
        desc: I18nKey.gameSubscriptionUrlUnreachable.tr,
        yes: () async {
          Get.back();
          _moveSubscription(sub.url, url);
          await _save();
        },
      );
      return;
    }

    _moveSubscription(sub.url, url);
    final moved = _subscriptions.firstWhere((e) => e.url == url);
    if (_needsApply(moved, manifest)) {
      final dc = await showOverlay<DownloadContent?>(
        () => GameSubscriptionHelp.download(classroomId, url, manifest),
        I18nKey.labelImporting.tr,
      );
      // 下包失败也照样存新地址，下次检查更新再补。
      if (dc != null) {
        await _applyManifest(url, manifest, dc);
      }
    }
    await _save();
    Snackbar.show(I18nKey.labelSaved.tr);
  }

  /// 只改内存里的 map：订阅的 url 和所有回指它的条目的 'u'。
  void _moveSubscription(String oldUrl, String newUrl) {
    final subs = _subscriptions;
    for (final s in subs) {
      if (s.url != oldUrl) continue;
      s.url = newUrl;
      // 名字是拿 url 兜底的，地址都换了就别留旧地址当名字，下次 apply 会拿 manifest 的。
      if (s.name == oldUrl) s.name = '';
    }
    _saveSubscriptions(subs);
    for (final raw in [..._games, ..._tipServices]) {
      if (raw is Map<String, dynamic> && raw['u'] == oldUrl) {
        raw['u'] = newUrl;
      }
    }
  }

  /// 改订阅的显示名。清空就回落成显示地址，下次更新时拿 manifest 的名字。
  Future<void> renameSubscription(GameSubscription sub, String name) async {
    name = name.trim();
    final subs = _subscriptions;
    final target = subs.firstWhereOrNull((e) => e.url == sub.url);
    if (target == null || target.name == name) return;
    target.name = name;
    _saveSubscriptions(subs);
    await _save();
  }

  /// 名字在课堂内必须唯一（Game 表在 (classroomId, name) 上有唯一索引，
  /// registerRes 又按 name 删多余行，重名会直接冲掉别人）。占了就往后加序号。
  String _uniqueName(String base) {
    if (base.isEmpty) base = 'game';
    final used = <String>{};
    for (final raw in _games) {
      if (raw is Map<String, dynamic>) used.add((raw['n'] ?? '').toString());
    }
    if (!used.contains(base)) return base;
    for (var i = 2; ; i++) {
      final candidate = '$base $i';
      if (!used.contains(candidate)) return candidate;
    }
  }

  /// lastGameIndex 存的是下标不是 id，条目一少后面的整体前移，
  /// 不越界也不报错，只是静默指向了另一个游戏。所以删过条目就归零。
  Future<void> _resetLastGameIndex() async {
    await Db().db.crKvDao.insertOrReplace(CrKv(classroomId, CrK.lastGameIndex, '0'));
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
    if (item.fromSubscription) {
      Snackbar.show(I18nKey.gameOverriddenBySubscription.tr);
    }
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
    if (item.fromSubscription) {
      Snackbar.show(I18nKey.gameOverriddenBySubscription.tr);
    }
  }

  // ---------------------------------------------------------------- 删除

  Future<void> delete(GameItem item) async {
    final games = _classroomMap['g'];
    if (games is! List || item.index >= games.length) return;
    games.removeAt(item.index);
    await _dropUnreferencedZip(item.hash);
    await _resetLastGameIndex();
    await _save();
    if (item.fromSubscription) {
      // manifest 是唯一真相，下次检查更新会把它加回来。
      Snackbar.show(I18nKey.gameOverriddenBySubscription.tr);
    }
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

  /// 没有任何游戏、提示服务、提示字段再引用这个 hash 了，就把它从 'd' 里摘掉，文件也删干净。
  ///
  /// 提示字段要算上：退订以后手工配好的提示还得能用，书本级的字段也从同一个目录拿文件。
  Future<void> _dropUnreferencedZip(String hash) async {
    if (hash.isEmpty) return;
    bool refs(dynamic e) => e is Map<String, dynamic> && e['h'] == hash;
    if (_games.any(refs) || _tipServices.any(refs)) return;
    if (ClassroomHelp.classroomTipRefs(_classroomMap).any((ref) => refs(VerseField.of(_classroomMap, ref)))) return;
    if ((await _bookIdsReferencing(hash)).isNotEmpty) return;
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
