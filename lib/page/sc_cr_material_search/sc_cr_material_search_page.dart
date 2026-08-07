import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/model/book_content.dart';
import 'package:repeat_flutter/logic/model/verse_pos.dart';
import 'package:repeat_flutter/logic/model/verse_show.dart';
import 'package:repeat_flutter/page/content/logic/helper.dart';
import 'package:repeat_flutter/widget/app_bar/app_bar_widget.dart';

import 'sc_cr_material_search_logic.dart';

class ScCrMaterialSearchPage extends StatelessWidget {
  const ScCrMaterialSearchPage({Key? key}) : super(key: key);

  static const int previewMaxLength = 60;

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<ScCrMaterialSearchLogic>();
    final state = logic.state;
    return Scaffold(
      appBar: AppBar(
        title: Helper.getTextField(
          controller: state.searchController,
          focusNode: state.searchFocusNode,
          onSubmitted: logic.doSearch,
          onChanged: logic.onSearchChanged,
        ),
        actions: AppBarWidget.buildAppBarAction([
          PopupMenuItem<String>(
            onTap: logic.rebuildManually,
            child: Text(I18nKey.labelRebuildIndex.tr),
          ),
        ]),
      ),
      body: Obx(() {
        if (state.indexing.value) {
          return buildIndexing(logic);
        }
        if (state.resultIds.isEmpty) {
          return Center(
            child: Text(state.searched.value ? I18nKey.labelNoSearchResult.tr : ''),
          );
        }
        // 骨架是 id 列表，正文按滚动位置从窗口里现取；GetBuilder 负责补齐后重画
        return GetBuilder<ScCrMaterialSearchLogic>(
          id: ScCrMaterialSearchLogic.id,
          builder: (_) {
            return ListView.separated(
              itemCount: state.resultIds.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final verse = logic.verseAt(index);
                if (verse == null) {
                  return const ListTile(title: Text(''));
                }
                return ListTile(
                  title: Text(versePos(logic.bookNames[verse.bookId] ?? '', verse.chapterIndex, verse.verseIndex)),
                  subtitle: Text(
                    preview(verse),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => logic.openVerse(index),
                );
              },
            );
          },
        );
      }),
    );
  }

  Widget buildIndexing(ScCrMaterialSearchLogic logic) {
    final state = logic.state;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(I18nKey.labelBuildingIndex.tr),
            const SizedBox(height: 20),
            LinearProgressIndicator(
              value: state.indexDone.value / state.indexTotal.value,
            ),
          ],
        ),
      ),
    );
  }

  /// 命中条目的正文预览：优先问题，没有就用答案。
  String preview(VerseShow verse) {
    String? text;
    try {
      var content = VerseContent.fromJson(jsonDecode(verse.verseContent));
      text = content.question;
      if (text == null || text.isEmpty) {
        text = content.answer;
      }
    } catch (_) {
      text = null;
    }
    if (text == null || text.isEmpty) {
      return '';
    }
    text = text.replaceAll('\n', ' ');
    if (text.length > previewMaxLength) {
      return '${text.substring(0, previewMaxLength)}...';
    }
    return text;
  }
}
