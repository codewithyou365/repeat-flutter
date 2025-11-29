import 'package:flutter/material.dart';
import 'package:repeat_flutter/logic/game_server/constant.dart';

abstract class GameSettings {
  Future<void> onInit();

  Future<void> onClose();

  List<Widget> build();
}
