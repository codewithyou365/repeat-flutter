import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';
import 'package:repeat_flutter/widget/row/row_widget.dart';

import 'gs_cr_content_share_logic.dart';

class GsCrContentSharePage extends StatelessWidget {
  const GsCrContentSharePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<GsCrContentShareLogic>();
    return Scaffold(
      appBar: AppBar(
        title: Text(I18nKey.bookShare.tr),
        actions: <Widget>[
          Padding(
            padding: EdgeInsets.all(8.0.w),
            child: IconButton(
              icon: const Icon(Icons.save),
              onPressed: logic.onSave,
            ),
          ),
        ],
      ),
      body: GetBuilder<GsCrContentShareLogic>(
        id: GsCrContentShareLogic.id,
        builder: (_) => _buildList(context, logic),
      ),
    );
  }

  Widget _buildList(BuildContext context, GsCrContentShareLogic logic) {
    final state = logic.state;
    return ListView(children: [
      buildItem(
        state.addresses[0].title,
        state.addresses[0].address,
        false.obs,
      ),
      if (state.addresses.length > 1)
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: RowWidget.buildSwitch(I18nKey.labelDoYourShareTheNotes.tr, state.shareNote),
        ),
      if (state.addresses.length > 1)
        ...List.generate(
          state.addresses.length - 1,
          (index) => buildItem(
            state.addresses[index + 1].title,
            state.addresses[index + 1].address,
            state.shareNote,
          ),
        )
    ]);
  }

  Widget buildItem(String itemLabel, String desc, RxBool shareNote) {
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
            title: Obx(() {
              return Row(
                children: [
                  Text(itemLabel),
                  const Spacer(),
                  if (shareNote.value) Text(I18nKey.labelSharingNotes.tr),
                ],
              );
            }),
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
