import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/common/date.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/verse_today_prg.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';

/// One bar on the chart. [v2] is null for single series charts.
class BarPoint {
  final String label;
  final num v1;
  final num? v2;

  BarPoint(this.label, this.v1, [this.v2]);
}

typedef BarPointLoader = Future<List<BarPoint>> Function(bool monthly);

class TrendChartLogic<T extends GetxController> {
  final T parentLogic;
  final String id;
  final I18nKey title;
  final I18nKey unit;
  final I18nKey label1;
  final I18nKey? label2;

  /// shown in the legend above the chart; falls back to label1/label2
  final I18nKey? legend1;
  final I18nKey? legend2;
  final BarPointLoader loader;

  bool monthly = false;
  List<BarPoint> points = [];
  int selectedIndex = -1;

  static const Color color1 = Colors.green;
  static const Color color2 = Colors.redAccent;

  TrendChartLogic(
    this.parentLogic,
    this.id, {
    required this.title,
    required this.unit,
    required this.label1,
    this.label2,
    this.legend1,
    this.legend2,
    required this.loader,
  });

  Future<void> init() async {
    await load();
  }

  Future<void> load() async {
    points = await loader(monthly);
    selectedIndex = points.length - 1;
    parentLogic.update([id]);
  }

  Future<void> switchRange(bool monthly) async {
    if (this.monthly == monthly) {
      return;
    }
    this.monthly = monthly;
    await load();
  }

  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 18.0, top: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  title.tr,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
              ],
            ),
          ),
          GetBuilder<T>(
            id: id,
            builder: (_) => Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
              child: Column(
                children: [
                  _buildTabs(context),
                  const SizedBox(height: 8),
                  if (label2 != null) _buildLegend(context),
                  SizedBox(height: 180, child: _buildChart(context)),
                  const SizedBox(height: 12),
                  _buildDetail(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildTab(context, I18nKey.labelLastWeek.tr, !monthly, () => switchRange(false)),
        const SizedBox(width: 32),
        _buildTab(context, I18nKey.labelByMonth.tr, monthly, () => switchRange(true)),
      ],
    );
  }

  Widget _buildTab(BuildContext context, String text, bool selected, VoidCallback onTap) {
    final color = selected ? Theme.of(context).colorScheme.primary : Theme.of(context).disabledColor;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color),
            ),
            const SizedBox(height: 4),
            Container(
              height: 2,
              width: 24,
              color: selected ? color : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _buildLegendItem(context, color1, (legend1 ?? label1).tr),
        const SizedBox(width: 16),
        _buildLegendItem(context, color2, (legend2 ?? label2!).tr),
      ],
    );
  }

  Widget _buildLegendItem(BuildContext context, Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(text, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildChart(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox.shrink();
    }
    num maxValue = 0;
    for (var p in points) {
      if (p.v1 > maxValue) maxValue = p.v1;
      if (p.v2 != null && p.v2! > maxValue) maxValue = p.v2!;
    }
    // keep a flat baseline visible when there is no data at all
    final maxY = maxValue == 0 ? 1.0 : maxValue.toDouble() * 1.2;
    return BarChart(
      BarChartData(
        maxY: maxY,
        alignment: BarChartAlignment.spaceAround,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => Colors.transparent,
            getTooltipItem: (group, groupIndex, rod, rodIndex) => null,
          ),
          touchCallback: (event, response) {
            if (!event.isInterestedForInteractions) {
              return;
            }
            var index = response?.spot?.touchedBarGroupIndex;
            if (index == null || index < 0 || index >= points.length) {
              return;
            }
            selectedIndex = index;
            parentLogic.update([id]);
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              getTitlesWidget: (value, meta) {
                var index = value.toInt();
                if (index < 0 || index >= points.length) {
                  return const SizedBox.shrink();
                }
                final selected = index == selectedIndex;
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    points[index].label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: selected ? Theme.of(context).colorScheme.primary : null,
                        ),
                  ),
                );
              },
            ),
          ),
        ),
        gridData: const FlGridData(show: true, drawVerticalLine: true, drawHorizontalLine: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(points.length, (index) {
          final p = points[index];
          final selected = index == selectedIndex;
          return BarChartGroupData(
            x: index,
            barsSpace: 2,
            barRods: [
              _buildRod(p.v1, color1, selected),
              if (p.v2 != null) _buildRod(p.v2!, color2, selected),
            ],
          );
        }),
      ),
    );
  }

  BarChartRodData _buildRod(num value, Color color, bool selected) {
    return BarChartRodData(
      toY: value.toDouble(),
      width: 8,
      color: selected ? color : color.withValues(alpha: 0.5),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
    );
  }

  Widget _buildDetail(BuildContext context) {
    final p = (selectedIndex >= 0 && selectedIndex < points.length) ? points[selectedIndex] : null;
    return Row(
      children: [
        Expanded(child: _buildStatItem(context, label1.tr, "${p?.v1 ?? 0}")),
        if (label2 != null) Expanded(child: _buildStatItem(context, label2!.tr, "${p?.v2 ?? 0}")),
      ],
    );
  }

  Widget _buildStatItem(BuildContext context, String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(width: 8),
            Text(unit.tr, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ],
    );
  }
}

