import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/nav.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';
import 'package:repeat_flutter/widget/select/select.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

import 'game_list_help.dart';
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
        title: Text(I18nKey.manageSubscription.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: I18nKey.subscriptionHelp.tr,
            onPressed: () => Get.to(() => const GameListHelpPage()),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: I18nKey.gameCheckUpdate.tr,
            onPressed: logic.checkUpdates,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: logic.add,
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            tooltip: I18nKey.gameManageSubscription.tr,
            onPressed: () => _manageSubscriptions(logic),
          ),
        ],
      ),
      body: Obx(() {
        if (state.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.items.isEmpty && state.tipServices.isEmpty) {
          return Center(child: Text(I18nKey.gameEmpty.tr));
        }
        // 游戏和提示服务分两组：提示服务不能当游戏开，只是给提示字段挑的目录。
        return ListView(
          children: [
            if (state.items.isNotEmpty) _header(context, I18nKey.gameSectionGame.tr),
            for (final item in state.items) ...[
              _gameTile(context, logic, item),
              const Divider(height: 1),
            ],
            if (state.tipServices.isNotEmpty) _header(context, I18nKey.gameSectionTip.tr),
            for (final item in state.tipServices) ...[
              _tipServiceTile(context, item),
              const Divider(height: 1),
            ],
          ],
        );
      }),
    );
  }

  static Widget _header(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }

  Widget _gameTile(BuildContext context, GameListLogic logic, GameItem item) {
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
        _subtitle(item),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _openActions(logic, item),
    );
  }

  /// 提示服务没有可改的东西（名字、入口都跟着订阅走），只展示。
  Widget _tipServiceTile(BuildContext context, TipServiceItem item) {
    final broken = !item.unpacked;
    final from = item.subName.isEmpty ? item.subUrl : item.subName;
    final status = broken ? I18nKey.gameNotUnpacked.tr : I18nKey.gameReady.tr;
    return ListTile(
      leading: Icon(
        Icons.tips_and_updates,
        color: broken ? Theme.of(context).disabledColor : null,
      ),
      title: Text(
        item.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: broken ? TextStyle(color: Theme.of(context).disabledColor) : null,
      ),
      subtitle: Text(
        '${item.service} · $status · ${I18nKey.gameFromSubscription.trArgs(['$from v${item.subVersion}'])}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  static String _status(GameItem item) {
    if (!item.zipExists) return I18nKey.gameZipMissing.tr;
    if (!item.unpacked) return I18nKey.gameNotUnpacked.tr;
    return I18nKey.gameReady.tr;
  }

  /// 入口 js · 状态[· 来自 <订阅名> v<版本>]
  static String _subtitle(GameItem item) {
    final ret = StringBuffer('${item.service} · ${_status(item)}');
    if (item.fromSubscription) {
      final from = item.subName.isEmpty ? item.subUrl : item.subName;
      ret.write(' · ${I18nKey.gameFromSubscription.trArgs(['$from v${item.subVersion}'])}');
    }
    return ret.toString();
  }

  /// 订阅列表：选中一条再挑改地址/改名/退订。（不新增页面，全在这一页里解决。）
  ///
  /// 版本和 hash 是装包时记下的，不给改；想重装直接点检查更新。
  void _manageSubscriptions(GameListLogic logic) async {
    final subs = logic.state.subscriptions.toList();
    if (subs.isEmpty) {
      Snackbar.show(I18nKey.gameSubscriptionEmpty.tr);
      return;
    }
    final index = await Select.showSheet(
      title: I18nKey.gameManageSubscription.tr,
      keys: subs.map((e) => '${e.name.isEmpty ? e.url : e.name} v${e.version}').toList(),
    );
    if (index == null) return;
    final sub = subs[index];
    final action = await Select.showSheet(
      // 标题放地址，改之前能看到现在填的是什么。
      title: sub.url,
      keys: [
        I18nKey.gameSubscriptionUrl.tr,
        I18nKey.gameSubscriptionName.tr,
        I18nKey.gameUnsubscribe.tr,
      ],
    );
    if (action == null) return;
    switch (action) {
      case 0:
        final RxString model = sub.url.obs;
        MsgBox.strInputWithYesOrNo(
          model,
          I18nKey.gameSubscriptionUrl.tr,
          null,
          qrPagePath: Nav.scan.path,
          yes: () {
            Get.back();
            logic.changeSubscriptionUrl(sub, model.value);
          },
        );
        break;
      case 1:
        _strInput(sub.name, I18nKey.gameSubscriptionName.tr, (v) => logic.renameSubscription(sub, v));
        break;
      case 2:
        MsgBox.yesOrNo(
          title: I18nKey.gameUnsubscribe.tr,
          desc: I18nKey.gameUnsubscribeConfirm.tr,
          yes: () {
            Get.back();
            logic.unsubscribe(sub);
          },
        );
        break;
    }
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
