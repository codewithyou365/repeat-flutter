import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

Future<T> showTransparentOverlay<T>(Future<T> Function() asyncFunction) async {
  return Get.showOverlay(
    asyncFunction: asyncFunction,
    opacity: 0,
    loadingWidget: Container(),
  );
}

Future<T> showOverlay<T>(Future<T> Function() asyncFunction, String title) async {
  return Get.showOverlay(
    asyncFunction: asyncFunction,
    loadingWidget: Center(
      child: Container(
        constraints: BoxConstraints(minWidth: 160.w, maxWidth: 240.w),
        decoration: BoxDecoration(
          color: Theme.of(Get.context!).colorScheme.onInverseSurface,
          borderRadius: BorderRadius.circular(12.w),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 50.w, vertical: 40.w),
              child: const CircularProgressIndicator(),
            ),
            Padding(
              padding: EdgeInsets.only(left: 16.w, right: 16.w, bottom: 20.w),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(Get.context!).colorScheme.primary,
                  fontSize: 20.sp,
                  decoration: TextDecoration.none,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
