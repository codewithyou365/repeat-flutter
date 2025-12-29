import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/db/entity/game_user_score.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';
import 'package:repeat_flutter/widget/row/row_widget.dart';
import 'package:repeat_flutter/widget/sheet/sheet.dart';

import 'game_logic.dart';
import 'game_state.dart';
import 'logic/game_settings.dart';

class GamePage<T extends GetxController> {
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
              I18nKey.game.tr,
              state.open,
              logic.switchWeb,
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
                  I18nKey.labelGameRuleSettings.tr,
                  logic.gameTypeToGameSettings.keys.map((gameSettings) {
                    switch (gameSettings) {
                      case GameType.type:
                        return I18nKey.typeGame.tr;
                      case GameType.blankItRight:
                        return I18nKey.blankItRightGame.tr;
                      case GameType.wordSlicer:
                        return I18nKey.workSlicer.tr;
                      case GameType.input:
                        return I18nKey.inputGame.tr;
                      default:
                        return '';
                    }
                  }).toList(),
                  state.game,
                  pickWidth: 150,
                  changed: logic.changeGame,
                ),
                RowWidget.buildDividerWithoutColor(),
                ...gameSettings(logic.gameTypeToGameSettings),
                RowWidget.buildDividerWithoutColor(),
              ],
            );
          },
        ),
      ),
      rate: 1,
    );
  }

  List<Widget> gameSettings(Map<GameType, GameSettings> gameSettings) {
    for (var k in gameSettings.keys) {
      if (GameState.lastGameIndex == k.index) {
        return gameSettings[k]!.build();
      }
    }
    return [];
  }
}
