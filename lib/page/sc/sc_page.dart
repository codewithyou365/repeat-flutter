import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/nav.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';

import 'sc_logic.dart';

class ScPage extends StatelessWidget {
  const ScPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<ScLogic>();
    return Scaffold(
      appBar: AppBar(
        actions: <Widget>[
          Padding(
            padding: EdgeInsets.all(8.0.w),
            child: IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                Nav.scSettings.push();
              },
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
          MsgBox.strInputWithYesOrNo(classroomName, I18nKey.btnAdd.tr, I18nKey.labelClassroomName.tr, yes: () {
            logic.add(classroomName.value);
          });
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
      child: MasonryGridView.count(
        shrinkWrap: true,
        crossAxisCount: 2,
        mainAxisSpacing: 28.w,
        crossAxisSpacing: 28.w,
        itemBuilder: (context, index) {
          if (index != 1) {
            return buildButton(logic, state.list[index]);
          }
          return Padding(
            padding: EdgeInsets.only(top: 28.w),
            child: buildButton(logic, state.list[index]),
          );
        },
        itemCount: state.list.length,
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.w),
        child: Container(
          color: Colors.blue,
          padding: const EdgeInsets.only(top: 70, bottom: 70),
          alignment: Alignment.center,
          child: Text(
            model.name,
            style: TextStyle(fontSize: 50.sp),
          ),
        ),
      ),
    );
  }

  openDeleteDialog(ScLogic logic, Classroom model) {
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
