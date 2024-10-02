import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';

import 'gs_cr_content_share_logic.dart';

class GsCrContentSharePage extends StatelessWidget {
  const GsCrContentSharePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<GsCrContentShareLogic>();
    return Scaffold(
      appBar: AppBar(
        title: Text(I18nKey.contentShare.tr),
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
    return ListView(
      children: List.generate(
        state.addresses.length,
        (index) => buildItem(state.addresses[index].title, state.addresses[index].address),
      ),
    );
  }

  Widget buildItem(String itemLabel, String desc) {
    return Card(
      child: InkWell(
        onTap: () => {
          MsgBox.yesWithQrCode(
            itemLabel,
            desc,
            desc,
          )
        },
        child: ListTile(
          title: Text(itemLabel),
          subtitle: Padding(
            padding: EdgeInsets.all(16.w),
            child: Text(desc),
          ),
        ),
      ),
    );
  }
}
