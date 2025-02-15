import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/db/dao/schedule_dao.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/widget/learn_config.dart';
import 'package:repeat_flutter/widget/app_bar/app_bar_widget.dart';
import 'package:repeat_flutter/widget/sheet/sheet.dart';
import 'package:repeat_flutter/widget/row/row_widget.dart';

import 'gs_cr_settings_el_logic.dart';

class GsCrSettingsElPage extends StatelessWidget {
  const GsCrSettingsElPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<GsCrSettingsElLogic>();
    return Scaffold(
      appBar: AppBar(
        actions: AppBarWidget.buildAppBarAction([
          PopupMenuItem<String>(
            onTap: logic.addItem,
            child: Text(I18nKey.btnAdd.tr),
          ),
          PopupMenuItem<String>(
            onTap: logic.reset,
            child: Text(I18nKey.btnReset.tr),
          ),
        ]),
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
                    var config = logic.state.currElConfig;
                    Sheet.showBottomSheet(context, Obx(() {
                      return ListView(
                        children: [
                          LearnConfig.buttonGroup(logic.copyItem, logic.deleteItem, logic.updateItem),
                          RowWidget.buildMiddleText(ElConfig(
                            config.title.value,
                            config.random.value,
                            config.level.value,
                            config.toLevel.value,
                            config.learnCount.value,
                            config.learnCountPerGroup.value,
                          ).trWithTitle()),
                          RowWidget.buildDivider(),
                          RowWidget.buildTextWithEdit(I18nKey.labelTitle.tr, config.title),
                          RowWidget.buildDividerWithoutColor(),
                          RowWidget.buildSwitch(I18nKey.labelElRandom.tr, config.random),
                          RowWidget.buildDividerWithoutColor(),
                          RowWidget.buildTextWithEdit(I18nKey.labelElLevel.tr, config.level),
                          RowWidget.buildDividerWithoutColor(),
                          RowWidget.buildTextWithEdit(I18nKey.labelElToLevel.tr, config.toLevel),
                          RowWidget.buildDividerWithoutColor(),
                          RowWidget.buildTextWithEdit(I18nKey.labelElLearnCount.tr, config.learnCount),
                          RowWidget.buildDividerWithoutColor(),
                          RowWidget.buildTextWithEdit(I18nKey.labelLearnCountPerGroup.tr, config.learnCountPerGroup),
                        ],
                      );
                    }));
                  },
                ),
              )
              .toList(),
        ),
      ),
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
