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
    final int itemCount = logic.onExpand != null ? 2 : 1;
    final double rowUnit = RowWidget.rowHeight + RowWidget.dividerHeight;
    return Sheet.showBottomSheet(
      context,
      ListView(
        children: [
          Obx(
            () => RowWidget.buildSelect(
              title: I18nKey.network.tr,
              leading: logic.state.webStart.value ? RowWidget.buildGreenDot() : RowWidget.buildGreenDot(color: Colors.grey),
              onTap: () => _openNetwork(logic),
            ),
          ),
          if (logic.onExpand != null) ...[
            RowWidget.buildDividerWithoutColor(),
            RowWidget.buildSelect(
              title: I18nKey.assistant.tr,
              onTap: () => logic.onExpand?.call(),
            ),
          ],
        ],
      ),
      head: SheetHead(
        height: rowUnit,
        widgets: [
          Obx(
            () => RowWidget.buildMiddleText(
              I18nKey.advancedEdit.tr,
              leading: logic.state.webStart.value ? RowWidget.buildGreenDot() : RowWidget.buildGreenDot(color: Colors.grey),
            ),
          ),
          RowWidget.buildDivider(),
        ],
      ),
      height: (itemCount + 1) * rowUnit,
    );
  }

  Future<void> _openNetwork(BookEditorLogic<T> logic) {
    var context = Get.context!;
    final state = logic.state;
    return Sheet.showBottomSheet(
      context,
      GetBuilder<T>(
        id: BookEditorLogic.id,
        builder: (_) => _buildList(context, logic),
      ),
      head: SheetHead(
        height: RowWidget.rowHeight + RowWidget.dividerHeight,
        widgets: [
          RowWidget.buildSwitch(
            title: '${I18nKey.advancedEdit.tr}·${I18nKey.network.tr}',
            value: state.webStart,
            set: logic.switchWebForBtn,
          ),
          RowWidget.buildDivider(),
        ],
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
            (index) => buildItem(state.addresses[index].title, state.addresses[index].address, logic.openCredentialDialog),
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
