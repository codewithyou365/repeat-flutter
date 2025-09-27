import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/db/dao/schedule_dao.dart';

class RelConfigView {
  int index;
  final Key key;
  final ReviewLearnConfig config;

  RelConfigView(
    this.index,
    this.key,
    this.config,
  );
}

class RelConfigObs {
  var title = "".obs;
  var level = 0.obs;
  var before = 0.obs;
  var from = 20240321.obs;
  var learnCountPerGroup = 2.obs;
}

class GsCrSettingsRelState {
  List<RelConfigView> reviewLearnConfigs = [];

  var currRelConfig = RelConfigObs();
  var currRelConfigIndex = 0;

  GsCrSettingsRelState() {
    ///Initialize variables
  }
}
