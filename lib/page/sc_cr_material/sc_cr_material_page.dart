import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/db/entity/book.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
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
        crossAxisCount: 3,
        mainAxisSpacing: 28,
        crossAxisSpacing: 28,
        itemBuilder: (context, index) {
          if (index != 1) {
            return buildButton(logic, state.list[index]);
          }
          return Padding(
            padding: EdgeInsets.only(top: 10),
            child: buildButton(logic, state.list[index]),
          );
        },
        itemCount: state.list.length,
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
    }
    return PopupMenuButton<String>(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Container(
              color: book.enable ? Colors.green : Colors.red,
              padding: const EdgeInsets.all(8),
              alignment: Alignment.center,
              child: Text(
                book.name,
                style: TextStyle(fontSize: 30),
              ),
            ),
          ],
        ),
      ),
      itemBuilder: (BuildContext context) => menus,
    );
  }
}
