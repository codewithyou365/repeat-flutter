import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Sheet {
  static const double paddingHorizontal = 10;

  static Future<T?> showBottomSheet<T>(BuildContext context, Widget w, {double? rate, GestureTapCallback? onTapBlack}) {
    final Size screenSize = MediaQuery.of(context).size;
    rate ??= 2 / 3;

    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min, // Prevents unnecessary expansion
          children: [
            GestureDetector(
              onTap: () {
                if (onTapBlack != null) {
                  onTapBlack();
                } else {
                  Get.back();
                }
              },
              child: Container(
                width: screenSize.width,
                height: screenSize.height * (1 - rate!),
                color: Colors.transparent,
              ),
            ),
            Container(
              width: screenSize.width,
              height: screenSize.height * rate,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: paddingHorizontal, vertical: 20.0),
                child: w,
              ),
            ),
          ],
        );
      },
    );
  }
}
