import 'package:flutter/material.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/event_bus.dart';
import 'package:repeat_flutter/logic/model/verse_show.dart';
import 'package:repeat_flutter/logic/verse_help.dart';

class ProgressLogic {
  double progress = 0;
  int learnedCount = 0;
  int totalCount = 0;

  static final SubList changeSub = [];

  ProgressLogic();

  static void onEvent() {
    changeSub.on([EventTopic.importBook, EventTopic.reimportBook, EventTopic.deleteBook, EventTopic.deleteChapter, EventTopic.addVerse, EventTopic.deleteVerse, EventTopic.updateVerseProgress], (_) {
      Db().db.crKvDao.deleteByKey(Classroom.curr, CrK.lastCache4ProgressStats);
    });
  }

  static void offEvent() {
    changeSub.off();
  }

  Future<void> init() async {
    learnedCount = 0;
    totalCount = 0;

    var cache = await Db().db.crKvDao.getString(Classroom.curr, CrK.lastCache4ProgressStats);
    if (cache != null) {
      var values = cache.split(",");
      learnedCount = int.parse(values[0]);
      totalCount = int.parse(values[1]);
    } else {
      List<VerseShow> progressRawData = await VerseHelp.getVerses();
      learnedCount = progressRawData.where((e) => e.progress != 0).length;
      totalCount = progressRawData.length;
      await Db().db.crKvDao.insertOrReplace(CrKv(Classroom.curr, CrK.lastCache4ProgressStats, '$learnedCount,$totalCount'));
    }
    progress = learnedCount / (totalCount == 0 ? 1 : totalCount);
  }

  Widget build(BuildContext context) {
    double viewProgress = progress;
    double minViewValue = 0.03;
    if (progress == 0.0) {
      viewProgress = progress;
    } else if (progress < minViewValue) {
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
            padding: const EdgeInsets.only(left: 18.0, top: 8),
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
                // IconButton(
                //   onPressed: () {
                //     Nav.gsCrStatsLearn.push();
                //   },
                //   icon: const Icon(Icons.arrow_forward_ios),
                // ),
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
