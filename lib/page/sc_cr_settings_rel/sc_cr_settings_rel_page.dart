import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/common/date.dart';
import 'package:repeat_flutter/db/dao/schedule_dao.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/widget/app_bar/app_bar_widget.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';
import 'package:repeat_flutter/widget/row/row_widget.dart';
import 'package:repeat_flutter/widget/sheet/sheet.dart';
import 'sc_cr_settings_rel_logic.dart';

class ScCrSettingsRelPage extends StatelessWidget {
  const ScCrSettingsRelPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<ScCrSettingsRelLogic>();
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
      body: GetBuilder<ScCrSettingsRelLogic>(
        id: ScCrSettingsRelLogic.elConfigsId,
        builder: (_) => ReorderableListView(
          onReorder: logic.reorder,
          children: logic.state.reviewLearnConfigs
              .map(
                (item) => ListTile(
                  key: item.key,
                  title: Text(item.config.trWithTitle()),
                  onTap: () {
                    logic.setCurrElConfig(item);
                    var config = logic.state.currRelConfig;
                    Sheet.showBottomSheet(
                      context,
                      Obx(() {
                        return ListView(
                          children: [
                            RowWidget.buildButtons([
                              Button(I18nKey.btnCopy.tr, logic.copyItem),
                              Button(I18nKey.btnDelete.tr, logic.deleteItem),
                              Button(I18nKey.btnOk.tr, logic.updateItem),
                            ]),
                            RowWidget.buildMiddleText(
                              ReviewLearnConfig(
                                title: config.title.value,
                                level: config.level.value,
                                before: config.before.value,
                                from: Date(config.from.value),
                                learnCountPerGroup: config.learnCountPerGroup.value,
                              ).trWithTitle(),
                            ),
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
                      }),
                    );
                    //openEditDialog(logic, context);
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  void tryOpenSaveConfirmDialog(ScCrSettingsRelLogic logic) {
    var same = logic.isSame();
    if (same) {
      Get.back();
      return;
    }
    MsgBox.yesOrNo(
      title: I18nKey.labelSavingConfirm.tr,
      desc: I18nKey.labelConfigChange.tr,
      no: () {
        Get.back();
        Get.back();
      },
      yes: () {
        logic.save();
        Get.back();
        Get.back();
      },
    );
  }
}
