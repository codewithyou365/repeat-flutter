import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/nav.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';

import 'gs_logic.dart';

class GsPage extends StatelessWidget {
  const GsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<GsLogic>();
    return Scaffold(
      appBar: AppBar(
        actions: <Widget>[
          Padding(
            padding: EdgeInsets.all(8.0.w),
            child: IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Nav.gsSettings.push();
              },
            ),
          ),
        ],
        title: Text(I18nKey.labelSelectClassroom.tr),
      ),
      body: GetBuilder<GsLogic>(
        id: GsLogic.id,
        builder: (_) => buildBody(logic),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          openAddDialog(logic, Classroom("", "", 0));
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget buildBody(GsLogic logic) {
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

  Widget buildButton(GsLogic logic, Classroom model) {
    return GestureDetector(
      onTap: () {
        logic.select(model.name);
      },
      onLongPress: () {
        openDeleteDialog(logic, model);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.w),
        child: Container(
          color: Colors.blue,
          padding: EdgeInsets.only(top: 60.h, bottom: 60.h),
          alignment: Alignment.center,
          child: Column(
            children: [
              Text(
                model.name,
                style: TextStyle(fontSize: 50.sp),
              ),
            ],
          ),
        ),
      ),
    );
  }

  openAddDialog(GsLogic logic, Classroom model) async {
    final te = TextEditingController(text: model.name);
    Get.defaultDialog(
      title: I18nKey.btnAdd.tr,
      content: Column(
        mainAxisSize: MainAxisSize.min, // Ensure dialog fits content
        children: [
          const SizedBox(height: 10),
          TextFormField(
            controller: te,
            decoration: InputDecoration(
              labelText: I18nKey.labelClassroomName.tr,
            ),
          ),
        ],
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
            logic.add(te.value.text);
          },
        ),
      ],
    );
  }

  openDeleteDialog(GsLogic logic, Classroom model) {
    RxBool deleteAll = false.obs;
    MsgBox.switchWithYesOrNo(
      I18nKey.labelDelete.tr,
      I18nKey.labelDeleteClassroom.trArgs([model.name]),
      deleteAll,
      I18nKey.labelDeleteClassroomAll.tr,
      yes: () {
        logic.delete(model.name, deleteAll.value);
        Get.back();
      },
    );
  }
}
