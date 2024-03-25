import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/nav.dart';

import 'i18n/i18n_translations.dart';

void main() => runApp(MyApp());

class MyAppLogic extends GetxController {
  final themeMode = ThemeMode.light.obs;
}

class MyApp extends StatelessWidget {
  MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var logic = Get.put<MyAppLogic>(MyAppLogic());

    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) {
        return GetMaterialApp(
          translations: I18nTranslations(),
          locale: I18nLocal.en.locale,
          initialRoute: Nav.initialRoute,
          getPages: Nav.getPages,
          themeMode: logic.themeMode.value,
          theme: logic.themeMode.value == ThemeMode.light ? ThemeData.light() : ThemeData.dark(),
          debugShowCheckedModeBanner: false,
          title: 'First Method',
          home: child,
        );
      },
    );
  }
}
