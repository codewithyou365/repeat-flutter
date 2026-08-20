import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/ai/ai_support.dart';
import 'package:repeat_flutter/nav.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';
import 'package:repeat_flutter/widget/sheet/sheet.dart';
import 'package:repeat_flutter/widget/tile/name_tile.dart';

import 'sc_logic.dart';

class ScPage extends StatelessWidget {
  const ScPage({super.key});

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<ScLogic>();
    return Scaffold(
      appBar: AppBar(
        actions: <Widget>[
          Padding(
            padding: EdgeInsets.all(8.0.w),
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  onTap: () {
                    Nav.scSettingsLang.push();
                  },
                  child: ListTile(
                    leading: const Icon(Icons.language),
                    title: Text(I18nKey.language.tr),
                  ),
                ),
                PopupMenuItem<String>(
                  onTap: () {
                    Nav.scSettingsTheme.push();
                  },
                  child: ListTile(
                    leading: const Icon(Icons.brightness_6),
                    title: Text(I18nKey.theme.tr),
                  ),
                ),
                PopupMenuItem<String>(
                  onTap: () {
                    Nav.scSettingsData.push();
                  },
                  child: ListTile(
                    leading: const Icon(Icons.storage),
                    title: Text(I18nKey.data.tr),
                  ),
                ),
                // 端上模型只有 Android/iOS 跑得了，其它平台连入口都不给
                if (AiSupport.available)
                  PopupMenuItem<String>(
                    onTap: () {
                      Nav.scSettingsAi.push();
                    },
                    child: ListTile(
                      leading: const Icon(Icons.psychology),
                      title: Text(I18nKey.aiModel.tr),
                    ),
                  ),
              ],
            ),
          ),
        ],
        title: Text(I18nKey.labelSelectClassroom.tr),
      ),
      body: GetBuilder<ScLogic>(
        id: ScLogic.id,
        builder: (_) => buildBody(logic),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          logic.openAddOrImportMenu();
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget buildBody(ScLogic logic) {
    var state = logic.state;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 28.w),
      child: SingleChildScrollView(
        child: Wrap(
          spacing: 28,
          runSpacing: 28,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: state.list.map((model) => buildButton(logic, model)).toList(),
        ),
      ),
    );
  }

  Widget buildButton(ScLogic logic, Classroom model) {
    return Builder(
      builder: (context) {
        return GestureDetector(
          onTap: () {
            logic.select(model.id, model.name);
          },
          onLongPressStart: (details) {
            openActionMenu(context, logic, model, details.globalPosition);
          },
          child: NameTile(
            name: model.name,
            color: Colors.blue,
          ),
        );
      },
    );
  }

  void openActionMenu(BuildContext context, ScLogic logic, Classroom model, Offset position) {
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      items: <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          onTap: () {
            openRenameDialog(logic, model);
          },
          child: ListTile(
            leading: const Icon(Icons.edit),
            title: Text(I18nKey.labelRenameClassroom.tr),
          ),
        ),
        PopupMenuItem<String>(
          onTap: () {
            openMoveSheet(context, logic, model);
          },
          child: ListTile(
            leading: const Icon(Icons.swap_vert),
            title: Text(I18nKey.labelMove.tr),
          ),
        ),
        PopupMenuItem<String>(
          onTap: () {
            Nav.scShare.push(arguments: [model]);
          },
          child: ListTile(
            leading: const Icon(Icons.share),
            title: Text(I18nKey.share.tr),
          ),
        ),
        PopupMenuItem<String>(
          onTap: () {
            openDeleteDialog(logic, model);
          },
          child: ListTile(
            leading: const Icon(Icons.delete),
            title: Text(I18nKey.labelDelete.tr),
          ),
        ),
      ],
    );
  }

  void openMoveSheet(BuildContext context, ScLogic logic, Classroom model) {
    Sheet.showBottomSheet(
      context,
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.vertical_align_top),
            title: Text(I18nKey.labelMoveToTop.tr),
            onTap: () {
              Get.back();
              logic.moveToTop(model.id);
            },
          ),
          ListTile(
            leading: const Icon(Icons.arrow_upward),
            title: Text(I18nKey.labelMoveUp.tr),
            onTap: () {
              Get.back();
              logic.moveUp(model.id);
            },
          ),
          ListTile(
            leading: const Icon(Icons.arrow_downward),
            title: Text(I18nKey.labelMoveDown.tr),
            onTap: () {
              Get.back();
              logic.moveDown(model.id);
            },
          ),
          ListTile(
            leading: const Icon(Icons.vertical_align_bottom),
            title: Text(I18nKey.labelMoveToBottom.tr),
            onTap: () {
              Get.back();
              logic.moveToBottom(model.id);
            },
          ),
        ],
      ),
      rate: 0.32,
    );
  }

  void openRenameDialog(ScLogic logic, Classroom model) {
    RxString classroomName = model.name.obs;
    MsgBox.strInputWithYesOrNo(
      classroomName,
      I18nKey.labelRenameClassroom.tr,
      I18nKey.labelClassroomName.tr,
      yes: () {
        logic.rename(model.id, classroomName.value);
      },
    );
  }

  void openDeleteDialog(ScLogic logic, Classroom model) {
    RxBool deleteAll = false.obs;
    MsgBox.checkboxWithYesOrNo(
      title: I18nKey.labelDelete.tr,
      desc: I18nKey.labelDeleteClassroom.trArgs([model.name]),
      select: deleteAll,
      selectDesc: I18nKey.labelDeleteClassroomAll.tr,
      yes: () {
        logic.delete(model.id, deleteAll.value);
        Get.back();
      },
    );
  }
}
