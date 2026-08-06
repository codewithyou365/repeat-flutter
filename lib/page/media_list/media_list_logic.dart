import 'dart:convert';
import 'dart:io';

import 'package:get/get.dart';
import 'package:repeat_flutter/common/path.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/logic/model/book_content.dart';

import 'media_item.dart';
import 'media_list_state.dart';

enum _RowKind { book, chapter, verse }

class _RowRef {
  final _RowKind kind;
  final int rowId;
  String content;

  _RowRef(this.kind, this.rowId, this.content);
}

class MediaListLogic extends GetxController {
  static const String id = "MediaListLogic";
  final MediaListState state = MediaListState();

  // Write-back bookkeeping: full JSON of each source row, and which rows a
  // given media hash appears in (across books), so a rename can persist to
  // every `d[].n` sharing that hash.
  final Map<String, _RowRef> _rows = {};
  final Map<String, Set<String>> _hashToRowKeys = {};

  // 全量媒体（已排序），state.items 是按当前过滤条件从这里筛出来的视图。
  final List<MediaItem> _all = [];

  @override
  void onInit() {
    super.onInit();
    load();
  }

  static MediaKind kindOf(String extension) {
    final ext = extension.toLowerCase();
    const images = {'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'};
    const videos = {'mp4', 'mov'};
    const audios = {'mp3', 'wav', 'm4a', 'aac', 'ogg', 'flac'};
    if (images.contains(ext)) return MediaKind.image;
    if (videos.contains(ext)) return MediaKind.video;
    if (audios.contains(ext)) return MediaKind.audio;
    return MediaKind.unknown;
  }

  Future<void> load() async {
    state.loading.value = true;
    _rows.clear();
    _hashToRowKeys.clear();
    _all.clear();

    final rootPath = await DocPath.getContentPath();
    final Map<String, MediaItem> byKey = {};
    final Map<String, int> sortByKey = {};

    void handleRow(_RowKind kind, int rowId, int bookId, int bookSort, int chapterIndex, int verseIndex, String content) {
      Map<String, dynamic> map;
      try {
        map = jsonDecode(content) as Map<String, dynamic>;
      } catch (_) {
        return;
      }
      // 字段专属媒体只在字段块里存 hash，文件对象一律在某一层的 d[] 里，所以这里只看 d[]。
      final ds = DownloadContent.toList(map['d']) ?? [];
      if (ds.isEmpty) {
        return;
      }
      final rowKey = '${kind.name}:$rowId';
      var rowUsed = false;
      for (final d in ds) {
        if (d.hash.length < 3) {
          continue;
        }
        (_hashToRowKeys[d.hash] ??= <String>{}).add(rowKey);
        rowUsed = true;

        final kind = kindOf(d.extension);
        if (kind == MediaKind.unknown) {
          // Non-media resources (e.g. zip bundles) are not shown in the media list.
          continue;
        }

        final itemKey = '$bookId:${d.hash}';
        final named = d.n != null && d.n!.isNotEmpty;
        if (byKey.containsKey(itemKey)) {
          // Prefer an explicit custom name if a later row provides one.
          if (named) {
            byKey[itemKey]!.displayName = d.n!;
            byKey[itemKey]!.named = true;
          }
          continue;
        }
        final localPath = rootPath.joinPath(DocPath.getRelativePath(bookId)).joinPath(d.path);
        byKey[itemKey] = MediaItem(
          hash: d.hash,
          url: d.url,
          bookId: bookId,
          localPath: localPath,
          kind: kind,
          displayName: named ? d.n! : d.name,
          named: named,
          exists: false,
        );
        sortByKey[itemKey] = bookSort * 10000000000 + chapterIndex * 100000 + verseIndex;
      }
      if (rowUsed) {
        _rows[rowKey] = _RowRef(kind, rowId, content);
      }
    }

    final books = await Db().db.bookDao.getByEnable(Classroom.curr, true);
    for (final b in books) {
      if (b.id == null) continue;
      handleRow(_RowKind.book, b.id!, b.id!, b.sort, -1, -1, b.content);
    }
    final chapters = await Db().db.chapterDao.getAllChapter(Classroom.curr);
    for (final c in chapters) {
      handleRow(_RowKind.chapter, c.chapterId, c.bookId, c.bookSort, c.chapterIndex, -1, c.chapterContent);
    }
    final verses = await Db().db.scheduleDao.getAllVerse(Classroom.curr);
    for (final v in verses) {
      handleRow(_RowKind.verse, v.verseId, v.bookId, v.bookSort, v.chapterIndex, v.verseIndex, v.verseContent);
    }

    final items = byKey.entries.toList();
    items.sort((a, b) => (sortByKey[a.key] ?? 0).compareTo(sortByKey[b.key] ?? 0));

    for (final e in items) {
      e.value.exists = await File(e.value.localPath).exists();
      _all.add(e.value);
    }

    _applyFilter();
    state.loading.value = false;
    update([id]);
  }

  /// 默认只列出有名字（d[].n 非空）的媒体，没命名的多是内部资源；
  /// 关掉开关后连未命名的一起显示。
  void _applyFilter() {
    if (state.onlyNamed.value) {
      state.items.assignAll(_all.where((e) => e.named));
    } else {
      state.items.assignAll(_all);
    }
  }

  void toggleOnlyNamed() {
    state.onlyNamed.value = !state.onlyNamed.value;
    _applyFilter();
    update([id]);
  }

  Future<void> rename(MediaItem item, String newName) async {
    newName = newName.trim();
    if (newName.isEmpty) {
      return;
    }
    final rowKeys = _hashToRowKeys[item.hash];
    if (rowKeys == null) {
      return;
    }
    for (final rowKey in rowKeys) {
      final row = _rows[rowKey];
      if (row == null) continue;
      Map<String, dynamic> map;
      try {
        map = jsonDecode(row.content) as Map<String, dynamic>;
      } catch (_) {
        continue;
      }
      var changed = false;
      final ds = DownloadContent.toList(map['d']);
      if (ds != null) {
        for (final d in ds) {
          if (d.hash == item.hash) {
            d.n = newName;
            changed = true;
          }
        }
        if (changed) {
          map['d'] = ds.map((e) => e.toJson()).toList();
        }
      }
      if (!changed) continue;
      final newContent = jsonEncode(map);
      row.content = newContent;
      switch (row.kind) {
        case _RowKind.book:
          await Db().db.bookDao.updateBookContent(row.rowId, newContent);
          break;
        case _RowKind.chapter:
          await Db().db.chapterDao.updateChapterContent(row.rowId, newContent);
          break;
        case _RowKind.verse:
          await Db().db.verseDao.updateVerseContent(row.rowId, newContent);
          break;
      }
    }
    for (final it in _all) {
      if (it.hash == item.hash) {
        it.displayName = newName;
        it.named = true;
      }
    }
    state.items.refresh();
    update([id]);
  }
}
