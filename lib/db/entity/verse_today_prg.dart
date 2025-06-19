// entity/verse_today_prg.dart

import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/date.dart';

enum TodayPrgType {
  none,
  learn,
  review,
  fullCustom,
  justView,
}

@Entity(
  indices: [
    Index(value: ['verseKeyId', 'type'], unique: true),
    Index(value: ['classroomId', 'sort']),
    Index(value: ['bookId']),
  ],
)
class VerseTodayPrg {
  @PrimaryKey(autoGenerate: true)
  final int? id;
  final int classroomId;
  final int bookId;
  final int chapterKeyId;
  final int verseKeyId;
  int time;
  int type;
  final int sort;
  int progress;
  DateTime viewTime;
  final int reviewCount;
  final Date reviewCreateDate;
  bool finish;

  VerseTodayPrg({
    required this.classroomId,
    required this.bookId,
    required this.chapterKeyId,
    required this.verseKeyId,
    required this.time,
    required this.type,
    required this.sort,
    required this.progress,
    required this.viewTime,
    required this.reviewCount,
    required this.reviewCreateDate,
    required this.finish,
    this.id,
  });

  static VerseTodayPrg empty() {
    return VerseTodayPrg(
      classroomId: 0,
      bookId: 0,
      chapterKeyId: 0,
      verseKeyId: 0,
      time: 0,
      type: TodayPrgType.none.index,
      sort: 0,
      progress: 0,
      viewTime: DateTime.now(),
      reviewCount: 0,
      reviewCreateDate: Date(0),
      finish: false,
    );
  }

  static void setType(List<VerseTodayPrg> list, TodayPrgType todayPrgType, int index, int limit) {
    if (limit <= 0) {
      for (VerseTodayPrg sl in list) {
        sl.type = VerseTodayPrg.toType(todayPrgType, index, 0);
      }
    } else {
      var groupNumber = 0;
      for (int i = 0; i < list.length; i++) {
        var sl = list[i];
        sl.type = VerseTodayPrg.toType(todayPrgType, index, groupNumber);
        if ((i + 1) % limit == 0) {
          groupNumber++;
        }
      }
    }
  }

  static int toType(TodayPrgType todayPrgType, int index, int groupNumber) {
    if (index >= 100000) {
      throw Exception("Level cannot be greater than or equal to 100000");
    }
    if (groupNumber >= 100000) {
      throw Exception("GroupNumber cannot be greater than or equal to 100000");
    }
    return (todayPrgType.index) * 10000000000 + index * 100000 + groupNumber;
  }

  static int getPrgTypeAndIndex(int type) {
    int prgTypeIndex = (type ~/ 10000000000);
    int index = (type % 10000000000) ~/ 100000;
    TodayPrgType todayPrgType = TodayPrgType.values[prgTypeIndex];
    return toPrgTypeAndIndex(todayPrgType, index);
  }

  static int toPrgTypeAndIndex(TodayPrgType type, int index) {
    var prgTypeIndex = type.index;
    return (prgTypeIndex * 100000) + index;
  }

  static TodayPrgType getPrgType(int type) {
    int typeIndex = (type ~/ 10000000000);
    if (typeIndex < 0 || typeIndex >= TodayPrgType.values.length) {
      throw Exception("Invalid type index");
    }
    return TodayPrgType.values[typeIndex];
  }

  static int getIndex(int type) {
    return (type ~/ 100000) % 100000;
  }

  static List<VerseTodayPrg> clone(List<VerseTodayPrg> list) {
    List<VerseTodayPrg> clonedList = [];
    for (VerseTodayPrg verse in list) {
      VerseTodayPrg clonedVerse = VerseTodayPrg(
        classroomId: verse.classroomId,
        bookId: verse.bookId,
        chapterKeyId: verse.chapterKeyId,
        verseKeyId: verse.verseKeyId,
        time: verse.time,
        type: verse.type,
        sort: verse.sort,
        progress: verse.progress,
        viewTime: verse.viewTime,
        reviewCount: verse.reviewCount,
        reviewCreateDate: verse.reviewCreateDate,
        finish: verse.finish,
        id: verse.id,
      );
      clonedList.add(clonedVerse);
    }
    return clonedList;
  }

  static List<VerseTodayPrg> refineWithFinish(List<VerseTodayPrg> list, bool finish) {
    var wrapper = list.where((verse) {
      return verse.finish == finish;
    });
    return wrapper.toList();
  }

  static int getFinishedCount(List<VerseTodayPrg> list) {
    var ret = 0;
    for (VerseTodayPrg verse in list) {
      if (verse.finish) {
        ret++;
      }
    }
    return ret;
  }

  static List<VerseTodayPrg> getFirstUnfinishedGroup(List<VerseTodayPrg> list) {
    Map<int, List<VerseTodayPrg>> grouped = {};
    for (var item in list) {
      if (!grouped.containsKey(item.type)) {
        grouped[item.type] = [];
      }
      grouped[item.type]!.add(item);
    }

    List<int> types = [];
    for (var item in list) {
      if (!types.contains(item.type)) {
        types.add(item.type);
      }
    }

    for (var type in types) {
      if (grouped[type] == null) {
        continue;
      }
      var group = grouped[type]!;
      if (group.any((item) => !item.finish)) {
        return group;
      }
    }
    return [];
  }
}
