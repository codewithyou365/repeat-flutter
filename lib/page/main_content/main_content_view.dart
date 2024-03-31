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
      body: buildList(context, logic),
    );
  }

  Widget buildList(BuildContext context, MainContentLogic logic) {
    return GetBuilder<MainContentLogic>(
      id: MainContentLogic.id,
      builder: (_) => _buildList(context, logic),
    );
  }

  Widget _buildList(BuildContext context, MainContentLogic logic) {
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
        onPressed: () => {
          openEditDialog(logic, ContentIndex(""), I18nKey.labelAddContentIndex.tr),
        },
        child: Text(I18nKey.btnAdd.tr),
      );
    }
    return ListView(
      children: List.generate(
        state.indexes.length,
        (index) => buildItem(context, logic, state.indexes[index]),
      ),
    );
  }

  openEditDialog(MainContentLogic logic, ContentIndex model, String title) {
    final firstNameController = TextEditingController(text: model.url);
    Get.defaultDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min, // Ensure dialog fits content
        children: [
          Text(title),
          const SizedBox(height: 10),
          TextFormField(
            controller: firstNameController,
            decoration: InputDecoration(
              labelText: I18nKey.labelUrl.tr,
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
            logic.add(firstNameController.value.text);
            Get.back();
          },
        ),
      ],
    );
  }

  openDeleteDialog(MainContentLogic logic, ContentIndex model) {
    Get.defaultDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min, // Ensure dialog fits content
        children: [
          Text(I18nKey.labelDeleteContentIndex.trArgs([model.url])),
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
            logic.delete(model.url);
            Get.back();
          },
        ),
      ],
    );
  }

  openDownloadDialog(MainContentLogic logic, ContentIndex model) {
    final state = logic.state;
    Get.defaultDialog(
      title: I18nKey.labelDownloadContent.tr,
      content: Obx(() {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(
              value: state.indexCount.value / state.indexTotal.value,
              semanticsLabel: "${(state.indexCount.value / state.indexTotal.value * 100).toStringAsFixed(1)}%",
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: state.contentProgress.value,
              semanticsLabel: "${(state.contentProgress.value * 100).toStringAsFixed(1)}%",
            ),
          ],
        );
      }),
      actions: [
        TextButton(
          child: Text(I18nKey.btnCancel.tr),
          onPressed: () {
            Get.back();
          },
        ),
        TextButton(
          child: Text(I18nKey.btnDownload.tr),
          onPressed: () {
            logic.download(model.url);
          },
        ),
      ],
    );
  }

  Widget buildItem(BuildContext context, MainContentLogic logic, ContentIndex model) {
    var textStyle = TextStyle(fontSize: 12.w);
    return SwipeActionCell(
      key: ObjectKey(model.url),
      trailingActions: <SwipeAction>[
        SwipeAction(
          title: I18nKey.btnDownload.tr,
          style: textStyle,
          color: Theme.of(context).secondaryHeaderColor,
          onTap: (CompletionHandler handler) async {
            openDownloadDialog(logic, model);
          },
        ),
        SwipeAction(
          title: I18nKey.btnDelete.tr,
          style: textStyle,
          color: Theme.of(context).secondaryHeaderColor,
          onTap: (CompletionHandler handler) async {
            openDeleteDialog(logic, model);
          },
        ),
        SwipeAction(
          title: I18nKey.btnCopy.tr,
          style: textStyle,
          color: Theme.of(context).secondaryHeaderColor,
          onTap: (CompletionHandler handler) async {
            openEditDialog(logic, model, I18nKey.labelAddContentIndex.tr);
          },
        ),
      ],
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Text(model.url),
      ),
    );
  }
}