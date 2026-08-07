import 'dart:async';

import 'package:get/get.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/query/show_window.dart';
import 'package:repeat_flutter/db/query/verse_query.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/logic/book_brief_help.dart';
import 'package:repeat_flutter/logic/model/lazy_verse_today_prg_list.dart';
import 'package:repeat_flutter/logic/model/verse_show.dart';
import 'package:repeat_flutter/logic/search/verse_search_index.dart';
import 'package:repeat_flutter/nav.dart';
import 'package:repeat_flutter/page/repeat/logic/constant.dart';
import 'package:repeat_flutter/page/repeat/repeat_args.dart';

import 'sc_cr_material_search_state.dart';

class ScCrMaterialSearchLogic extends GetxController {
  static const String id = "ScCrMaterialSearchLogic";
  static const Duration debounce = Duration(milliseconds: 300);

  final ScCrMaterialSearchState state = ScCrMaterialSearchState();

  Timer? _debounceTimer;

  /// bookId -> 书名，只给列表标题显示用。页面关掉就跟着释放。
  Map<int, String> bookNames = {};

  /// 结果的正文窗口：只保当前可视区附近那几十条，滚出去就淘汰。
  late final ShowWindow<VerseShow> window = ShowWindow<VerseShow>(
    fetch: VerseQuery.byIds,
    idOf: (row) => row.verseId,
    onLoaded: () => update([ScCrMaterialSearchLogic.id]),
  );

  @override
  void onInit() {
    super.onInit();
    loadBookNames();
    ensureIndex();
  }

  @override
  void onClose() {
    _debounceTimer?.cancel();
    state.searchController.dispose();
    state.searchFocusNode.dispose();
    super.onClose();
  }

  Future<void> loadBookNames() async {
    bookNames = await BookBriefHelp.loadNameMap(Classroom.curr);
    update([ScCrMaterialSearchLogic.id]);
  }

  Future<void> ensureIndex({bool force = false}) async {
    await VerseSearchIndex.ensureTable();
    var rebuild = VerseSearchIndex.ftsAvailable && (force || await VerseSearchIndex.needRebuild(Classroom.curr));
    if (!rebuild) {
      // 没有 FTS5 时走 SQL LIKE 搜索，不需要建索引
      return;
    }
    state.indexDone.value = 0;
    state.indexTotal.value = 1;
    state.indexing.value = true;
    try {
      // rebuild 自己分批从库里取，不再需要外面先把全量句子拉进内存
      await VerseSearchIndex.rebuild(
        Classroom.curr,
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
      state.resultIds.clear();
      window.reset([]);
      return;
    }
    List<int> hitIds;
    if (VerseSearchIndex.ftsAvailable) {
      hitIds = await VerseSearchIndex.search(Classroom.curr, keyword);
    } else {
      // 降级走 SQL LIKE：SQLite 的 LIKE 对 ASCII 默认就不区分大小写，
      // 和 FTS 路径的表现一致，也不用再把全课堂正文转一份小写副本留在内存里
      hitIds = await VerseQuery.searchIdsByLike(Classroom.curr, keyword);
    }
    state.searched.value = true;
    state.resultIds.value = hitIds;
    window.reset(hitIds);
    update([ScCrMaterialSearchLogic.id]);
  }

  /// 列表第 [index] 行的正文。没在窗口里就先返回 null，补齐后界面会自己重画。
  VerseShow? verseAt(int index) => window.at(index);

  Future<void> openVerse(int index) async {
    if (index < 0 || index >= state.resultIds.length) {
      return;
    }
    await Nav.repeat.push(
      arguments: RepeatArgs(
        progresses: LazyVerseTodayPrgList(await VerseQuery.briefByIds(state.resultIds.toList())),
        startIndex: index,
        repeatFlowType: RepeatType.browse,
        enableShowRecallButtons: false,
        showMode: ShowMode.edit,
      ),
    );
  }
}
