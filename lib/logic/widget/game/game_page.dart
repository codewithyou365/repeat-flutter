import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/widget/game/game_state.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';
import 'package:repeat_flutter/widget/row/row_widget.dart';
import 'package:repeat_flutter/widget/sheet/sheet.dart';

import 'game_logic.dart';

class GamePage<T extends GetxController> {
  Key userIndexKey = GlobalKey();

  Future<void> open(GameLogic<T> logic) async {
    var state = logic.state;
    return Sheet.withHeaderAndBody(
      Get.context!,
      Padding(
        key: GlobalKey(),
        padding: EdgeInsets.symmetric(horizontal: 10.0.w, vertical: 0.0),
        child: Column(
          children: [
            RowWidget.buildSwitch(
              title: I18nKey.game.tr,
              value: state.open,
              set: logic.switchWebForBtn,
            ),
            RowWidget.buildDivider(),
          ],
        ),
      ),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.0.w, vertical: 0.0),
        child: GetBuilder<T>(
          id: GameLogic.bodyId,
          builder: (_) {
            return ListView(
              children: [
                Obx(() {
                  return Column(
                    children: [
                      ...List.generate(
                        state.open.value ? state.urls.length : 0,
                        (index) => Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Card(
                            color: Theme.of(Get.context!).secondaryHeaderColor,
                            child: InkWell(
                              onTap: () => {
                                MsgBox.noWithQrCode(
                                  I18nKey.labelLanAddress.tr,
                                  state.urls[index],
                                  state.urls[index],
                                ),
                              },
                              child: ListTile(
                                title: Row(
                                  children: [
                                    Text('${I18nKey.labelLanAddress.tr}-${index + 1}'),
                                    const Spacer(),
                                    IconButton(
                                      icon: const Icon(Icons.key),
                                      onPressed: logic.openCredentialDialog,
                                      padding: EdgeInsets.zero,
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.play_arrow),
                                      onPressed: logic.openWebview,
                                      padding: EdgeInsets.zero,
                                    ),
                                  ],
                                ),
                                subtitle: Padding(
                                  padding: EdgeInsets.all(16.w),
                                  child: Text(state.urls[index]),
                                ),
                              ),
                            ),
                          ),
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
                RowWidget.buildCupertinoPicker(
                  title: I18nKey.labelGameRuleSettings.tr,
                  options: logic.listGameNames(),
                  value: GameState.game?.id ?? 0,
                  pickWidth: 150,
                  changed: logic.changeGame,
                  disabled: state.open,
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
                    title: I18nKey.editor.tr,
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
      ),
      rate: 1,
    );
  }
}
