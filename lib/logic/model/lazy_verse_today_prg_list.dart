import 'dart:collection';

import 'package:repeat_flutter/common/date.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/verse_today_prg.dart';
import 'package:repeat_flutter/logic/model/verse_brief.dart';

/// A read-only [List] of [VerseTodayPrg] backed by [verses]: elements are
/// built on first index access and cached, so callers that mutate an element
/// (e.g. SessionCoordinator's time counter) keep getting the same instance.
///
/// 吃的是 [VerseBrief]（不带正文）而不是 VerseShow：这个列表会跟着 RepeatArgs
/// 在整个播放会话里常驻，全局浏览时是一整个课堂的量，多带一份正文就是白占内存。
/// 正文由播放页按当前这一节现取（见 Helper.prefetch）。
class LazyVerseTodayPrgList extends ListBase<VerseTodayPrg> {
  final List<VerseBrief> verses;
  final Map<int, VerseTodayPrg> _cache = {};

  LazyVerseTodayPrgList(this.verses);

  @override
  int get length => verses.length;

  @override
  set length(int newLength) => throw UnsupportedError("LazyVerseTodayPrgList is read-only");

  @override
  VerseTodayPrg operator [](int index) {
    return _cache.putIfAbsent(index, () {
      var verse = verses[index];
      return VerseTodayPrg(
        classroomId: Classroom.curr,
        bookId: verse.bookId,
        chapterId: verse.chapterId,
        verseId: verse.verseId,
        time: 0,
        type: TodayPrgType.justView.index,
        sort: index,
        progress: 0,
        viewTime: DateTime.now(),
        reviewCount: 0,
        reviewCreateDate: Date(0),
        finish: false,
      );
    });
  }

  @override
  void operator []=(int index, VerseTodayPrg value) {
    _cache[index] = value;
  }

  /// Collects book ids without building any [VerseTodayPrg].
  Set<int> get bookIds => verses.map((v) => v.bookId).toSet();
}
