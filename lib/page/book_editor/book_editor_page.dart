import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';
import 'package:repeat_flutter/widget/row/row_widget.dart';

import 'book_editor_logic.dart';

class BookEditorPage extends StatelessWidget {
  const BookEditorPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<BookEditorLogic>();
    return Scaffold(
      appBar: AppBar(
        title: Text(I18nKey.editBook.tr),
      ),
      body: GetBuilder<BookEditorLogic>(
        id: BookEditorLogic.id,
        builder: (_) => _buildList(context, logic),
      ),
    );
  }

  Widget _buildList(BuildContext context, BookEditorLogic logic) {
    final state = logic.state;
    return ListView(children: [
      // buildItem(
      //   "导入",
      //   "只会导入媒体文件，如视频，音频，图片等",
      //   null,
      // ),
      RowWidget.buildDividerWithoutColor(),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: RowWidget.buildSwitch(I18nKey.web.tr, state.webStart, logic.switchWeb),
      ),
      if (state.addresses.isNotEmpty)
        ...List.generate(
          state.addresses.length,
          (index) => buildItem(state.addresses[index].title, state.addresses[index].address, logic.randCredentials),
        )
    ]);
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
