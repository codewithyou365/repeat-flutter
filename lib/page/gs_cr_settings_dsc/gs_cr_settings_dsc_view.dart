import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/db/dao/schedule_dao.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';

import 'gs_cr_settings_dsc_logic.dart';

class GsCrSettingsDscPage extends StatelessWidget {
  const GsCrSettingsDscPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<GsCrSettingsDscLogic>();
    return Scaffold(
      appBar: AppBar(
        title: Text(I18nKey.settings.tr),
      ),
      body: GetBuilder<GsCrSettingsDscLogic>(
        id: GsCrSettingsDscLogic.elConfigsId,
        builder: (_) => ReorderableListView(
          onReorder: logic.reorder,
          children: logic.state.elConfigs
              .map(
                (item) => ListTile(
                  key: item.key,
                  title: Text(item.config.tr()),
                  onTap: () {
                    logic.setCurrElConfig(item.config);
                    openEditDialog(logic);
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  openEditDialog(GsCrSettingsDscLogic logic) {
    var config = logic.state.currElConfig;
    Get.defaultDialog(
      title: "xx",
      content: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Column(
          children: [
            Row(
              children: [
                Text("是否随机"),
                Spacer(),
                Obx(() {
                  return Switch(
                      value: config.random.value,
                      onChanged: (bool value) {
                        config.random.value = value;
                      });
                }),
              ],
            ),
            Row(
              children: [
                Text("以后"),
                Spacer(),
                Obx(() {
                  return Switch(
                      value: config.extendLevel.value,
                      onChanged: (bool value) {
                        config.extendLevel.value = value;
                      });
                }),
              ],
            ),
            Row(
              children: [
                Text("等级"),
                Spacer(),
                InkWell(
                  onTap: () {
                    openInputNumberDialog("等级", config.level);
                  },
                  child: Obx(() {
                    return Text(config.level.value.toString());
                  }),
                )
              ],
            ),
            Row(
              children: [
                Text("数量"),
                Spacer(),
                InkWell(
                  onTap: () {
                    openInputNumberDialog("数量", config.learnCount);
                  },
                  child: Obx(() {
                    return Text(config.learnCount.value.toString());
                  }),
                )
              ],
            ),
            Row(
              children: [
                Text("每组数量"),
                Spacer(),
                InkWell(
                  onTap: () {
                    openInputNumberDialog("每组数量", config.learnCountPerGroup);
                  },
                  child: Obx(() {
                    return Text(config.learnCountPerGroup.value.toString());
                  }),
                )
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: Text(I18nKey.btnCancel.tr),
          onPressed: () {
            Get.back();
          },
        ),
        TextButton(
          child: Text(I18nKey.btnOk.tr),
          onPressed: () {
            Get.back();
          },
        ),
      ],
    );
  }

  Widget buildInput(RxInt value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: () {
            if (value.value > 0) {
              value.value = value.value - 1;
            }
          },
          child: Text(
            '-',
            style: TextStyle(fontSize: 24.sp),
          ),
        ),
        Obx(
          () => Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0.w),
            child: Text(
              '${value.value}',
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            value.value = value.value + 1;
          },
          child: Text(
            '+',
            style: TextStyle(fontSize: 24.sp),
          ),
        ),
      ],
    );
  }

  openInputNumberDialog(String title, RxInt value) {
    Get.defaultDialog(
      title: title,
      content: buildInput(value),
      actions: [
        TextButton(
          child: Text(I18nKey.btnOk.tr),
          onPressed: () {
            Get.back();
          },
        ),
      ],
    );
  }
}
