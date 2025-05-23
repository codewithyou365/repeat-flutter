// entity/segment_today_prg.dart

import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/date.dart';

enum TodayPrgType {
  none,
  learn,
  review,
  fullCustom,
}

@Entity(
  indices: [
    Index(value: ['classroomId', 'segmentKeyId', 'type'], unique: true),
    Index(value: ['classroomId', 'sort']),
    Index(value: ['classroomId', 'contentSerial']),
  ],
)
class SegmentTodayPrg {
  @PrimaryKey(autoGenerate: true)
  final int? id;
  final int classroomId;
  final int contentSerial;
  final int lessonKeyId;
  final int segmentKeyId;
  int time;
  int type;
  final int sort;
  int progress;
  DateTime viewTime;
  final int reviewCount;
  final Date reviewCreateDate;
  bool finish;

  SegmentTodayPrg({
    required this.classroomId,
    required this.contentSerial,
    required this.lessonKeyId,
    required this.segmentKeyId,
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

  static SegmentTodayPrg empty() {
    return SegmentTodayPrg(
      classroomId: 0,
      contentSerial: 0,
      lessonKeyId: 0,
      segmentKeyId: 0,
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

  static void setType(List<SegmentTodayPrg> list, TodayPrgType todayPrgType, int index, int limit) {
    if (limit <= 0) {
      for (SegmentTodayPrg sl in list) {
        sl.type = SegmentTodayPrg.toType(todayPrgType, index, 0);
      }
    } else {
      var groupNumber = 0;
      for (int i = 0; i < list.length; i++) {
        var sl = list[i];
        sl.type = SegmentTodayPrg.toType(todayPrgType, index, groupNumber);
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

  static List<SegmentTodayPrg> clone(List<SegmentTodayPrg> list) {
    List<SegmentTodayPrg> clonedList = [];
    for (SegmentTodayPrg segment in list) {
      SegmentTodayPrg clonedSegment = SegmentTodayPrg(
        classroomId: segment.classroomId,
        contentSerial: segment.contentSerial,
        lessonKeyId: segment.lessonKeyId,
        segmentKeyId: segment.segmentKeyId,
        time: segment.time,
        type: segment.type,
        sort: segment.sort,
        progress: segment.progress,
        viewTime: segment.viewTime,
        reviewCount: segment.reviewCount,
        reviewCreateDate: segment.reviewCreateDate,
        finish: segment.finish,
        id: segment.id,
      );
      clonedList.add(clonedSegment);
    }
    return clonedList;
  }

  static List<SegmentTodayPrg> refineWithFinish(List<SegmentTodayPrg> list, bool finish) {
    var wrapper = list.where((segment) {
      return segment.finish == finish;
    });
    return wrapper.toList();
  }

  static int getFinishedCount(List<SegmentTodayPrg> list) {
    var ret = 0;
    for (SegmentTodayPrg segment in list) {
      if (segment.finish) {
        ret++;
      }
    }
    return ret;
  }

  static List<SegmentTodayPrg> getFirstUnfinishedGroup(List<SegmentTodayPrg> list) {
    Map<int, List<SegmentTodayPrg>> grouped = {};
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
