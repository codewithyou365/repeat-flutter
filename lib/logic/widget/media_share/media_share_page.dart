import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/widget/qr/lan_address_qr_code.dart';
import 'package:repeat_flutter/widget/row/row_widget.dart';
import 'package:repeat_flutter/widget/sheet/sheet.dart';

import 'media_share_logic.dart';

class MediaSharePage {
  Future<void> open(MediaShareLogic logic) {
    var context = Get.context!;
    final state = logic.state;
    return Sheet.showBottomSheet(
      context,
      head: SheetHead(
        widgets: [
          Column(
            children: [
              RowWidget.buildSwitch(
                title: I18nKey.mediaShare.tr,
                value: state.webStart,
                set: logic.switchWebForBtn,
              ),
              RowWidget.buildDivider(),
            ],
          ),
        ],
        height: RowWidget.rowHeight + RowWidget.dividerHeight,
      ),
      _buildList(context, logic),
    );
  }

  Widget _buildList(BuildContext context, MediaShareLogic logic) {
    final state = logic.state;
    return Obx(() {
      List<Widget> items = [
        RowWidget.buildSwitch(
          title: I18nKey.enableSsl.tr,
          value: state.enableSsl,
          disabled: state.webStart,
        ),
        RowWidget.buildDivider(),
      ];
      items.add(
        LanAddressQrCode(
          addresses: List.generate(state.addressesLength.value, (i) => state.addresses[i].address),
        ),
      );
      return ListView(children: items);
    });
  }
}
