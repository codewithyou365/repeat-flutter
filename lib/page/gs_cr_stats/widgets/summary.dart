import 'package:flutter/material.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';

class SummaryLogic {
  int todayCount = 0;
  int totalCount = 0;
  int todayMinutes = 0;
  int totalMinutes = 0;

  SummaryLogic();

  void init(int todayCount, int totalCount, int todayMinutes, int totalMinutes) {
    this.todayCount = todayCount;
    this.totalCount = totalCount;
    this.todayMinutes = todayMinutes;
    this.totalMinutes = totalMinutes;
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
                  I18nKey.labelSummary.tr,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                // IconButton(
                //   onPressed: () {},
                //   icon: const Icon(Icons.arrow_forward_ios),
                // ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        context,
                        I18nKey.labelTodayLearning.tr,
                        "$todayCount",
                        I18nKey.labelVerse.tr,
                        Icons.today,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatItem(
                        context,
                        I18nKey.labelTotalLearning.tr,
                        "$totalCount",
                        I18nKey.labelVerse.tr,
                        Icons.auto_stories,
                        Colors.redAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        context,
                        I18nKey.labelTodayTime.tr,
                        "$todayMinutes",
                        I18nKey.labelMin.tr,
                        Icons.timer,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatItem(
                        context,
                        I18nKey.labelTotalTime.tr,
                        "$totalMinutes",
                        I18nKey.labelMin.tr,
                        Icons.access_time,
                        Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String title,
    String value,
    String unit,
    IconData icon,
    Color iconColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
        ),
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
            Text(
              unit,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }
}
