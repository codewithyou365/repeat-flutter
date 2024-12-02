import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/db/entity/material.dart' as entity;
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/nav.dart';
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
            icon: const Icon(Icons.add),
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                onTap: logic.todoAddByZip,
                child: Text(I18nKey.labelLocalZipImport.tr),
              ),
              PopupMenuItem<String>(
                onTap: Nav.gsCrContentTemplate.push,
                child: Text(I18nKey.labelLocalMediaImport.tr),
              ),
            ],
          ),
        ],
      ),
      body: GetBuilder<GsCrContentLogic>(
        id: GsCrContentLogic.id,
        builder: (_) => buildBody(logic),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          RxString mgn = RxString("");
          MsgBox.strInputWithYesOrNo(mgn, I18nKey.btnAdd.tr, I18nKey.labelMaterialName.tr, yes: () {
            logic.add(mgn.value);
            return;
          });
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget buildBody(GsCrContentLogic logic) {
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

  Widget buildButton(GsCrContentLogic logic, entity.Material model) {
    var menus = <PopupMenuEntry<String>>[];

    if (model.docId == 0) {
      // PopupMenuItem<String>(
      //   onTap: logic.todoAddByZip,
      //   child: Text(I18nKey.labelLocalZipImport.tr),
      // ),
      menus.add(PopupMenuItem<String>(
        onTap: () {
          openDownloadDialog(logic, model);
        },
        child: Text(I18nKey.labelRemoteImport.tr),
      ));
      menus.add(PopupMenuItem<String>(
        onTap: () {
          Nav.gsCrContentTemplate.push(arguments: <int>[model.id!, model.serial]);
        },
        child: Text(I18nKey.labelLocalMediaImport.tr),
      ));
    } else {
      menus.add(PopupMenuItem<String>(
        onTap: () {
          openScheduleDialog(logic, model);
        },
        child: Text(I18nKey.btnSchedule.tr),
      ));
    }
    return PopupMenuButton<String>(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.w),
        child: Container(
          color: model.docId == 0 ? Colors.red : Colors.green,
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
      itemBuilder: (BuildContext context) => menus,
    );
  }

  // Widget buildList(BuildContext context, GsCrContentLogic logic) {
  //   return GetBuilder<GsCrContentLogic>(
  //     id: GsCrContentLogic.id,
  //     builder: (_) => _buildList(context, logic),
  //   );
  // }
  //
  // Widget _buildList(BuildContext context, GsCrContentLogic logic) {
  //   final state = logic.state;
  //   if (state.list.isEmpty) {
  //     if (state.loading.value) {
  //       return Container(
  //         alignment: Alignment.topCenter,
  //         padding: EdgeInsets.only(top: 80.w),
  //         child: const CircularProgressIndicator(),
  //       );
  //     }
  //   }
  //   return ListView(
  //     children: List.generate(
  //       state.list.length,
  //       (index) => buildItem(context, logic, state.list[index]),
  //     ),
  //   );
  // }

  openDeleteDialog(GsCrContentLogic logic, entity.Material model) {
    MsgBox.yesOrNo(
      I18nKey.labelDelete.tr,
      I18nKey.labelDeleteMaterial.trArgs([model.name]),
      yes: () {
        logic.delete(model.id!, model.serial);
        Get.back();
      },
    );
  }

  openDownloadDialog(GsCrContentLogic logic, entity.Material model) {
    final state = logic.state;
    RxString downloadUrl = "".obs;
    MsgBox.strInputWithYesOrNo(
      downloadUrl,
      I18nKey.labelDownloadContent.tr,
      I18nKey.labelRemoteUrl.tr,
      nextChildren: [
        const SizedBox(height: 20),
        Obx(() {
          return LinearProgressIndicator(
            value: state.indexCount.value / state.indexTotal.value,
            semanticsLabel: "${(state.indexCount.value / state.indexTotal.value * 100).toStringAsFixed(1)}%",
          );
        }),
        const SizedBox(height: 20),
        Obx(() {
          return LinearProgressIndicator(
            value: state.contentProgress.value,
            semanticsLabel: "${(state.contentProgress.value * 100).toStringAsFixed(1)}%",
          );
        }),
      ],
      yes: () {
        logic.download(model.id!, model.serial, downloadUrl.value);
      },
      yesBtnTitle: I18nKey.btnDownload.tr,
      noBtnTitle: I18nKey.btnClose.tr,
    );
  }

  openScheduleDialog(GsCrContentLogic logic, entity.Material model) async {
    var unitCount = await logic.getUnitCount(model.serial);
    if (unitCount == 0) {
      logic.resetDoc(model.id!);
      return;
    }
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
            logic.addToSchedule(model);
            Get.back();
          },
        ),
      ],
    );
  }

  Widget buildItem(BuildContext context, GsCrContentLogic logic, Material model) {
    return Container();
    // var textStyle = TextStyle(fontSize: 12.w);
    // return SwipeActionCell(
    //   key: ObjectKey(model.url),
    //   leadingActions: <SwipeAction>[
    //     SwipeAction(
    //       title: I18nKey.btnDelete.tr,
    //       style: textStyle,
    //       color: Theme.of(context).secondaryHeaderColor,
    //       onTap: (CompletionHandler handler) async {
    //         openDeleteDialog(logic, model);
    //       },
    //     ),
    //     SwipeAction(
    //       title: I18nKey.btnShare.tr,
    //       style: textStyle,
    //       color: Theme.of(context).secondaryHeaderColor,
    //       onTap: (CompletionHandler handler) async {
    //         logic.todoShare(model);
    //       },
    //     ),
    //   ],
    //   trailingActions: <SwipeAction>[
    //     SwipeAction(
    //       title: I18nKey.btnSchedule.tr,
    //       style: textStyle,
    //       color: Theme.of(context).secondaryHeaderColor,
    //       onTap: (CompletionHandler handler) async {
    //         openScheduleDialog(logic, model);
    //       },
    //     ),
    //     SwipeAction(
    //       title: I18nKey.btnDownload.tr,
    //       style: textStyle,
    //       color: Theme.of(context).secondaryHeaderColor,
    //       onTap: (CompletionHandler handler) async {
    //         openDownloadDialog(logic, model);
    //       },
    //     ),
    //     SwipeAction(
    //       title: I18nKey.btnCopy.tr,
    //       style: textStyle,
    //       color: Theme.of(context).secondaryHeaderColor,
    //       onTap: (CompletionHandler handler) async {
    //         openEditDialog(logic, model.url, I18nKey.labelAddContentIndex.tr);
    //       },
    //     ),
    //   ],
    //   child: Padding(
    //     padding: EdgeInsets.all(16.w),
    //     child: Text(model.url),
    //   ),
    // );
  }
}
