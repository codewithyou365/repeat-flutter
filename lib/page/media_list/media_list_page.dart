import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';

import 'media_item.dart';
import 'media_list_logic.dart';
import 'media_list_player.dart';

class MediaListPage extends StatelessWidget {
  const MediaListPage({Key? key}) : super(key: key);

  IconData _iconOf(MediaKind kind) {
    switch (kind) {
      case MediaKind.audio:
        return Icons.audiotrack;
      case MediaKind.video:
        return Icons.movie;
      case MediaKind.image:
        return Icons.image;
      case MediaKind.unknown:
        return Icons.insert_drive_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<MediaListLogic>();
    final state = logic.state;
    return Scaffold(
      appBar: AppBar(
        title: Text(I18nKey.mediaList.tr),
        actions: [
          Obx(() {
            final onlyNamed = state.onlyNamed.value;
            return IconButton(
              icon: Icon(onlyNamed ? Icons.filter_alt : Icons.filter_alt_off),
              tooltip: onlyNamed ? I18nKey.mediaOnlyNamed.tr : I18nKey.mediaShowAll.tr,
              onPressed: logic.toggleOnlyNamed,
            );
          }),
        ],
      ),
      body: Obx(() {
        if (state.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.items.isEmpty) {
          return Center(child: Text(I18nKey.mediaEmpty.tr));
        }
        return ListView.separated(
          itemCount: state.items.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final item = state.items[index];
            final missing = !item.exists;
            return ListTile(
              leading: Icon(
                _iconOf(item.kind),
                color: missing ? Theme.of(context).disabledColor : null,
              ),
              title: Text(
                item.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: missing ? TextStyle(color: Theme.of(context).disabledColor) : null,
              ),
              subtitle: missing ? Text(I18nKey.mediaFileNotExist.tr) : null,
              trailing: IconButton(
                icon: const Icon(Icons.drive_file_rename_outline),
                onPressed: () => _renameDialog(logic, item),
              ),
              onTap: () {
                if (missing) {
                  MsgBox.yes(I18nKey.labelTips.tr, I18nKey.mediaFileNotExist.tr);
                  return;
                }
                Get.to(() => MediaPlayerScreen(items: state.items.toList(), startIndex: index));
              },
            );
          },
        );
      }),
    );
  }

  void _renameDialog(MediaListLogic logic, MediaItem item) {
    final RxString model = item.displayName.obs;
    MsgBox.strInputWithYesOrNo(
      model,
      I18nKey.mediaRename.tr,
      null,
      yes: () {
        Get.back();
        logic.rename(item, model.value);
      },
    );
  }
}
