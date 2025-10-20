import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';
import 'package:repeat_flutter/widget/row/row_widget.dart';

import 'sc_cr_material_share_logic.dart';

class ScCrContentSharePage extends StatelessWidget {
  const ScCrContentSharePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<ScCrMaterialShareLogic>();
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
      body: GetBuilder<ScCrMaterialShareLogic>(
        id: ScCrMaterialShareLogic.id,
        builder: (_) => _buildList(context, logic),
      ),
    );
  }

  Widget _buildList(BuildContext context, ScCrMaterialShareLogic logic) {
    final state = logic.state;
    return ListView(
      children: [
        buildItem(
          state.original.title,
          state.original.address,
          "",
          false.obs,
          null,
        ),
        RowWidget.buildDividerWithoutColor(),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: RowWidget.buildSwitch(I18nKey.web.tr, state.webStart, logic.switchWeb),
        ),
        RowWidget.buildDividerWithoutColor(),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: RowWidget.buildSwitch(I18nKey.labelDoYourShareTheNotes.tr, state.shareNote),
        ),
        if (state.addresses.isNotEmpty)
          ...List.generate(
            state.addresses.length,
            (index) => buildItem(
              state.addresses[index].title,
              state.addresses[index].address,
              "#${state.user.value}:${state.password.value}",
              state.shareNote,
              logic.randCredentials,
            ),
          ),
      ],
    );
  }

  Widget buildItem(String itemLabel, String desc, String credentials, RxBool shareNote, VoidCallback? key) {
    var withCredentials = "$desc$credentials";
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Card(
        child: InkWell(
          onTap: () {
            MsgBox.noWithQrCode(
              itemLabel,
              withCredentials,
              withCredentials,
            );
          },
          child: ListTile(
            title: Obx(() {
              return Row(
                children: [
                  Text(itemLabel),
                  const Spacer(),
                  if (shareNote.value) Text(I18nKey.labelSharingNotes.tr),
                  if (key != null)
                    IconButton(
                      icon: const Icon(Icons.key),
                      onPressed: key,
                    ),
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
