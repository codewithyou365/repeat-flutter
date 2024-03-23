
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ButtonController extends GetxController {
  RxInt buttonColorIndex = 0.obs;

  final List<Color> buttonColors = [Colors.red, Colors.green, Colors.blue];

  void changeButtonColor() {
    buttonColorIndex.value = (buttonColorIndex.value + 1) % buttonColors.length;
  }
}
