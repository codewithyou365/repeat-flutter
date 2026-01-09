import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/logic/game_server/constant.dart';
import 'package:repeat_flutter/logic/game_server/web_server.dart';

abstract class GameSettings {
  RxBool webOpen = RxBool(false);

  void setWebOpen(bool webOpen) {
    this.webOpen.value = webOpen;
  }

  Future<void> onInit(WebServer web);

  Future<void> onWebOpen();

  Future<void> onWebClose();

  Future<void> onClose();

  List<Widget> build();
}
