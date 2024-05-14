import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';

import 'gs_settings_data_logic.dart';

class GsSettingsDataPage extends StatelessWidget {
  const GsSettingsDataPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<GsSettingsDataLogic>();
    var state = logic.state;
    return Scaffold(
      appBar: AppBar(
        title: Text(I18nKey.data.tr),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: ListView(
          children: <Widget>[
            ListTile(
              title: Text(I18nKey.btnExport.tr),
              onTap: () => {openDialog(context, logic, I18nKey.btnExport.tr, state.exportUrl, logic.export)},
            ),
            ListTile(
              title: Text(I18nKey.btnImport.tr),
              onTap: () => {openDialog(context, logic, I18nKey.btnImport.tr, state.importUrl, logic.import)},
            ),
          ],
        ),
      ),
    );
  }

  openDialog(BuildContext context, GsSettingsDataLogic logic, String title, String url, DialogCallback callback) {
    final textEditingController = TextEditingController(text: url);
    Get.defaultDialog(
      title: title,
      content: Column(
        mainAxisSize: MainAxisSize.min, // Ensure dialog fits content
        children: [
          TextFormField(
            controller: textEditingController,
            decoration: InputDecoration(
              labelText: I18nKey.labelUrl.tr,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                child: Text(I18nKey.btnCancel.tr),
                onPressed: () {
                  Get.back();
                },
              ),
              TextButton(
                onPressed: () {
                  callback(context, textEditingController.value.text);
                },
                child: Text(I18nKey.btnOk.tr),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
