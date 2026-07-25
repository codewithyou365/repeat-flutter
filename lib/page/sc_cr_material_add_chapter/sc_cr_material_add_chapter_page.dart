import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/chapter_import_help.dart';

import 'sc_cr_material_add_chapter_logic.dart';

class ScCrMaterialAddChapterPage extends StatelessWidget {
  const ScCrMaterialAddChapterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<ScCrMaterialAddChapterLogic>();
    final state = logic.state;
    return Scaffold(
      appBar: AppBar(
        title: Text(I18nKey.labelAddChapter.tr),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _buildSource(
            context,
            title: I18nKey.labelChapterMedia.tr,
            controller: state.mediaController,
            source: state.mediaSource,
            pick: logic.pickMedia,
            scan: logic.scanMedia,
          ),
          const SizedBox(height: 24),
          _buildSource(
            context,
            title: I18nKey.labelChapterSrt.tr,
            controller: state.srtController,
            source: state.srtSource,
            pick: logic.pickSrt,
            scan: logic.scanSrt,
          ),
          const SizedBox(height: 32),
          Obx(() {
            var value = state.indexTotal.value == 0 ? 0.0 : state.indexCount.value / state.indexTotal.value;
            return LinearProgressIndicator(
              value: value,
              semanticsLabel: "${(value * 100).toStringAsFixed(1)}%",
            );
          }),
          const SizedBox(height: 8),
          Obx(() {
            return LinearProgressIndicator(
              value: state.contentProgress.value,
              semanticsLabel: "${(state.contentProgress.value * 100).toStringAsFixed(1)}%",
            );
          }),
          const SizedBox(height: 32),
          Obx(() {
            return SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: state.importing.value ? null : logic.submit,
                child: Text(I18nKey.btnAdd.tr),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSource(
    BuildContext context, {
    required String title,
    required TextEditingController controller,
    required RxString source,
    required VoidCallback pick,
    required VoidCallback scan,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          onChanged: (v) => source.value = v,
          decoration: InputDecoration(
            hintText: I18nKey.labelLocalPathOrUrl.tr,
          ),
        ),
        // The buttons get their own row, so the input stays uncluttered.
        Row(
          children: [
            TextButton.icon(
              onPressed: pick,
              icon: const Icon(Icons.folder_open),
              label: Text(I18nKey.btnSelectFile.tr),
            ),
            TextButton.icon(
              onPressed: scan,
              icon: const Icon(Icons.qr_code_scanner),
              label: Text(I18nKey.scan.tr),
            ),
            const Spacer(),
            Obx(() {
              if (source.value.trim().isEmpty) {
                return const SizedBox.shrink();
              }
              var remote = ChapterImportHelp.isUrl(source.value.trim());
              return Text(
                remote ? I18nKey.labelSourceRemote.tr : I18nKey.labelSourceLocal.tr,
                style: Theme.of(context).textTheme.bodySmall,
              );
            }),
          ],
        ),
      ],
    );
  }
}
