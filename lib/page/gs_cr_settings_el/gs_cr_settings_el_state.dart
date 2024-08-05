import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/db/dao/schedule_dao.dart';

class ElConfigView {
  int index;
  final Key key;
  final ElConfig config;

  ElConfigView(
    this.index,
    this.key,
    this.config,
  );
}

class ElConfigObs {
  var title = "".obs;
  var random = false.obs;
  var extend = false.obs;
  var level = 0.obs;
  var learnCount = 2.obs;
  var learnCountPerGroup = 2.obs;
}

class GsCrSettingsState {
  List<ElConfigView> elConfigs = [];

  var currElConfig = ElConfigObs();
  var currElConfigIndex = 0;

  GsCrSettingsState() {
    ///Initialize variables
  }
}
