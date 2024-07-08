import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/db/dao/schedule_dao.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';

import 'gs_cr_settings_el_logic.dart';

class GsCrSettingsElPage extends StatelessWidget {
  const GsCrSettingsElPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<GsCrSettingsElLogic>();
    return Scaffold(
      appBar: AppBar(
        title: Text(I18nKey.labelConfigSettingsForEl.tr),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            tryOpenSaveConfirmDialog(logic);
          },
        ),
      ),
      body: GetBuilder<GsCrSettingsElLogic>(
        id: GsCrSettingsElLogic.elConfigsId,
        builder: (_) => ReorderableListView(
          onReorder: logic.reorder,
          children: logic.state.elConfigs
              .map(
                (item) => ListTile(
                  key: item.key,
                  title: Text(item.config.tr()),
                  onTap: () {
                    logic.setCurrElConfig(item);
                    openEditDialog(logic);
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  openEditDialog(GsCrSettingsElLogic logic) {
    var config = logic.state.currElConfig;
    Get.defaultDialog(
      title: I18nKey.settings.tr,
      content: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Column(
          children: [
            buildSwitch("是否随机", config.random),
            buildSwitch("以后", config.extendLevel),
            buildNumberItem("等级", config.level),
            buildNumberItem("数量", config.learnCount),
            buildNumberItem("每组数量", config.learnCountPerGroup),
            const Divider(),
            Obx(() {
              return Text(ElConfig(
                config.random.value,
                config.extendLevel.value,
                config.level.value,
                config.learnCount.value,
                config.learnCountPerGroup.value,
              ).tr());
            }),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: Text(I18nKey.btnCopy.tr),
          onPressed: () {
            logic.copyItem();
            Get.back();
          },
        ),
        TextButton(
          child: Text(I18nKey.btnDelete.tr),
          onPressed: () {
            logic.deleteItem();
            Get.back();
          },
        ),
        TextButton(
          child: Text(I18nKey.btnOk.tr),
          onPressed: () {
            logic.updateItem();
            Get.back();
          },
        ),
      ],
    );
  }

  Widget buildSwitch(String title, RxBool ele) {
    return Row(
      children: [
        Text(title),
        const Spacer(),
        Obx(() {
          return Switch(
              value: ele.value,
              onChanged: (bool value) {
                ele.value = value;
              });
        }),
      ],
    );
  }

  Widget buildNumberItem(String title, RxInt value) {
    return Row(
      children: [
        Text(title),
        const Spacer(),
        InkWell(
          onTap: () {
            openInputNumberDialog(title, value);
          },
          child: Obx(() {
            return Text(value.value.toString(), style: TextStyle(fontSize: 24.sp));
          }),
        )
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

  tryOpenSaveConfirmDialog(GsCrSettingsElLogic logic) {
    var same = logic.isSame();
    if (same) {
      Get.back();
      return;
    }
    Get.defaultDialog(
      title: I18nKey.labelSavingConfirm.tr,
      content: Text(I18nKey.labelConfigChange.tr),
      actions: [
        TextButton(
          child: Text(I18nKey.btnCancel.tr),
          onPressed: () {
            Get.back();
            Get.back();
          },
        ),
        TextButton(
          child: Text(I18nKey.btnOk.tr),
          onPressed: () {
            logic.save();
            Get.back();
            Get.back();
          },
        ),
      ],
    );
  }
}
