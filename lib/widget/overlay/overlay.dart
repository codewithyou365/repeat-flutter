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
        height: 160.w,
        width: 160.w,
        decoration: BoxDecoration(
          color: Theme.of(Get.context!).colorScheme.onInverseSurface,
          borderRadius: BorderRadius.circular(12.w),
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 50.w, vertical: 40.w),
              child: const CircularProgressIndicator(),
            ),
            Text(
              title,
              style: TextStyle(
                color: Theme.of(Get.context!).colorScheme.primary,
                fontSize: 20.sp,
                decoration: TextDecoration.none,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
