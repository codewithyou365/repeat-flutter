import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_swipe_action_cell/flutter_swipe_action_cell.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/db/entity/content_index.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';

import 'gs_cr_content_logic.dart';

class GsCrContentPage extends StatelessWidget {
  const GsCrContentPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<GsCrContentLogic>();
    return Scaffold(
      appBar: AppBar(
        title: Text(I18nKey.content.tr),
        actions: <Widget>[
          PopupMenuButton<String>(
            onSelected: (String result) {
              print('Selected: $result');
            },
            icon: const Icon(Icons.add),
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                onTap: logic.addByScan,
                value: 'SCAN',
                child: const Text('SCAN'),
              ),
              PopupMenuItem<String>(
                onTap: () {
                  openEditDialog(logic, "", I18nKey.labelAddContentIndex.tr);
                },
                value: 'URL',
                child: const Text('URL'),
              ),
              PopupMenuItem<String>(
                onTap: logic.addByZip,
                value: 'ZIP',
                child: const Text('ZIP'),
              ),
            ],
          ),
        ],
      ),
      body: buildList(context, logic),
    );
  }

  Widget buildList(BuildContext context, GsCrContentLogic logic) {
    return GetBuilder<GsCrContentLogic>(
      id: GsCrContentLogic.id,
      builder: (_) => _buildList(context, logic),
    );
  }

  Widget _buildList(BuildContext context, GsCrContentLogic logic) {
    final state = logic.state;
    if (state.indexes.isEmpty) {
      if (state.loading.value) {
        return Container(
          alignment: Alignment.topCenter,
          padding: EdgeInsets.only(top: 80.w),
          child: const CircularProgressIndicator(),
        );
      }
    }
    return ListView(
      children: List.generate(
        state.indexes.length,
        (index) => buildItem(context, logic, state.indexes[index]),
      ),
    );
  }

  openEditDialog(GsCrContentLogic logic, String url, String title) {
    var value = url.obs;
    MsgBox.strInputWithYesOrNo(value, title, I18nKey.labelUrl.tr, yes: () {
      logic.add(value.value);
      Get.back();
    });
  }

  openDeleteDialog(GsCrContentLogic logic, ContentIndex model) {
    Get.defaultDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
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

  openDownloadDialog(GsCrContentLogic logic, ContentIndex model) {
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

  openScheduleDialog(GsCrContentLogic logic, ContentIndex model) async {
    var unitCount = await logic.getUnitCount(model.url);
    Get.defaultDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min, // Ensure dialog fits content
        children: [
          Text(I18nKey.labelScheduleContent.trArgs([unitCount.toString()])),
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
            logic.addToSchedule(model.url, model.sort);
            Get.back();
          },
        ),
      ],
    );
  }

  Widget buildItem(BuildContext context, GsCrContentLogic logic, ContentIndex model) {
    var textStyle = TextStyle(fontSize: 12.w);
    return SwipeActionCell(
      key: ObjectKey(model.url),
      leadingActions: <SwipeAction>[
        SwipeAction(
          title: I18nKey.btnDelete.tr,
          style: textStyle,
          color: Theme.of(context).secondaryHeaderColor,
          onTap: (CompletionHandler handler) async {
            openDeleteDialog(logic, model);
          },
        ),
        SwipeAction(
          title: I18nKey.btnShare.tr,
          style: textStyle,
          color: Theme.of(context).secondaryHeaderColor,
          onTap: (CompletionHandler handler) async {
            logic.share(model);
          },
        ),
      ],
      trailingActions: <SwipeAction>[
        SwipeAction(
          title: I18nKey.btnSchedule.tr,
          style: textStyle,
          color: Theme.of(context).secondaryHeaderColor,
          onTap: (CompletionHandler handler) async {
            openScheduleDialog(logic, model);
          },
        ),
        SwipeAction(
          title: I18nKey.btnDownload.tr,
          style: textStyle,
          color: Theme.of(context).secondaryHeaderColor,
          onTap: (CompletionHandler handler) async {
            openDownloadDialog(logic, model);
          },
        ),
        SwipeAction(
          title: I18nKey.btnCopy.tr,
          style: textStyle,
          color: Theme.of(context).secondaryHeaderColor,
          onTap: (CompletionHandler handler) async {
            openEditDialog(logic, model.url, I18nKey.labelAddContentIndex.tr);
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