/// The x axis buckets shared by both charts: the last 7 days, or the last 6 months.
class TrendRange {
  final Date start;
  final Date end;
  final String label;

  TrendRange(this.start, this.end, this.label);

  bool contains(Date date) => date.value >= start.value && date.value <= end.value;

  static List<TrendRange> build(bool monthly) {
    final now = DateTime.now();
    final result = <TrendRange>[];
    if (monthly) {
      for (var i = 5; i >= 0; i--) {
        var month = DateTime(now.year, now.month - i, 1);
        var start = Date.fromYmd(month.year, month.month, 1);
        var end = Date.fromYmd(month.year, month.month, 31);
        var label = i == 0 ? I18nKey.labelThisMonth.tr : month.month.toString().padLeft(2, '0');
        result.add(TrendRange(start, end, label));
      }
    } else {
      for (var i = 6; i >= 0; i--) {
        var day = now.subtract(Duration(days: i));
        var date = Date.from(day);
        var label = i == 0 ? I18nKey.labelToday.tr : '${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
        result.add(TrendRange(date, date, label));
      }
    }
    return result;
  }
}

/// Loader for the learning volume chart: learn / review verse count per bucket.
Future<List<BarPoint>> loadVolumePoints(bool monthly) async {
  var ranges = TrendRange.build(monthly);
  var stats = await Db().db.statsDao.getStatsByDateRange(Classroom.curr, ranges.first.start, ranges.last.end);
  var learn = List<int>.filled(ranges.length, 0);
  var review = List<int>.filled(ranges.length, 0);
  for (var e in stats) {
    var index = ranges.indexWhere((r) => r.contains(e.createDate));
    if (index < 0) {
      continue;
    }
    if (e.type == TodayPrgType.learn.index) {
      learn[index]++;
    } else if (e.type == TodayPrgType.review.index) {
      review[index]++;
    }
  }
  return List.generate(ranges.length, (i) => BarPoint(ranges[i].label, learn[i], review[i]));
}

/// Loader for the study duration chart: minutes per bucket.
Future<List<BarPoint>> loadTimePoints(bool monthly) async {
  var ranges = TrendRange.build(monthly);
  var stats = await Db().db.timeStatsDao.getTimeStatsByDateRange(Classroom.curr, ranges.first.start, ranges.last.end);
  var duration = List<int>.filled(ranges.length, 0);
  for (var e in stats) {
    var index = ranges.indexWhere((r) => r.contains(e.createDate));
    if (index < 0) {
      continue;
    }
    duration[index] += e.duration;
  }
  return List.generate(ranges.length, (i) => BarPoint(ranges[i].label, (duration[i] / 60000.0).toInt()));
}
