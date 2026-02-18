import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/kv.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/logic/verse_help.dart';
import 'package:repeat_flutter/logic/widget/close_eyes/close_eyes_panel.dart';
import 'package:repeat_flutter/nav.dart';
import 'package:repeat_flutter/page/editor/editor_args.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';
import 'package:repeat_flutter/widget/select/select.dart';
import 'package:repeat_flutter/widget/text/text_button.dart';

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
    final double screenWidth = screenSize.width;
    double screenHeight = screenSize.height;
    var landscape = false;
    if (screenWidth > screenHeight) {
      landscape = true;
    }
    state.helper.screenWidth = screenWidth;
    state.helper.screenHeight = screenHeight;
    state.helper.landscape = landscape;
    state.helper.leftPadding = leftPadding;
    state.helper.topPadding = topPadding;
    double topBarHeight = state.helper.topBarHeight;
    state.helper.topBar = () => topBar(logic: logic, height: topBarHeight);
    state.helper.bottomBar = ({required double width}) => bottomBar(logic: logic, width: width, height: state.helper.bottomBarHeight);
    state.helper.text = (QaType type) => text(logic, type);
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
          IconButton(
            icon: const Icon(Icons.note_alt_outlined),
            onPressed: logic.editNote,
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
                onTap: () async {
                  state.helper.stopMedia(false);
                  await logic.gameLogic.open();
                  state.helper.stopMedia(true);
                },
                child: Text(logic.gameLogic.title),
              ),
              PopupMenuItem<String>(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: logic.switchFocusMode,
                  child: Obx(() {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("${I18nKey.btnFocus.tr}(${state.helper.focusMode.value})"),
                        Spacer(),
                      ],
                    );
                  }),
                ),
              ),
              PopupMenuItem<String>(
                onTap: logic.openAdvancedEditor,
                child: Text(logic.bookEditor.title),
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
    final helper = logic.state.helper;
    var m = helper.getCurrVerseMap();
    String? tip;
    if (m != null) {
      tip = m[QaType.tip.acronym];
    }
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
          if (tip != null && tip.isNotEmpty)
            Row(
              children: [
                const Spacer(),
                bottomBarButton(
                  text: I18nKey.btnTips.tr,
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
    double fontSizeVal = textFontSize(logic, type) ?? 17;
    TextStyle? style = TextStyle(fontSize: fontSizeVal);
    if (edit) {
      String text = map[type.acronym] ?? '';
      String editText = '${type.i18n.tr}:$text';
      return MyTextButton.build(
        () async {
          helper.stopMedia(false);
          var keys = [
            I18nKey.adjustFontSize.trArgs(['$fontSizeVal']),
            I18nKey.editContent.tr,
          ];
          if (type == QaType.tip) {
            keys.add(I18nKey.ttsSettings.tr);
          }
          int? index = await Select.showSheet(title: I18nKey.edit.tr, keys: keys);
          if (index == null) {
            return;
          }
          if (keys[index] == I18nKey.editContent.tr) {
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
          } else if (keys[index] == I18nKey.ttsSettings.tr) {
            logic.ttsHelper.open();
          } else {
            var v = RxDouble(fontSizeVal);
            var saveTo = RxInt(0);
            await MsgBox.myDialog(
              title: I18nKey.edit.tr,
              content: Obx(
                () => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 10),
                    Text(
                      '${I18nKey.fontSize.tr}: ${v.value.round()}',
                      style: TextStyle(fontSize: v.value),
                    ),
                    Slider(
                      value: v.value,
                      min: 10,
                      max: 40,
                      divisions: 30,
                      label: '${v.value.round()}',
                      onChanged: (newVal) {
                        v.value = newVal;
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 14.0),
                      child: RadioGroup<int>(
                        groupValue: saveTo.value,
                        onChanged: (val) {
                          if (val != null) saveTo.value = val;
                        },
                        child: Row(
                          children: [
                            Text(I18nKey.labelSaveAt.tr),
                            Radio<int>(
                              value: ContentTypeEnum.book.index,
                            ),
                            Text(I18nKey.labelBookFn.tr),
                            Radio<int>(
                              value: ContentTypeEnum.chapter.index,
                            ),
                            Text(I18nKey.labelChapterName.tr),
                            Radio<int>(
                              value: ContentTypeEnum.verse.index,
                            ),
                            Text(I18nKey.labelVerseName.tr),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              action: MsgBox.buttonsWithDivider(
                buttons: [
                  MsgBox.button(
                    text: I18nKey.btnCancel.tr,
                    onPressed: () {
                      Get.back();
                    },
                  ),
                  MsgBox.button(
                    text: I18nKey.btnSave.tr,
                    onPressed: () async {
                      final fontSizeKey = "${type.acronym}FontSize";
                      final verse = helper.getCurrVerse()!;
                      var bookMap = helper.getCurrBookMap();
                      bookMap?.remove(fontSizeKey);
                      var chapterMap = helper.getCurrChapterMap();
                      chapterMap?.remove(fontSizeKey);
                      var verseMap = helper.getCurrVerseMap();
                      verseMap?.remove(fontSizeKey);
                      switch (ContentTypeEnum.values[saveTo.value]) {
                        case ContentTypeEnum.book:
                          bookMap![fontSizeKey] = '${v.value}';
                          await Db().db.bookDao.updateBookContent(verse.bookId, jsonEncode(bookMap));
                          await Db().db.chapterDao.updateChapterContent(verse.chapterId, jsonEncode(chapterMap));
                          await Db().db.verseDao.updateVerseContent(verse.verseId, jsonEncode(verseMap));
                          break;
                        case ContentTypeEnum.chapter:
                          chapterMap![fontSizeKey] = '${v.value}';
                          await Db().db.chapterDao.updateChapterContent(verse.chapterId, jsonEncode(chapterMap));
                          await Db().db.verseDao.updateVerseContent(verse.verseId, jsonEncode(verseMap));
                          break;
                        case ContentTypeEnum.verse:
                          verseMap![fontSizeKey] = '${v.value}';
                          await Db().db.verseDao.updateVerseContent(verse.verseId, jsonEncode(verseMap));
                          break;
                      }
                      logic.update([RepeatLogic.id]);
                      Get.back();
                    },
                  ),
                ],
              ),
            );
          }
          helper.stopMedia(true);
        },
        editText,
        style,
      );
    } else {
      String? text = map[type.acronym];
      if (text == null || text.isEmpty) {
        return null;
      }
      return MyTextButton.build(
        () async {
          helper.stopMedia(false);
          await logic.copyLogic.show(Get.context!, "{{text}}", text);
          helper.stopMedia(true);
        },
        text,
        style,
      );
    }
  }

  double? textFontSize(RepeatLogic logic, QaType type) {
    final helper = logic.state.helper;
    final fontSizeKey = "${type.acronym}FontSize";
    var map = helper.getCurrVerseMap();
    if (map != null && map[fontSizeKey] != null) {
      return double.parse(map[fontSizeKey]);
    }
    map = helper.getCurrChapterMap();
    if (map != null && map[fontSizeKey] != null) {
      return double.parse(map[fontSizeKey]);
    }
    map = helper.getCurrBookMap();
    if (map != null && map[fontSizeKey] != null) {
      return double.parse(map[fontSizeKey]);
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
