import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';
import 'package:repeat_flutter/widget/row/row_widget.dart';
import 'package:repeat_flutter/widget/sheet/sheet.dart';

import 'media_share_logic.dart';

class MediaSharePage {
  Future<void> open(MediaShareLogic logic) {
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
              title: I18nKey.mediaShare.tr,
              value: state.webStart,
              set: logic.switchWeb,
            ),
            RowWidget.buildDivider(),
          ],
        ),
      ),
      _buildList(context, logic),
    );
  }

  Widget _buildList(BuildContext context, MediaShareLogic logic) {
    final state = logic.state;
    return Obx(() {
      List<Widget> items = [];
      for (var i = 0; i < state.addressesLength.value; i++) {
        items.add(buildItem(state.addresses[i].title, state.addresses[i].address));
      }
      return ListView(children: items);
    });
  }

  Widget buildItem(String itemLabel, String desc) {
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
