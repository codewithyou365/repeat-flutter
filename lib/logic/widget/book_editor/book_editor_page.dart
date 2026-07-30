import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/widget/qr/lan_address_qr_code.dart';
import 'package:repeat_flutter/widget/row/row_widget.dart';
import 'package:repeat_flutter/widget/sheet/sheet.dart';

import 'book_editor_logic.dart';

class BookEditorPage<T extends GetxController> {
  Future<void> open(BookEditorLogic<T> logic) {
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
            title: I18nKey.advancedEdit.tr,
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
        LanAddressQrCode(
          addresses: state.addresses.map((e) => e.address).toList(),
          onKey: logic.openCredentialDialog,
        ),
      ],
    );
  }
}
