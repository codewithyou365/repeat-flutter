import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:repeat_flutter/db/dao/schedule_dao.dart';

class ElConfigView {
  final Key key;
  final ElConfig config;

  ElConfigView(
    this.key,
    this.config,
  );
}

class GsCrSettingsState {
  List<ElConfigView> elConfigs = [];

  GsCrSettingsState() {
    ///Initialize variables
  }
}
