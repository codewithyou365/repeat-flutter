import 'dart:collection';

import 'package:repeat_flutter/common/date.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/verse_today_prg.dart';
import 'package:repeat_flutter/logic/model/verse_show.dart';

/// A read-only [List] of [VerseTodayPrg] backed by [verseShows]: elements are
/// built on first index access and cached, so callers that mutate an element
/// (e.g. SessionCoordinator's time counter) keep getting the same instance.
class LazyVerseTodayPrgList extends ListBase<VerseTodayPrg> {
  final List<VerseShow> verseShows;
  final Map<int, VerseTodayPrg> _cache = {};

  LazyVerseTodayPrgList(this.verseShows);

  @override
  int get length => verseShows.length;

  @override
  set length(int newLength) => throw UnsupportedError("LazyVerseTodayPrgList is read-only");

  @override
  VerseTodayPrg operator [](int index) {
    return _cache.putIfAbsent(index, () {
      var verseShow = verseShows[index];
      return VerseTodayPrg(
        classroomId: Classroom.curr,
        bookId: verseShow.bookId,
        chapterId: verseShow.chapterId,
        verseId: verseShow.verseId,
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
  Set<int> get bookIds => verseShows.map((v) => v.bookId).toSet();
}
