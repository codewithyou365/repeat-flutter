import 'package:flutter/material.dart';
import 'package:repeat_flutter/logic/game_server/constant.dart';
import 'package:repeat_flutter/logic/game_server/web_server.dart';

abstract class GameSettings {
  Future<void> onInit(WebServer web);

  Future<void> onClose();

  List<Widget> build();
}
