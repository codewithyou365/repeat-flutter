import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/common/extension.dart';
import 'package:repeat_flutter/logic/repeat_doc_help.dart';
import 'package:repeat_flutter/nav.dart';

import 'db/database.dart';
import 'db/entity/kv.dart';
import 'i18n/i18n_translations.dart';

void main() async {
  var logic = Get.put<MyAppLogic>(MyAppLogic());
  WidgetsFlutterBinding.ensureInitialized();
  RepeatDocHelp.clear();
  var db = await Db().init();
  var settings = await db.kvDao.find([K.settingsI18n, K.settingsTheme]);
  if (settings.isEmpty) {
    settings = [
      Kv(K.settingsI18n, I18nLocal.en.name),
      Kv(K.settingsTheme, ThemeMode.light.name),
    ];
    db.kvDao.insertKvs(settings);
  }
  Map<K, String> settingsMap = {for (var kv in settings) kv.k: kv.value};
  logic.themeMode.value = ThemeModeFromString.c(settingsMap[K.settingsTheme]!);
  logic.i18nLocal.value = I18nLocalFromString.c(settingsMap[K.settingsI18n]!);
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
    var locale = logic.i18nLocal.value.locale;
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) {
        return Obx(() {
          return GetMaterialApp(
            translations: I18nTranslations(),
            locale: locale,
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
