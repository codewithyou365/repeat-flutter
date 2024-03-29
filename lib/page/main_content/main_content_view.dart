import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_swipe_action_cell/flutter_swipe_action_cell.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/db/entity/content_index.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';

import 'main_content_logic.dart';

class MainContentPage extends StatelessWidget {
  const MainContentPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<MainContentLogic>();
    logic.init();
    return Scaffold(
      appBar: AppBar(
        title: Text(I18nKey.content.tr),
      ),
      body: buildList(logic),
    );
  }

  Widget buildList(MainContentLogic logic) {
    return GetBuilder<MainContentLogic>(
        id: MainContentLogic.id, builder: (_) => _buildList(logic));
  }

  Widget _buildList(MainContentLogic logic) {
    final state = logic.state;
    if (state.indexes.isEmpty) {
      if (state.loading.value) {
        return Container(
          alignment: Alignment.topCenter,
          padding: EdgeInsets.only(top: 80.w),
          child: const CircularProgressIndicator(),
        );
      }
      return TextButton(
        onPressed: () => {openEditDialog(logic, ContentIndex("", false))},
        child: Text("Add"),
      );
    }
    return ListView(
      children: List.generate(
        state.indexes.length,
        (index) => buildItem(logic, model: state.indexes[index]),
      ),
    );
  }

  openEditDialog(MainContentLogic logic, ContentIndex model) {
    final firstNameController = TextEditingController(text: model.url);
    Get.defaultDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min, // Ensure dialog fits content
        children: [
          Text("Enter your information:"),
          SizedBox(height: 10),
          TextFormField(
            controller: firstNameController,
            decoration: InputDecoration(
              labelText: 'URL',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          child: Text("Cancel"),
          onPressed: () {
            Get.back();
          },
        ),
        TextButton(
          child: Text("OK"),
          onPressed: () {
            logic.add(firstNameController.value.text);
            Get.back();
          },
        ),
      ],
    );
  }

  Widget buildItem(MainContentLogic logic, {required ContentIndex model}) {
    return SwipeActionCell(
      key: ObjectKey(model.url),
      trailingActions: <SwipeAction>[
        SwipeAction(
            title: I18nKey.btnDownload.tr,
            onTap: (CompletionHandler handler) async {
              //logic.downloadTest();
            }),
        SwipeAction(
            title: I18nKey.btnEdit.tr,
            onTap: (CompletionHandler handler) async {}),
        SwipeAction(
            title: I18nKey.btnDelete.tr,
            onTap: (CompletionHandler handler) async {}),
        SwipeAction(
            title: I18nKey.btnCopy.tr,
            onTap: (CompletionHandler handler) async {
              openEditDialog(logic, model);
            }),
      ],
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Text(model.url),
      ),
    );
  }
}
