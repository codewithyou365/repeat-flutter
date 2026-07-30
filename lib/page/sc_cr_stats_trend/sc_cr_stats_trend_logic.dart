import 'package:get/get.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';

import 'widgets/trend_chart.dart';

class ScCrStatsTrendLogic extends GetxController {
  static const String id = "ScCrStatsTrendLogic";
  late TrendChartLogic<ScCrStatsTrendLogic> volumeChartLogic = TrendChartLogic<ScCrStatsTrendLogic>(
    this,
    "VolumeChartLogic",
    title: I18nKey.labelLearningVolume,
    unit: I18nKey.labelVerse,
    label1: I18nKey.labelDayLearning,
    label2: I18nKey.labelDayReview,
    legend1: I18nKey.labelLegendLearn,
    legend2: I18nKey.labelLegendReview,
    loader: loadVolumePoints,
  );
  late TrendChartLogic<ScCrStatsTrendLogic> timeChartLogic = TrendChartLogic<ScCrStatsTrendLogic>(
    this,
    "TimeChartLogic",
    title: I18nKey.labelStudyDuration,
    unit: I18nKey.labelMin,
    label1: I18nKey.labelDayTime,
    loader: loadTimePoints,
  );

  @override
  Future<void> onInit() async {
    super.onInit();
    await init();
  }

  Future<void> init() async {
    await volumeChartLogic.init();
    await timeChartLogic.init();
    update([ScCrStatsTrendLogic.id]);
  }
}
