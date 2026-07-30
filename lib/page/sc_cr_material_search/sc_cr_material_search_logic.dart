import 'dart:async';

import 'package:get/get.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/logic/model/lazy_verse_today_prg_list.dart';
import 'package:repeat_flutter/logic/model/verse_show.dart';
import 'package:repeat_flutter/logic/search/verse_search_index.dart';
import 'package:repeat_flutter/logic/verse_help.dart';
import 'package:repeat_flutter/nav.dart';
import 'package:repeat_flutter/page/repeat/logic/constant.dart';
import 'package:repeat_flutter/page/repeat/repeat_args.dart';

import 'sc_cr_material_search_state.dart';

class ScCrMaterialSearchLogic extends GetxController {
  static const String id = "ScCrMaterialSearchLogic";
  static const Duration debounce = Duration(milliseconds: 300);

  final ScCrMaterialSearchState state = ScCrMaterialSearchState();

  List<VerseShow> _verses = [];
  final Map<int, VerseShow> _verseIdToShow = {};
  final Map<int, String> _lowerContentCache = {};
  Timer? _debounceTimer;

  @override
  void onInit() {
    super.onInit();
    ensureIndex();
  }

  @override
  void onClose() {
    _debounceTimer?.cancel();
    state.searchController.dispose();
    state.searchFocusNode.dispose();
    super.onClose();
  }

  Future<void> ensureIndex({bool force = false}) async {
    await VerseSearchIndex.ensureTable();
    // 要重建时必须绕过 VerseHelp 的内存缓存重新取，否则会拿旧内容建索引
    var rebuild = VerseSearchIndex.ftsAvailable && (force || await VerseSearchIndex.needRebuild(Classroom.curr));
    _verses = await VerseHelp.getVerses(force: rebuild);
    _verseIdToShow.clear();
    _lowerContentCache.clear();
    for (var verse in _verses) {
      _verseIdToShow[verse.verseId] = verse;
    }
    if (!rebuild) {
      // 没有 FTS5 时走内存 contains 搜索，同样不需要建索引
      return;
    }
    state.indexDone.value = 0;
    state.indexTotal.value = _verses.isEmpty ? 1 : _verses.length;
    state.indexing.value = true;
    try {
      await VerseSearchIndex.rebuild(
        Classroom.curr,
        _verses,
        onProgress: (done, total) {
          state.indexDone.value = done;
          state.indexTotal.value = total == 0 ? 1 : total;
        },
      );
    } finally {
      state.indexing.value = false;
    }
    // 重建后把当前关键词重搜一遍
    if (state.searched.value) {
      await doSearch(state.searchController.text);
    }
  }

  Future<void> rebuildManually() {
    return ensureIndex(force: true);
  }

  void onSearchChanged(String input) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounce, () => doSearch(input));
  }

  Future<void> doSearch(String input) async {
    var keyword = input.trim();
    if (keyword.isEmpty) {
      state.searched.value = false;
      state.result.clear();
      return;
    }
    List<VerseShow> hits;
    if (VerseSearchIndex.ftsAvailable) {
      var verseIds = await VerseSearchIndex.search(Classroom.curr, keyword);
      hits = verseIds.map((e) => _verseIdToShow[e]).whereType<VerseShow>().toList();
    } else {
      // 降级路径也要忽略大小写，和 FTS 路径保持一致
      var lower = keyword.toLowerCase();
      hits = _verses.where((e) => _lowerContent(e).contains(lower)).toList();
    }
    state.searched.value = true;
    state.result.value = hits;
  }

  /// 降级搜索用：正文全部转小写后缓存，避免每敲一个字就把整个教室的 JSON 重转一遍。
  String _lowerContent(VerseShow verse) {
    return _lowerContentCache.putIfAbsent(verse.verseId, () => verse.verseContent.toLowerCase());
  }

  Future<void> openVerse(int index) async {
    if (index < 0 || index >= state.result.length) {
      return;
    }
    await Nav.repeat.push(
      arguments: RepeatArgs(
        progresses: LazyVerseTodayPrgList(state.result.toList()),
        startIndex: index,
        repeatFlowType: RepeatType.browse,
        enableShowRecallButtons: false,
        showMode: ShowMode.edit,
      ),
    );
  }
}
