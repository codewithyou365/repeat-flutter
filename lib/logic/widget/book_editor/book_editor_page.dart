import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';
import 'package:repeat_flutter/widget/row/row_widget.dart';
import 'package:repeat_flutter/widget/sheet/sheet.dart';

import 'book_editor_logic.dart';

class BookEditorPage<T extends GetxController> {
  Future<void> open(BookEditorLogic<T> logic) {
    var context = Get.context!;
    final state = logic.state;
    return Sheet.withHeaderAndBody(
      context,
      Padding(
        key: GlobalKey(),
        padding: EdgeInsets.symmetric(horizontal: 10.0.w, vertical: 0.0),
        child: Column(
          children: [
            RowWidget.buildSwitch(
              I18nKey.editBook.tr,
              state.webStart,
              logic.switchWeb,
            ),
            RowWidget.buildDivider(),
          ],
        ),
      ),
      GetBuilder<T>(
        id: BookEditorLogic.id,
        builder: (_) => _buildList(context, logic),
      ),
    );
  }

  Widget _buildList(BuildContext context, BookEditorLogic logic) {
    final state = logic.state;
    return ListView(
      children: [
        if (state.addresses.isNotEmpty)
          ...List.generate(
            state.addresses.length,
            (index) => buildItem(state.addresses[index].title, state.addresses[index].address, logic.randCredentials),
          ),
      ],
    );
  }

  Widget buildItem(String itemLabel, String desc, VoidCallback? key) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Card(
        child: InkWell(
          onTap: () {
            MsgBox.noWithQrCode(
              itemLabel,
              desc,
              desc,
            );
          },
          child: ListTile(
            title: Row(
              children: [
                Text(itemLabel),
                const Spacer(),
                if (key != null)
                  IconButton(
                    icon: const Icon(Icons.key),
                    onPressed: key,
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
            subtitle: Padding(
              padding: EdgeInsets.all(16.w),
              child: Text(desc),
            ),
          ),
        ),
      ),
    );
  }
}
