import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/db/dao/schedule_dao.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';

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
                  title: Text(item.config.trWithTitle()),
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
            buildStringItem(I18nKey.labelTitle.tr, config.title),
            buildSwitch(I18nKey.labelElRandom.tr, config.random),
            buildNumberItem(I18nKey.labelElLevel.tr, config.level),
            buildNumberItem(I18nKey.labelElToLevel.tr, config.toLevel),
            buildNumberItem(I18nKey.labelElLearnCount.tr, config.learnCount),
            buildNumberItem(I18nKey.labelLearnCountPerGroup.tr, config.learnCountPerGroup),
            const Divider(),
            Obx(() {
              return Text(ElConfig(
                config.title.value,
                config.random.value,
                config.level.value,
                config.toLevel.value,
                config.learnCount.value,
                config.learnCountPerGroup.value,
              ).trWithTitle());
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

  Widget buildStringItem(String title, RxString value) {
    return InkWell(
      onTap: () {
        MsgBox.strInputWithYesOrNo(value, title, "");
      },
      child: Row(
        children: [
          Text(title),
          const Spacer(),
          Obx(() {
            return Text(value.value.toString(), style: TextStyle(fontSize: 24.sp));
          })
        ],
      ),
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
    RxInt tempValue = RxInt(value.value);
    Get.defaultDialog(
      title: title,
      content: buildInput(tempValue),
      actions: [
        TextButton(
          child: Text(I18nKey.btnOk.tr),
          onPressed: () {
            value.value = tempValue.value;
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
