import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/common/date.dart';
import 'package:repeat_flutter/db/dao/schedule_dao.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';

import 'gs_cr_settings_rel_logic.dart';

class GsCrSettingsRelPage extends StatelessWidget {
  const GsCrSettingsRelPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<GsCrSettingsRelLogic>();
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
      body: GetBuilder<GsCrSettingsRelLogic>(
        id: GsCrSettingsRelLogic.elConfigsId,
        builder: (_) => ReorderableListView(
          onReorder: logic.reorder,
          children: logic.state.relConfigs
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

  openEditDialog(GsCrSettingsRelLogic logic) {
    var config = logic.state.currRelConfig;
    Get.defaultDialog(
      title: I18nKey.settings.tr,
      content: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Column(
          children: [
            buildNumberItem("多少天前", config.before),
            buildNumberItem("开始时间", config.from),
            buildNumberItem("追赶", config.chase),
            buildNumberItem("每组数量", config.learnCountPerGroup),
            const Divider(),
            Obx(() {
              return Text(RelConfig(
                config.level.value,
                config.before.value,
                config.chase.value,
                Date(config.from.value),
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

  tryOpenSaveConfirmDialog(GsCrSettingsRelLogic logic) {
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
