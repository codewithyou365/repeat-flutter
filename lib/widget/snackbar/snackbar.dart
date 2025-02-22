import 'package:get/get.dart';

import 'package:flutter/material.dart';

class Snackbar {
  static void show(String content) {
    var context = Get.context;
    if (context == null) {
      return;
    }
    double marginWidth = 40;
    if (content.length < 10) {
      marginWidth = 80;
    }
    var isDarkMode = Theme.of(context).brightness == Brightness.dark;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Center(
          child: Text(
            content,
            style: TextStyle(
              fontSize: 18,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.only(
          left: marginWidth,
          right: marginWidth,
          bottom: MediaQuery.of(context).size.height / 2 - 28,
        ),
        elevation: 10000000,
      ),
    );
  }
}
