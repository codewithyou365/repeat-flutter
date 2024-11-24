import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';

import 'gs_cr_content_template_logic.dart';

class GsCrContentTemplatePage extends StatelessWidget {
  const GsCrContentTemplatePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<GsCrContentTemplateLogic>();
    return Scaffold(
      appBar: AppBar(
        title: Text(I18nKey.mediaImportTemplate.tr),
      ),
      body: GetBuilder<GsCrContentTemplateLogic>(
        id: GsCrContentTemplateLogic.id,
        builder: (_) => _buildList(context, logic),
      ),
    );
  }

  Widget _buildList(BuildContext context, GsCrContentTemplateLogic logic) {
    final state = logic.state;
    return ListView(
      children: List.generate(
        state.items.length,
        (index) => buildItem(state.items[index], logic),
      ),
    );
  }

  Widget buildItem(String content, GsCrContentTemplateLogic logic) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Card(
        child: InkWell(
          onTap: () => logic.onSave(content),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(content),
          ),
        ),
      ),
    );
  }
}
