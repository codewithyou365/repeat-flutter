import 'package:flutter/material.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/model/segment_overall_prg_with_key.dart';
import 'package:repeat_flutter/nav.dart';

class ProgressLogic {
  double progress = 0;
  int learnedCount = 0;
  int totalCount = 0;

  ProgressLogic();

  void init(List<SegmentOverallPrgWithKey> progressRawData) {
    learnedCount = progressRawData.where((e) => e.progress != 0).length;
    totalCount = progressRawData.length;
    progress = learnedCount / (totalCount == 0 ? 1 : totalCount);
  }

  Widget build(BuildContext context) {
    double viewProgress = progress;
    double minViewValue = 0.03;
    if (progress < minViewValue) {
      viewProgress = minViewValue;
    }
    if (progress != 1 && progress > 1 - minViewValue) {
      viewProgress = 1 - minViewValue;
    }
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 18.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  I18nKey.labelProgress.tr,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    Nav.gsCrStatsLearn.push();
                  },
                  icon: const Icon(Icons.arrow_forward_ios),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LinearProgressIndicator(
                    value: viewProgress,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    color: Colors.green,
                    minHeight: 10,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      I18nKey.labelLearned.trArgs([learnedCount.toString()]),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const Spacer(),
                    Text(
                      I18nKey.labelTotal.trArgs([totalCount.toString()]),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
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
}
