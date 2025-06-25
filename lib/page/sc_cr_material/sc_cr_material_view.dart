import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/db/entity/book.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/nav.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';

import 'sc_cr_material_logic.dart';

class ScCrMaterialPage extends StatelessWidget {
  const ScCrMaterialPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<ScCrMaterialLogic>();
    return Scaffold(
      appBar: AppBar(
        title: Text(I18nKey.material.tr),
      ),
      body: GetBuilder<ScCrMaterialLogic>(
        id: ScCrMaterialLogic.id,
        builder: (_) => buildBody(logic),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          RxString mgn = RxString("");
          MsgBox.strInputWithYesOrNo(mgn, I18nKey.btnAdd.tr, I18nKey.labelBookName.tr, yes: () {
            logic.add(mgn.value);
            return;
          });
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget buildBody(ScCrMaterialLogic logic) {
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

  Widget buildButton(ScCrMaterialLogic logic, Book book) {
    var menus = <PopupMenuEntry<String>>[];

    if (book.docId == 0) {
      menus.add(PopupMenuItem<String>(
        onTap: () {
          openDownloadDialog(logic, book);
        },
        child: Text(I18nKey.labelRemoteImport.tr),
      ));
      menus.add(PopupMenuItem<String>(
        onTap: () => logic.addByZip(book.id!),
        child: Text(I18nKey.labelLocalZipImport.tr),
      ));
      menus.add(PopupMenuItem<String>(
        onTap: () {
          logic.createBook(book.id!);
        },
        child: Text(I18nKey.create.tr),
      ));
    } else {
      menus.add(PopupMenuItem<String>(
        onTap: () {
          logic.share(book);
        },
        child: Text(I18nKey.btnShare.tr),
      ));
      menus.add(PopupMenuItem<String>(
        onTap: () {
          logic.showContent(bookId: book.id!);
        },
        child: Text(I18nKey.labelContent.tr),
      ));
    }
    menus.add(PopupMenuItem<String>(
      onTap: () {
        openDeleteDialog(logic, book);
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
              color: book.docId == 0 ? Colors.red : Colors.green,
              padding: const EdgeInsets.only(top: 70, bottom: 70),
              alignment: Alignment.center,
              child: Text(
                book.name,
                style: TextStyle(fontSize: 50.sp),
              ),
            ),
            if ((book.chapterWarning == true || book.verseWarning == true) && book.docId != 0)
              IconButton(
                onPressed: () {
                  if (book.verseWarning) {
                    logic.showContent(bookId: book.id!, defaultTap: 2);
                  } else if (book.chapterWarning) {
                    logic.showContent(bookId: book.id!, defaultTap: 1);
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

  openDeleteDialog(ScCrMaterialLogic logic, Book model) {
    MsgBox.yesOrNo(
      title: I18nKey.labelDelete.tr,
      desc: I18nKey.labelDeleteBook.trArgs([model.name]),
      yes: () {
        logic.delete(model.id!);
        Get.back();
      },
    );
  }

  openDownloadDialog(ScCrMaterialLogic logic, Book model) {
    final state = logic.state;
    RxString downloadUrl = model.url.obs;
    MsgBox.strInputWithYesOrNo(
      downloadUrl,
      I18nKey.labelDownloadBook.tr,
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
        logic.download(model.id!, downloadUrl.value);
      },
      yesBtnTitle: I18nKey.btnDownload.tr,
      noBtnTitle: I18nKey.btnClose.tr,
      qrPagePath: Nav.scan.path,
    );
  }
}
