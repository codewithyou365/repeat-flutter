import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/db/entity/content.dart';
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
      ),
      body: GetBuilder<GsCrContentLogic>(
        id: GsCrContentLogic.id,
        builder: (_) => buildBody(logic),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          RxString mgn = RxString("");
          MsgBox.strInputWithYesOrNo(mgn, I18nKey.btnAdd.tr, I18nKey.labelContentName.tr, yes: () {
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

  Widget buildButton(GsCrContentLogic logic, Content model) {
    var menus = <PopupMenuEntry<String>>[];

    if (model.docId == 0) {
      menus.add(PopupMenuItem<String>(
        onTap: () {
          openDownloadDialog(logic, model);
        },
        child: Text(I18nKey.labelRemoteImport.tr),
      ));
      menus.add(PopupMenuItem<String>(
        onTap: () => logic.addByZip(model.id!, model.serial),
        child: Text(I18nKey.labelLocalZipImport.tr),
      ));
      menus.add(PopupMenuItem<String>(
        onTap: () {
          Nav.gsCrContentTemplate.push(arguments: <int>[model.id!, model.serial]);
        },
        child: Text(I18nKey.create.tr),
      ));
    } else {
      menus.add(PopupMenuItem<String>(
        onTap: () {
          logic.share(model);
        },
        child: Text(I18nKey.btnShare.tr),
      ));
      menus.add(PopupMenuItem<String>(
        onTap: () {
          logic.showContent(model.id!);
        },
        child: Text(I18nKey.labelContent.tr),
      ));
      menus.add(PopupMenuItem<String>(
        onTap: () {
          logic.showLesson(model.id!);
        },
        child: Text(I18nKey.labelLessonName.tr),
      ));
      menus.add(PopupMenuItem<String>(
        onTap: () {
          logic.showVerse(model.id!);
        },
        child: Text(I18nKey.labelVerseName.tr),
      ));
    }
    menus.add(PopupMenuItem<String>(
      onTap: () {
        openDeleteDialog(logic, model);
      },
      child: Text(I18nKey.btnDelete.tr),
    ));
    return PopupMenuButton<String>(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.w),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Container(
              color: model.docId == 0 ? Colors.red : Colors.green,
              padding: const EdgeInsets.only(top: 70, bottom: 70),
              alignment: Alignment.center,
              child: Text(
                model.name,
                style: TextStyle(fontSize: 50.sp),
              ),
            ),
            if ((model.lessonWarning == true || model.verseWarning == true) && model.docId != 0)
              IconButton(
                onPressed: () {
                  if (model.verseWarning) {
                    logic.showVerse(model.id!);
                  } else if (model.lessonWarning) {
                    logic.showLesson(model.id!);
                  }
                },
                color: Colors.yellow,
                icon: const Icon(Icons.warning),
              ),
          ],
        ),
      ),
      itemBuilder: (BuildContext context) => menus,
    );
  }

  openDeleteDialog(GsCrContentLogic logic, Content model) {
    MsgBox.yesOrNo(
      title: I18nKey.labelDelete.tr,
      desc: I18nKey.labelDeleteContent.trArgs([model.name]),
      yes: () {
        logic.delete(model.id!, model.serial);
        Get.back();
      },
    );
  }

  openDownloadDialog(GsCrContentLogic logic, Content model) {
    final state = logic.state;
    RxString downloadUrl = model.url.obs;
    MsgBox.strInputWithYesOrNo(
      downloadUrl,
      I18nKey.labelDownloadContent.tr,
      I18nKey.labelRemoteUrl.tr,
      nextChildren: [
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
        const SizedBox(height: 10),
      ],
      yes: () {
        logic.download(model.id!, model.serial, downloadUrl.value);
      },
      yesBtnTitle: I18nKey.btnDownload.tr,
      noBtnTitle: I18nKey.btnClose.tr,
      qrPagePath: Nav.gsCrContentScan.path,
    );
  }
}
