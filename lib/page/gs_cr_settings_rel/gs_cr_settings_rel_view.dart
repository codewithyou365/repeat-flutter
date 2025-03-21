import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/common/date.dart';
import 'package:repeat_flutter/db/dao/schedule_dao.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/widget/learn_config.dart';
import 'package:repeat_flutter/widget/app_bar/app_bar_widget.dart';
import 'package:repeat_flutter/widget/row/row_widget.dart';
import 'package:repeat_flutter/widget/sheet/sheet.dart';
import 'gs_cr_settings_rel_logic.dart';

class GsCrSettingsRelPage extends StatelessWidget {
  const GsCrSettingsRelPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<GsCrSettingsRelLogic>();
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
        title: Text(I18nKey.labelConfigSettingsForRel.tr),
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
                  title: Text(item.config.trWithTitle()),
                  onTap: () {
                    logic.setCurrElConfig(item);
                    var config = logic.state.currRelConfig;
                    Sheet.showBottomSheet(context, Obx(() {
                      return ListView(
                        children: [
                          LearnConfig.buttonGroup(logic.copyItem, logic.deleteItem, logic.updateItem),
                          RowWidget.buildMiddleText(RelConfig(
                            config.title.value,
                            config.level.value,
                            config.before.value,
                            Date(config.from.value),
                            config.learnCountPerGroup.value,
                          ).trWithTitle()),
                          RowWidget.buildDivider(),
                          RowWidget.buildTextWithEdit(I18nKey.labelTitle.tr, config.title),
                          RowWidget.buildDividerWithoutColor(),
                          RowWidget.buildTextWithEdit(I18nKey.labelRelBefore.tr, config.before),
                          RowWidget.buildDividerWithoutColor(),
                          RowWidget.buildDateWithEdit(I18nKey.labelRelFrom.tr, config.from, context),
                          RowWidget.buildDividerWithoutColor(),
                          RowWidget.buildTextWithEdit(I18nKey.labelLearnCountPerGroup.tr, config.learnCountPerGroup),
                        ],
                      );
                    }));
                    //openEditDialog(logic, context);
                  },
                ),
              )
              .toList(),
        ),
      ),
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
