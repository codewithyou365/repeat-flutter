// entity/segment_today_prg.dart

import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/date.dart';

enum TodayPrgType {
  learn,
  review,
}

@Entity(
  indices: [
    Index(value: ['segmentKeyId', 'type'], unique: true),
    Index(value: ['sort']),
  ],
)
class SegmentTodayPrg {
  @PrimaryKey(autoGenerate: true)
  final int? id;
  final int segmentKeyId;
  int type;
  final int sort;
  int progress;
  DateTime viewTime;
  final int reviewCount;
  final Date reviewCreateDate;
  bool finish;

  SegmentTodayPrg(
    this.segmentKeyId,
    this.type,
    this.sort,
    this.progress,
    this.viewTime,
    this.reviewCount,
    this.reviewCreateDate,
    this.finish, {
    this.id,
  });

  static void setType(List<SegmentTodayPrg> list, TodayPrgType todayPrgType, int level, int limit) {
    if (limit <= 0) {
      for (SegmentTodayPrg sl in list) {
        sl.type = SegmentTodayPrg.toType(todayPrgType, level, 0);
      }
    } else {
      var groupNumber = 0;
      for (int i = 0; i < list.length; i++) {
        var sl = list[i];
        sl.type = SegmentTodayPrg.toType(todayPrgType, level, groupNumber);
        if ((i + 1) % limit == 0) {
          groupNumber++;
        }
      }
    }
  }

  static int toType(TodayPrgType todayPrgType, int level, int groupNumber) {
    if (level >= 100000) {
      throw Exception("Level cannot be greater than or equal to 100000");
    }
    if (groupNumber >= 100000) {
      throw Exception("GroupNumber cannot be greater than or equal to 100000");
    }
    return (todayPrgType.index + 1) * 10000000000 + level * 100000 + groupNumber;
  }

  static List<SegmentTodayPrg> clone(List<SegmentTodayPrg> list) {
    List<SegmentTodayPrg> clonedList = [];
    for (SegmentTodayPrg segment in list) {
      SegmentTodayPrg clonedSegment = SegmentTodayPrg(
        segment.segmentKeyId,
        segment.type,
        segment.sort,
        segment.progress,
        segment.viewTime,
        segment.reviewCount,
        segment.reviewCreateDate,
        segment.finish,
      );
      clonedList.add(clonedSegment);
    }
    return clonedList;
  }

  static List<SegmentTodayPrg> refineFinished(List<SegmentTodayPrg> list) {
    var wrapper = list.where((segment) {
      return segment.finish == false;
    });
    return wrapper.toList();
  }

  static List<SegmentTodayPrg> refine(List<SegmentTodayPrg> list, int levelAndGroupNumber, bool withoutFinish) {
    var wrapper = list.where((segment) {
      if (withoutFinish) {
        return segment.type % 10000000000 == levelAndGroupNumber;
      } else {
        return segment.type % 10000000000 == levelAndGroupNumber && segment.finish == false;
      }
    });
    return wrapper.toList();
  }

  static List<int> getLevelAndGroupNumber(List<SegmentTodayPrg> list) {
    List<int> types = [];
    for (SegmentTodayPrg segment in list) {
      var type = segment.type % 10000000000;
      if (!types.contains(type)) {
        types.add(type);
      }
    }
    return types.toList();
  }

  static int getUnfinishedCount(List<SegmentTodayPrg> list) {
    var ret = 0;
    for (SegmentTodayPrg segment in list) {
      if (segment.finish == false) {
        ret++;
      }
    }
    return ret;
  }
}
