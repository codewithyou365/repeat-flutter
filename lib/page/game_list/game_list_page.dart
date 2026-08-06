import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';
import 'package:repeat_flutter/widget/select/select.dart';

import 'game_list_item.dart';
import 'game_list_logic.dart';

class GameListPage extends StatelessWidget {
  const GameListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<GameListLogic>();
    final state = logic.state;
    return Scaffold(
      appBar: AppBar(
        title: Text(I18nKey.manageGame.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: logic.add,
          ),
        ],
      ),
      body: Obx(() {
        if (state.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.items.isEmpty) {
          return Center(child: Text(I18nKey.gameEmpty.tr));
        }
        return ListView.separated(
          itemCount: state.items.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final item = state.items[index];
            final broken = !item.unpacked;
            return ListTile(
              leading: Icon(
                Icons.videogame_asset,
                color: broken ? Theme.of(context).disabledColor : null,
              ),
              title: Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: broken ? TextStyle(color: Theme.of(context).disabledColor) : null,
              ),
              subtitle: Text(
                '${item.service} · ${_status(item)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _openActions(logic, item),
            );
          },
        );
      }),
    );
  }

  static String _status(GameItem item) {
    if (!item.zipExists) return I18nKey.gameZipMissing.tr;
    if (!item.unpacked) return I18nKey.gameNotUnpacked.tr;
    return I18nKey.gameReady.tr;
  }

  void _openActions(GameListLogic logic, GameItem item) async {
    final index = await Select.showSheet(
      title: item.name,
      keys: [
        I18nKey.gameName.tr,
        I18nKey.gameKey.tr,
        I18nKey.gameService.tr,
        I18nKey.gameReplaceZip.tr,
        I18nKey.btnDelete.tr,
      ],
    );
    if (index == null) return;
    switch (index) {
      case 0:
        _strInput(item.name, I18nKey.gameName.tr, (v) => logic.rename(item, v));
        break;
      case 1:
        _strInput(item.key, I18nKey.gameKey.tr, (v) => logic.setKey(item, v));
        break;
      case 2:
        _pickService(logic, item);
        break;
      case 3:
        logic.replaceZip(item);
        break;
      case 4:
        MsgBox.yesOrNo(
          title: I18nKey.btnDelete.tr,
          desc: I18nKey.gameDeleteConfirm.tr,
          yes: () {
            Get.back();
            logic.delete(item);
          },
        );
        break;
    }
  }

  /// 入口 js 能从解压目录里扫出来就让用户挑，扫不到（没解压/没有顶层 js）回落到手填。
  void _pickService(GameListLogic logic, GameItem item) async {
    final files = await logic.listJsFiles(item);
    if (files.isEmpty) {
      _strInput(item.service, I18nKey.gameService.tr, (v) => logic.setService(item, v));
      return;
    }
    final index = await Select.showSheet(title: I18nKey.gameService.tr, keys: files);
    if (index == null) return;
    logic.setService(item, files[index]);
  }

  void _strInput(String value, String title, void Function(String) onOk) {
    final RxString model = value.obs;
    MsgBox.strInputWithYesOrNo(
      model,
      title,
      null,
      yes: () {
        Get.back();
        onOk(model.value);
      },
    );
  }
}
