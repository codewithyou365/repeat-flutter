import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/widget/qr/lan_address_qr_code.dart';
import 'package:repeat_flutter/widget/row/row_widget.dart';

import 'sc_cr_material_edit_logic.dart';

class ScCrMaterialEditPage extends StatelessWidget {
  const ScCrMaterialEditPage({super.key});

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<ScCrMaterialEditLogic>();
    return Scaffold(
      appBar: AppBar(
        title: Text(I18nKey.advancedEdit.tr),
      ),
      body: GetBuilder<ScCrMaterialEditLogic>(
        id: ScCrMaterialEditLogic.id,
        builder: (_) => _buildList(logic),
      ),
    );
  }

  Widget _buildList(ScCrMaterialEditLogic logic) {
    final state = logic.editor.state;
    return ListView(
      children: [
        RowWidget.buildDivider(),
        RowWidget.buildSwitch(
          title: I18nKey.web.tr,
          value: state.webStart,
          set: logic.editor.switchWebForBtn,
        ),
        RowWidget.buildDividerWithoutColor(),
        if (state.addresses.isNotEmpty)
          LanAddressQrCode(
            addresses: state.addresses.map((e) => e.address).toList(),
            onKey: logic.editor.openCredentialDialog,
          ),
      ],
    );
  }
}
