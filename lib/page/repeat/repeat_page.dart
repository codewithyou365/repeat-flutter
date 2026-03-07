import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/common/list_util.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/kv.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/logic/font_help.dart';
import 'package:repeat_flutter/logic/verse_help.dart';
import 'package:repeat_flutter/logic/widget/close_eyes/close_eyes_panel.dart';
import 'package:repeat_flutter/logic/widget/text_template.dart';
import 'package:repeat_flutter/nav.dart';
import 'package:repeat_flutter/page/editor/editor_args.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';
import 'package:repeat_flutter/widget/select/select.dart';
import 'package:repeat_flutter/widget/text/expandable_text.dart';

import 'repeat_logic.dart';
import 'repeat_state.dart' show RepeatState;
import 'logic/constant.dart';

class RepeatPage extends StatelessWidget {
  RepeatPage({super.key});

  final GlobalKey closeEyeKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: GetBuilder<RepeatLogic>(
        id: RepeatLogic.id,
        builder: (_) {
          return buildCore(context);
        },
      ),
    );
  }

  Widget buildCore(BuildContext context) {
    final logic = Get.find<RepeatLogic>();
    final state = logic.state;
    final Size screenSize = MediaQuery.of(context).size;
    final double topPadding = MediaQuery.of(context).padding.top;
    final double leftPadding = MediaQuery.of(context).padding.left;
    final double inset = MediaQuery.of(context).viewInsets.bottom;
    final double screenWidth = screenSize.width;
    double screenHeight = screenSize.height;
    var landscape = false;
    if (screenWidth > screenHeight) {
      landscape = true;
    }
    state.helper.screenWidth = screenWidth;
    state.helper.screenHeight = screenHeight - inset;
    state.helper.landscape = landscape;
    state.helper.leftPadding = leftPadding;
    state.helper.topPadding = topPadding;
    double topBarHeight = state.helper.topBarHeight;
    state.helper.topBar = () => topBar(logic: logic, height: topBarHeight);
    state.helper.bottomBar = ({required double width}) => bottomBar(logic: logic, width: width, height: state.helper.bottomBarHeight);
    state.helper.text = (QaType type) => text(logic, type);
    state.helper.exerciseArea = () => exerciseArea(logic);
    state.helper.tipArea = () => tipArea(logic);
    state.helper.closeEyesPanel = () => closeEyesPanel(logic);

    if (state.lastLandscape == null || state.lastLandscape != landscape) {
      state.lastLandscape = landscape;
      state.needUpdateSystemUiMode = true;
    }
    if (state.needUpdateSystemUiMode) {
      state.needUpdateSystemUiMode = false;
      if (landscape) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack);
      } else {
        if (state.helper.focusMode.value) {
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack);
        } else {
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.top]);
        }
      }
    }
    String? viewName;
    if (state.helper.initialized) {
      var verse = state.helper.getCurrVerse();
      if (verse != null) {
        var verseShow = VerseHelp.getCache(verse.verseId);
        if (verseShow != null) {
          viewName = state.helper.getCurrViewName();
        }
      }
    }
    if (viewName == null) {
      return dataMissing(state);
    } else {
      return logic.showTypeToRepeatView[viewName]!.body();
    }
  }

  Widget dataMissing(RepeatState state) {
    var helper = state.helper;
    return Column(
      children: [
        SizedBox(
          height: helper.topPadding,
        ),
        SizedBox(
          height: helper.topBarHeight,
          child: Row(
            children: [
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                onPressed: () {
                  Nav.back();
                },
              ),
              const Spacer(),
            ],
          ),
        ),
        SizedBox(height: (helper.screenHeight * 1 / 3) - helper.topBarHeight - helper.topPadding),
        Center(
          child: Text(I18nKey.labelDataMissing.tr),
        ),
      ],
    );
  }

  Widget topBar({required RepeatLogic logic, required double height}) {
    final repeatLogic = logic.repeatLogic;
    final state = logic.state;
    return SizedBox(
      height: height,
      child: Row(
        children: [
          const SizedBox(width: 10),
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () {
              Nav.back();
            },
          ),
          topBarTitle(logic: logic, fontSize: 18),
          const Spacer(),
          if (repeatLogic != null && repeatLogic.step != RepeatStep.recall && state.enableShowRecallButtons)
            IconButton(
              icon: const Icon(Icons.assistant_photo),
              onPressed: logic.adjustProgress,
            ),
          if (repeatLogic != null && repeatLogic.step != RepeatStep.recall && state.enableShowRecallButtons)
            IconButton(
              icon: const Icon(Icons.list_alt),
              tooltip: I18nKey.labelDetail.tr,
              onPressed: logic.openContent,
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: logic.switchShowMode,
                  child: Obx(() {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(I18nKey.showMode.trArgs([state.helper.showMode.value.i18n.tr])),
                        Spacer(),
                      ],
                    );
                  }),
                ),
              ),
              PopupMenuItem<String>(
                onTap: logic.openCloseEyesMode,
                child: Text(I18nKey.closeEyes.tr),
              ),
              PopupMenuItem<String>(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    logic.toggleExerciseMode();
                  },
                  child: Obx(() {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(I18nKey.exercise.tr),
                        const Spacer(),
                        if (state.isExerciseMode.value) const Icon(Icons.check, size: 18, color: Colors.blue),
                      ],
                    );
                  }),
                ),
              ),
              PopupMenuItem<String>(
                onTap: () async {
                  state.helper.stopMedia(false);
                  await logic.gameLogic.open();
                  state.helper.stopMedia(true);
                },
                child: Obx(() {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(I18nKey.game.tr),
                      const Spacer(),
                      if (logic.gameLogic.state.open.value) const Icon(Icons.check, size: 18, color: Colors.blue),
                    ],
                  );
                }),
              ),
              PopupMenuItem<String>(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: logic.switchFocusMode,
                  child: Obx(() {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(I18nKey.btnFocus.tr),
                        const Spacer(),
                        if (state.helper.focusMode.value) const Icon(Icons.check, size: 18, color: Colors.blue),
                      ],
                    );
                  }),
                ),
              ),
              PopupMenuItem<String>(
                onTap: logic.openAdvancedEditor,
                child: Obx(() {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(I18nKey.advancedEdit.tr),
                      const Spacer(),
                      if (logic.bookEditor.state.webStart.value) const Icon(Icons.check, size: 18, color: Colors.blue),
                    ],
                  );
                }),
              ),
            ],
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }

  Widget topBarTitle({required RepeatLogic logic, double? fontSize}) {
    var state = logic.state;
    String text = '';
    if (!state.helper.focusMode.value && logic.repeatLogic != null) {
      text = logic.repeatLogic!.titleLabel;
    }
    return Text(
      text,
      style: fontSize == null ? null : TextStyle(fontSize: fontSize),
    );
  }

  Widget bottomBar({required RepeatLogic logic, required double width, required double height}) {
    final repeatLogic = logic.repeatLogic;
    final leftButtonText = repeatLogic?.leftLabel ?? '';
    final rightButtonText = repeatLogic?.rightLabel ?? '';
    final buttonWidth = width / 2;
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          Row(
            children: [
              bottomBarButton(
                text: leftButtonText,
                onTap: logic.onTapLeft,
                width: buttonWidth,
              ),
              const Spacer(),
              bottomBarButton(
                text: rightButtonText,
                onTap: logic.onTapRight,
                width: buttonWidth,
                onLongPress: logic.onLongTapRight,
              ),
            ],
          ),
          Row(
            children: [
              const Spacer(),
              bottomBarButton(
                text: I18nKey.tips.tr,
                onTap: logic.onTapMiddle,
                width: buttonWidth,
                onLongPress: logic.onLongTapMiddle,
              ),
              const Spacer(),
            ],
          ),
        ],
      ),
    );
  }

  Widget bottomBarButton({
    required String text,
    required VoidCallback onTap,
    double height = 60,
    double? width,
    VoidCallback? onLongPress,
  }) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        width: width,
        height: height,
        alignment: Alignment.center,
        child: Text(text),
      ),
    );
  }

  Widget exerciseArea(RepeatLogic logic) {
    return Obx(() {
      if (!logic.state.isExerciseMode.value) {
        return const SizedBox.shrink();
      }
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        decoration: BoxDecoration(
          color: Colors.grey.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blueAccent.withAlpha(100), width: 1),
        ),
        child: TextField(
          controller: logic.state.helper.exerciseController,
          maxLines: null,
          minLines: 3,
          textInputAction: TextInputAction.newline,
          style: TextStyle(
            fontSize: fontSize(logic, QaType.answer) ?? 17,
            fontFamily: fontAlias(logic, QaType.answer),
          ),
          decoration: InputDecoration(
            hintText: I18nKey.exerciseHint.tr,
            hintStyle: const TextStyle(color: Colors.grey),
            contentPadding: const EdgeInsets.all(12.0),
            border: InputBorder.none,
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear, size: 20, color: Colors.grey),
              onPressed: () {
                logic.state.helper.exerciseController.clear();
              },
            ),
          ),
        ),
      );
    });
  }

  Widget? tipArea(RepeatLogic logic) {
    final helper = logic.state.helper;
    if (helper.tip != TipLevel.tip) {
      return null;
    }
    var map = helper.getCurrVerseMap();

    if (map == null) return null;

    return Obx(() {
      int tabIndex = logic.state.currentTipTabIndex.value;
      bool isTip = tabIndex == 0;
      bool isEditMode = helper.showMode.value == ShowMode.edit;

      String tipText = map[QaType.tip.acronym] ?? I18nKey.labelNoContent.tr;
      String noteText = map[QaType.note.acronym] ?? '';

      String displayText = isTip ? tipText : noteText;

      bool canEdit = isTip ? isEditMode : true;
      final qaType = isTip ? QaType.tip : QaType.note;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Row(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => logic.state.currentTipTabIndex.value = 0,
                child: Text(
                  I18nKey.labelTips.tr,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isTip ? FontWeight.bold : FontWeight.normal,
                    color: isTip ? Colors.blue : Colors.grey,
                  ),
                ),
              ),
              const SizedBox(width: 24),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => logic.state.currentTipTabIndex.value = 1,
                child: Text(
                  I18nKey.labelNote.tr,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: !isTip ? FontWeight.bold : FontWeight.normal,
                    color: !isTip ? Colors.blue : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 16),

          if (displayText.isNotEmpty || canEdit)
            ExpandableText(
              title: "",
              text: displayText,
              style: TextStyle(
                fontSize: fontSize(logic, qaType) ?? 17,
                fontFamily: fontAlias(logic, qaType),
              ),
              onEdit: canEdit
                  ? () async {
                      if (helper.showMode.value != ShowMode.edit && qaType == QaType.note) {
                        await modify(map, logic, qaType);
                      } else {
                        await fullModify(map, logic, qaType);
                      }
                    }
                  : null,
              onTouch: () async {
                final String text = map[qaType.acronym] ?? '';
                if (text.isEmpty) {
                  return;
                }
                helper.stopMedia(false);
                await logic.copyLogic.show(
                  TextTemplateMode.editAndCopy,
                  Get.context!,
                  map[qaType.acronym] ?? '',
                );
                helper.stopMedia(true);
              },
            ),
          const SizedBox(height: 12),
        ],
      );
    });
  }

  Widget? text(RepeatLogic logic, QaType type) {
    var helper = logic.state.helper;
    if (type == QaType.tip) {
      if (helper.showMode.value != ShowMode.edit && //
          helper.tip != TipLevel.tip) {
        return null;
      }
    }
    if (type == QaType.answer) {
      if (helper.showMode.value != ShowMode.edit && //
          helper.step == RepeatStep.recall) {
        return null;
      }
    }
    var edit = helper.showMode.value == ShowMode.edit;
    var map = helper.getCurrVerseMap();
    if (map == null) {
      return null;
    }
    double fontSizeVal = fontSize(logic, type) ?? 17;
    TextStyle? style = TextStyle(
      fontSize: fontSizeVal,
      fontFamily: fontAlias(logic, type),
    );
    String text = map[type.acronym] ?? '';
    return ExpandableText(
      title: "",
      text: text,
      style: style,
      onEdit: edit
          ? () async {
              await fullModify(map, logic, type);
            }
          : null,
      onTouch: () async {
        if (text.isEmpty) {
          return;
        }
        helper.stopMedia(false);
        await logic.copyLogic.show(
          TextTemplateMode.editAndCopy,
          Get.context!,
          text,
        );
        helper.stopMedia(true);
      },
    );
  }

  Future<void> modify(Map<String, dynamic> map, RepeatLogic logic, QaType type) async {
    var helper = logic.state.helper;
    helper.stopMedia(false);

    await Nav.editor.push(
      arguments: EditorArgs(
        title: type.i18n.tr,
        value: map[type.acronym] ?? '',
        save: (str) async {
          map[type.acronym] = str;
          String jsonStr = jsonEncode(map);
          var verseId = helper.getCurrVerse()!.verseId;
          await Db().db.verseDao.updateVerseContent(verseId, jsonStr);
          logic.update([RepeatLogic.id]);
        },
      ),
    );
    helper.stopMedia(true);
  }

  Future<void> fullModify(Map<String, dynamic> map, RepeatLogic logic, QaType type) async {
    var helper = logic.state.helper;
    helper.stopMedia(false);
    String text = map[type.acronym] ?? '';
    var keys = [
      I18nKey.adjustFont.tr,
      I18nKey.editContent.tr,
      I18nKey.expand.tr,
    ];
    if (type == QaType.tip) {
      keys.add(I18nKey.ttsSettings.tr);
    }
    int? index = await Select.showSheet(title: I18nKey.editWhat.trArgs([type.i18n.tr]), keys: keys);
    if (index == null) {
      return;
    }
    if (keys[index] == I18nKey.adjustFont.tr) {
      final verse = helper.getCurrVerse();
      if (verse == null) {
        return;
      }
      final bookMap = helper.getCurrBookMap();
      if (bookMap == null) {
        return;
      }
      logic.adjustFont.open(
        bookId: verse.bookId,
        fontPrefix: type.acronym,
        bookMap: bookMap,
      );
    } else if (keys[index] == I18nKey.editContent.tr) {
      await Nav.editor.push(
        arguments: EditorArgs(
          title: type.i18n.tr,
          value: text,
          save: (str) async {
            map[type.acronym] = str;
            String jsonStr = jsonEncode(map);
            var verseId = helper.getCurrVerse()!.verseId;
            await Db().db.verseDao.updateVerseContent(verseId, jsonStr);
            logic.update([RepeatLogic.id]);
          },
        ),
      );
    } else if (keys[index] == I18nKey.expand.tr) {
      final verse = helper.getCurrVerse();
      if (verse == null) {
        return;
      }
      await logic.expandSheet.open(text, verse, map);
      logic.update([RepeatLogic.id]);
    } else if (keys[index] == I18nKey.ttsSettings.tr) {
      logic.ttsHelper.open();
    }
    helper.stopMedia(true);
  }

  double? fontSize(RepeatLogic logic, QaType type) {
    final helper = logic.state.helper;
    final fontSizeKey = "${type.acronym}${FontHelp.fontSizeSuffix}";
    final val = ListUtil.getValue([
      helper.getCurrBookMap(),
    ], fontSizeKey);
    if (val != null) {
      return double.parse(val);
    }
    return null;
  }

  String? fontAlias(RepeatLogic logic, QaType type) {
    final helper = logic.state.helper;
    final key = "${type.acronym}${FontHelp.fontAliasSuffix}";
    final val = ListUtil.getValue([
      helper.getCurrBookMap(),
    ], key);
    if (val != null) {
      return val as String;
    }
    return null;
  }

  Widget closeEyesPanel(RepeatLogic logic) {
    final helper = logic.state.helper;
    if (logic.state.enableCloseEyesMode.value == CloseEyesModeEnum.none) {
      return SizedBox.shrink();
    } else {
      return CloseEyesPanel.build(
        key: closeEyeKey,
        height: helper.screenHeight,
        width: helper.screenWidth,
        showFinger: true,
        direct: DirectEnum.values[logic.state.closeEyesDirect],
        changeDirect: (DirectEnum direct) {
          logic.state.closeEyesDirect = direct.index;
          Db().db.kvDao.insertOrReplace(Kv(K.closeEyesDirect, "${direct.index}"));
        },
        doubleUpCallback: (int index, int total) {
          if (index == 0) {
            logic.onTapLeft();
          } else if (index == total - 1) {
            logic.onLongTapRight();
          } else if (total >= 4 && index == 2) {
            logic.onLongTapMiddle();
          } else {
            logic.onTapMiddle();
          }
          HapticFeedback.lightImpact();
        },
        close: () {
          logic.state.enableCloseEyesMode.value = CloseEyesModeEnum.none;
        },
        help: () {
          MsgBox.tips(desc: I18nKey.closeEyesTips.tr);
        },
      );
    }
  }
}
