import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/widget/qr/lan_address_qr_code.dart';
import 'package:repeat_flutter/widget/row/row_widget.dart';

import 'sc_share_logic.dart';

class ScSharePage extends StatelessWidget {
  const ScSharePage({super.key});

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<ScShareLogic>();
    return Scaffold(
      appBar: AppBar(
        title: Text(I18nKey.classroomShare.tr),
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
      body: GetBuilder<ScShareLogic>(
        id: ScShareLogic.id,
        builder: (_) => _buildList(context, logic),
      ),
    );
  }

  Widget _buildList(BuildContext context, ScShareLogic logic) {
    final state = logic.state;
    return ListView(
      children: [
        RowWidget.buildDivider(),
        RowWidget.buildSwitch(
          title: I18nKey.labelDoYourShareTheNotes.tr,
          value: state.shareNote,
        ),
        RowWidget.buildDividerWithoutColor(),
        RowWidget.buildSwitch(
          title: I18nKey.web.tr,
          value: state.webStart,
          set: logic.switchWeb,
        ),
        if (state.addresses.isNotEmpty)
          Obx(() {
            var credentials = "#${state.user.value}:${state.password.value}";
            return LanAddressQrCode(
              addresses: state.addresses.map((e) => "${e.address}$credentials").toList(),
              trailing: state.shareNote.value ? Text(I18nKey.labelSharingNotes.tr) : null,
              onKey: logic.randCredentials,
            );
          }),
      ],
    );
  }
}
