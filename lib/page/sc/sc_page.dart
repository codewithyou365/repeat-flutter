import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/nav.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';
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
          RxString classroomName = "".obs;
          MsgBox.strInputWithYesOrNo(
            classroomName,
            I18nKey.btnAdd.tr,
            I18nKey.labelClassroomName.tr,
            yes: () {
              logic.add(classroomName.value);
            },
          );
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
    return GestureDetector(
      onTap: () {
        logic.select(model.id, model.name);
      },
      onLongPress: () {
        openDeleteDialog(logic, model);
      },
      child: NameTile(
        name: model.name,
        color: Colors.blue,
      ),
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
