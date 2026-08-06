import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/db/entity/book.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/widget/app_bar/app_bar_widget.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';
import 'package:repeat_flutter/widget/tile/name_tile.dart';

import 'sc_cr_material_logic.dart';

class ScCrMaterialPage extends StatelessWidget {
  const ScCrMaterialPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<ScCrMaterialLogic>();
    return Scaffold(
      appBar: AppBar(
        title: Text(I18nKey.material.tr),
        actions: AppBarWidget.buildAppBarAction([
          PopupMenuItem<String>(
            onTap: logic.showMediaList,
            child: Text(I18nKey.mediaList.tr),
          ),
          PopupMenuItem<String>(
            onTap: logic.showSearch,
            child: Text(I18nKey.searchMaterial.tr),
          ),
          PopupMenuItem<String>(
            onTap: logic.showAdvancedEdit,
            child: Text(I18nKey.advancedEdit.tr),
          ),
          PopupMenuItem<String>(
            onTap: logic.showGameList,
            child: Text(I18nKey.manageGame.tr),
          ),
        ]),
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
      child: SingleChildScrollView(
        child: Wrap(
          spacing: 28,
          runSpacing: 28,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: state.list.map((book) => buildButton(logic, book)).toList(),
        ),
      ),
    );
  }

  Widget buildButton(ScCrMaterialLogic logic, Book book) {
    var menus = <PopupMenuEntry<String>>[];

    if (book.enable == false) {
      menus.add(PopupMenuItem<String>(
        onTap: () {
          logic.importBook(book);
        },
        child: Text(I18nKey.import.tr),
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
      menus.add(PopupMenuItem<String>(
        onTap: () {
          logic.addChapter(book);
        },
        child: Text(I18nKey.labelAddChapter.tr),
      ));
    }
    return PopupMenuButton<String>(
      child: NameTile(
        name: book.name,
        color: book.enable ? Colors.green : Colors.red,
      ),
      itemBuilder: (BuildContext context) => menus,
    );
  }
}
