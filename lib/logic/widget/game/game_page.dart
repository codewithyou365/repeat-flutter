import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/widget/webview/webview_args.dart';
import 'package:repeat_flutter/widget/row/row_widget.dart';
import 'package:repeat_flutter/widget/sheet/sheet.dart';

import 'game_logic.dart';

class GamePage<T extends GetxController> {
  Key userIndexKey = GlobalKey();

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool enabled,
  }) {
    final color = enabled ? null : Colors.grey;
    return RowWidget.buildCard(
      InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16.w),
          child: Column(
            children: [
              Icon(icon, size: 32.w, color: color),
              SizedBox(height: 8.w),
              Text(title, style: TextStyle(fontSize: 16, color: color)),
            ],
          ),
        ),
      ),
    );
  }

  Future<WebviewArgs?> open(GameLogic<T> logic) async {
    var state = logic.state;
    return await Sheet.showBottomSheet<WebviewArgs?>(
      Get.context!,
      head: SheetHead(
        height: RowWidget.rowHeight + RowWidget.dividerHeight,
        widgets: [
          RowWidget.buildSwitch(
            title: I18nKey.gameWeb.tr,
            value: state.open,
            set: logic.switchWebForBtn,
          ),
          RowWidget.buildDivider(),
        ],
      ),
      GetBuilder<T>(
        id: GameLogic.bodyId,
        builder: (_) {
          return ListView(
            children: [
              Obx(() {
                final enabled = state.open.value && state.urls.isNotEmpty;
                return Row(
                  children: [
                    Expanded(
                      child: _buildActionCard(
                        icon: Icons.play_arrow,
                        title: I18nKey.startPlaying.tr,
                        onTap: logic.openWebview,
                        enabled: enabled,
                      ),
                    ),
                    Expanded(
                      child: _buildActionCard(
                        icon: Icons.qr_code_2,
                        title: I18nKey.shareAddress.tr,
                        onTap: logic.openShareDialog,
                        enabled: enabled,
                      ),
                    ),
                  ],
                );
              }),
              Obx(() {
                return RowWidget.buildTextWithEdit(
                  I18nKey.labelOnlineUserNumber.tr,
                  state.online,
                  onTap: () async {
                    await logic.userManager.show(Get.context!);
                    state.online.value = logic.getOnline();
                  },
                );
              }),
              RowWidget.buildDividerWithoutColor(),
              Obx(() {
                return RowWidget.buildCupertinoPicker(
                  title: I18nKey.game.tr,
                  options: logic.listGameNames(),
                  value: state.lastGameIndex.value,
                  pickWidth: 150,
                  changed: logic.changeGame,
                  disabled: state.open,
                );
              }),

              RowWidget.buildDividerWithoutColor(),
              RowWidget.buildSwitch(
                title: I18nKey.adminModel.tr,
                value: state.adminEnableRx,
                disabled: state.open,
                set: logic.setAdminEnable,
              ),
              RowWidget.buildDividerWithoutColor(),
              Obx(() {
                List<String> userNames = [];
                for (var i = 0; i < state.userNumber.value; i++) {
                  final user = state.users[i];
                  userNames.add('${user.name}(${state.userIdToScore[user.id!] ?? 0})');
                }
                return RowWidget.buildCupertinoPicker(
                  key: userIndexKey,
                  title: I18nKey.admin.tr,
                  options: userNames,
                  value: state.userIndex.value,
                  changed: logic.setUser,
                  disabled: state.open,
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
