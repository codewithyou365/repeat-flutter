import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/db/dao/schedule_dao.dart';

class ElConfigView {
  final Key key;
  final ElConfig config;

  ElConfigView(
    this.key,
    this.config,
  );
}

class ElConfigObs {
  var random = false.obs;
  var extendLevel = false.obs;
  var level = 0.obs;
  var learnCount = 2.obs;
  var learnCountPerGroup = 2.obs;

}

class GsCrSettingsState {
  List<ElConfigView> elConfigs = [];

  var currElConfig = ElConfigObs();

  GsCrSettingsState() {
    ///Initialize variables
  }
}
