import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/common/extension.dart';
import 'package:repeat_flutter/nav.dart';

import 'db/database.dart';
import 'db/entity/settings.dart';
import 'i18n/i18n_translations.dart';

void main() async {
  var logic = Get.put<MyAppLogic>(MyAppLogic());
  WidgetsFlutterBinding.ensureInitialized();

  var db = await Db().init();
  var settings = await db.settingsDao.one();
  if (settings == null) {
    settings = Settings(1, ThemeMode.light.name, I18nLocal.en.name);
    db.settingsDao.insertSettings(settings);
  }

  logic.themeMode.value = ThemeModeFromString.c(settings.themeMode);
  logic.i18nLocal.value = I18nLocalFromString.c(settings.i18n);
  runApp(MyApp());
}

class MyAppLogic extends GetxController {
  final themeMode = ThemeMode.light.obs;
  final i18nLocal = I18nLocal.en.obs;
}

class MyApp extends StatelessWidget {
  MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var logic = Get.find<MyAppLogic>();

    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) {
        return Obx(() {
          return GetMaterialApp(
            translations: I18nTranslations(),
            locale: logic.i18nLocal.value.locale,
            initialRoute: Nav.initialRoute,
            getPages: Nav.getPages,
            themeMode: logic.themeMode.value,
            theme: logic.themeMode.value == ThemeMode.light ? ThemeData.light() : ThemeData.dark(),
            debugShowCheckedModeBanner: false,
            title: 'First Method',
            home: child,
          );
        });
      },
    );
  }
}
