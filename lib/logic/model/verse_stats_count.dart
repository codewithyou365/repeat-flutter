import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/date.dart';

/// VerseStats 按「天 + 类型」聚合后的计数。
///
/// 日历/趋势图只要每天各类型多少条，别把整段区间的 VerseStats 原始行拉进内存再用
/// Dart 去数 —— 一个重度用户三个月就是上万行，反序列化直接卡住 UI 线程。
/// 让 SQL 去 GROUP BY，结果最多几百行。
@Entity(tableName: "", primaryKeys: ['createDate', 'type'])
class VerseStatsCount {
  final Date createDate;
  final int type;
  final int cnt;

  VerseStatsCount({
    required this.createDate,
    required this.type,
    required this.cnt,
  });
}
