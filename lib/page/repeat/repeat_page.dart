import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/kv.dart';
import 'package:repeat_flutter/db/entity/tip.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/logic/model/book_content.dart';
import 'package:repeat_flutter/logic/widget/assistive_touch/assistive_touch_button.dart';
import 'package:repeat_flutter/logic/widget/close_eyes/close_eyes_panel.dart';
import 'package:repeat_flutter/nav.dart';
import 'package:repeat_flutter/page/editor/editor_args.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';
import 'package:repeat_flutter/widget/row/row_widget.dart';
import 'package:repeat_flutter/widget/select/select.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';
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
        builder: (logic) {
          return Stack(
            children: [
              buildCore(context),
              AssistiveTouchButton(logic: logic.assistiveTouchLogic),
            ],
          );
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
    state.helper.practiceArea = () => practiceArea(logic);
    state.helper.tipArea = () => tipArea(logic);
    state.helper.fullScreenPanel = () => fullScreenPanel(logic);

    if (state.lastLandscape == null || state.lastLandscape != landscape) {
      state.lastLandscape = landscape;
      state.needUpdateSystemUiMode = true;
    }
    if (state.needUpdateSystemUiMode) {
      state.needUpdateSystemUiMode = false;
      logic.applySystemUiMode();
    }
    String? viewName;
    if (state.helper.initialized) {
      var verse = state.helper.getCurrVerse();
      if (verse != null && state.helper.currVerseShow != null) {
        viewName = state.helper.getCurrViewName();
      }
    }
    if (viewName == null) {
      return dataMissing(state);
    } else {
      logic.onViewNameChanged(viewName);
      return Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => logic.restoreSystemUiIfNeeded(),
        child: logic.showTypeToRepeatView[viewName]!.body(),
      );
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
    final repeatLogic = logic.repeatFlow;
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
                padding: EdgeInsets.zero,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: logic.switchShowMode,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Obx(() {
                      return Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Text(I18nKey.showMode.trArgs([state.helper.showMode.value.i18n.tr])),
                          Spacer(),
                        ],
                      );
                    }),
                  ),
                ),
              ),
              buildMenuItem(label: I18nKey.closeEyes.tr, onTap: logic.openCloseEyesMode),
              buildMenuItem(
                label: I18nKey.practice.tr,
                onTap: logic.togglePracticeMode,
                active: state.isPracticeMode,
              ),
              if (state.gameLogicInitSuccess)
                buildMenuItem(
                  label: I18nKey.game.tr,
                  onTap: logic.openGame,
                  active: logic.gameLogic.state.open,
                ),
              buildMenuItem(
                label: I18nKey.btnFocus.tr,
                onTap: logic.switchFocusMode,
                active: state.helper.focusMode,
              ),
              buildMenuItem(
                label: I18nKey.assistiveTouch.tr,
                onTap: logic.openAssistiveTouch,
                active: logic.assistiveTouchLogic.enabled,
              ),
              buildMenuItem(
                label: I18nKey.gamepadBinding.tr,
                onTap: logic.openGamepadBinding,
                active: logic.gamepadLogic.enabled,
              ),
            ],
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }

  /// 顶部菜单里带一致内边距(且可选左侧绿/灰点)的开关式菜单项。直接用 PopupMenuItem 自带的
  /// padding/onTap，而不是套一层 GestureDetector——PopupMenuItem 默认 padding 在 Material3
  /// 下是 12(不是 16),跟其他手写 16 的菜单项对不齐,所以这里显式传 16；onTap 用 PopupMenuItem
  /// 自带的即可，点击后会自动关闭菜单，不用手动 Get.back()。
  PopupMenuItem<String> buildMenuItem({
    required String label,
    required VoidCallback onTap,
    RxBool? active,
  }) {
    Widget row(bool showDot) {
      return Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          if (showDot) ...[
            active!.value ? RowWidget.buildGreenDot() : RowWidget.buildGreenDot(color: Colors.grey),
            const SizedBox(width: 8),
          ],
          Text(label),
          const Spacer(),
        ],
      );
    }

    return PopupMenuItem<String>(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      onTap: onTap,
      child: active == null ? row(false) : Obx(() => row(true)),
    );
  }

  Widget topBarTitle({required RepeatLogic logic, double? fontSize}) {
    var state = logic.state;
    String text = '';
    if (!state.helper.focusMode.value && logic.repeatFlow != null) {
      text = logic.repeatFlow!.titleLabel;
    }
    return Text(
      text,
      style: fontSize == null ? null : TextStyle(fontSize: fontSize),
    );
  }

  Widget bottomBar({required RepeatLogic logic, required double width, required double height}) {
    final repeatLogic = logic.repeatFlow;
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

  Widget practiceArea(RepeatLogic logic) {
    return Obx(() {
      if (!logic.state.isPracticeMode.value) {
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
          controller: logic.state.helper.practiceController,
          maxLines: null,
          minLines: 3,
          textInputAction: TextInputAction.newline,
          style: TextStyle(
            fontSize: fontSize(logic, QaType.answer) ?? 17,
            fontFamily: fontAlias(logic, QaType.answer),
          ),
          decoration: InputDecoration(
            hintText: I18nKey.practiceHint.tr,
            hintStyle: const TextStyle(color: Colors.grey),
            contentPadding: const EdgeInsets.all(12.0),
            border: InputBorder.none,
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear, size: 20, color: Colors.grey),
              onPressed: () {
                logic.state.helper.practiceController.clear();
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

    final classroomMap = helper.getClassroomMap();

    return Obx(() {
      final int tipCount = helper.currTipCount();
      bool isEditMode = helper.showMode.value == ShowMode.edit;

      // 这一条提示在这一节里有没有东西可看/可播。只判断字段块在不在不行：加提示、写了又清空
      // 都会留下一个空块（下标就是身份，空块不能从数组里删，见 VerseField.remove）。
      bool hasTipContent(int index) {
        final r = VerseField.ref(QaType.tip.acronym, index);
        if (VerseField.getText(map, r) != null) {
          return true;
        }
        if (VerseField.getStr(map, r, VerseField.mediaHash) != null) {
          return true;
        }
        // 没有专属媒体但配了区间：放的是整节那份媒体的一段，也算有内容。
        return VerseField.getStr(map, r, VerseField.start) != null && //
            VerseField.getStr(map, r, VerseField.end) != null;
      }

      // 这一节里哪几条提示要摆出来：开卷/闭卷下空的那几条不显示（提示是整个课堂统一定义的，
      // 但正文是逐节写的，不是每节都会把 8 条都填上）；编辑模式下全都摆出来，不然没法往里填。
      final visibleTips = <int>[];
      for (var i = 0; i < tipCount; i++) {
        if (isEditMode || hasTipContent(i)) {
          visibleTips.add(i);
        }
      }

      // 换了本书提示条数会变，存着的下标可能落在不存在的提示上。这里只是读的时候收一下，
      // 不回写：在 Obx 的 build 里改 Rx 会再触发一次重建。
      int tabIndex = helper.clampedTipTabIndex();
      if (tabIndex < tipCount && !visibleTips.contains(tabIndex)) {
        // 选中的那条这一节是空的（翻页翻过来的），退到第一条有内容的，都没有就落到笔记。
        tabIndex = visibleTips.isEmpty ? tipCount : visibleTips.first;
      }
      // 最后一个 tab 是笔记，前面是提示。
      final bool isNote = tabIndex >= tipCount;

      // 提示/笔记的定位串：提示按选中的那一条走（'t'/'t1'/…）。
      final String fieldRef = isNote ? QaType.note.acronym : VerseField.ref(QaType.tip.acronym, tabIndex);
      final String displayText = VerseField.getText(map, fieldRef) ?? (isNote ? '' : I18nKey.labelNoContent.tr);

      bool canEdit = isNote ? true : isEditMode;
      // 提示（'t'/'t1'/…）的提示服务是课堂级的，笔记（'n'）还是每本书各配各的。
      Tip? tipOf(String ref) {
        if (VerseField.baseOf(ref) == QaType.tip.acronym) {
          return logic.state.classroomTips[ref];
        }
        int? bookId = helper.logic.currVerse?.bookId;
        return logic.state.bookIdToTip[bookId]?[ref];
      }

      Future<void> onTipIconTap(String ref) async {
        Tip? tip = tipOf(ref);
        if (tip != null) {
          await logic.openTip(tip);
        }
      }

      // tab 名字：课堂那一层统一定义（整个课堂第 i 个 tab 名字一致，翻书翻页都不跳）。
      // 没写名字就用序号。
      String tabLabel(int index) {
        return VerseField.tipNameOf(classroomMap, index) ?? '${I18nKey.labelTips.tr}${index + 1}';
      }

      Widget tab(int index, String label, String ref) {
        final selected = index == tabIndex;
        // 编辑模式下长按提示 tab、或者再点一次已经选中的那个，都弹"更名/删除"。
        // 改的都是课堂那一层，整个课堂通用。
        final canEditTip = isEditMode && index < tipCount;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (selected && canEditTip) {
                  tipMenu(logic, index);
                  return;
                }
                helper.currentTipTabIndex.value = index;
              },
              onLongPress: canEditTip ? () => tipMenu(logic, index) : null,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  color: selected ? Colors.blue : Colors.grey,
                ),
              ),
            ),
            if (tipOf(ref) != null)
              IconButton(
                icon: const Icon(
                  Icons.tips_and_updates,
                  color: Color(0xFF007BFF),
                  size: 17,
                ),
                onPressed: () => onTipIconTap(ref),
              )
            else
              const SizedBox(width: 24),
          ],
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          // 提示最多 8 条，名字还可能很长，一行摆不下——整条 tab 栏横向可滚动。
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: helper.tipTabScrollController,
            child: Row(
              children: [
                for (final i in visibleTips) tab(i, tabLabel(i), VerseField.ref(QaType.tip.acronym, i)),
                // 编辑模式下能一直加到 8 条（VerseField.maxTip），加满就不显示了。
                if (isEditMode && tipCount < VerseField.maxTip)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => addTip(logic),
                    child: const Padding(
                      padding: EdgeInsets.only(right: 24),
                      child: Icon(Icons.add, size: 20, color: Colors.grey),
                    ),
                  ),
                tab(tipCount, I18nKey.labelNote.tr, QaType.note.acronym),
              ],
            ),
          ),
          const Divider(height: 16),

          if (displayText.isNotEmpty || canEdit)
            // 包一层 SelectionArea：长按正文能起选区、弹系统的复制/全选工具条；
            // 单击仍由里层 ExpandableText 的 GestureDetector 拿到（触发播放）。
            SelectionArea(
              child: ExpandableText(
                title: "",
                text: displayText,
                style: TextStyle(
                  fontSize: fontSizeOf(logic, fieldRef) ?? 17,
                  fontFamily: fontAliasOf(logic, fieldRef),
                ),
                onIcon: canEdit
                    ? () async {
                        if (helper.showMode.value != ShowMode.edit && isNote) {
                          await modify(map, logic, fieldRef);
                        } else {
                          await fullModify(map, logic, fieldRef);
                        }
                      }
                    : null,
                onText: () => logic.assistiveTouchLogic.playFieldRangeIfAny(fieldRef),
              ),
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
    String text = VerseField.getText(map, type.acronym) ?? '';
    BoxDecoration? iconDecoration;
    Future<void> Function()? onIconCallback;
    IconData? onIconData;
    if (edit) {
      onIconCallback = () async {
        await fullModify(map, logic, type.acronym);
      };
    } else {
      int? bookId = helper.logic.currVerse?.bookId;
      Tip? tip = logic.state.bookIdToTip[bookId]?[type.acronym];
      if (tip != null) {
        onIconCallback = () async {
          await logic.openTip(tip);
        };
        onIconData = Icons.tips_and_updates;
        iconDecoration = const BoxDecoration();
      } else {
        onIconCallback = null;
      }
    }
    // 同上：长按选词靠外面这层 SelectionArea，单击仍走里层的 onText。
    return SelectionArea(
      child: ExpandableText(
        title: "",
        text: text,
        style: style,
        onIcon: onIconCallback,
        iconDecoration: iconDecoration,
        icon: onIconData,
        onText: () => logic.assistiveTouchLogic.playFieldRangeIfAny(type.acronym),
      ),
    );
  }

  /// 编辑模式下点已选中的提示 tab 弹出来的菜单。
  Future<void> tipMenu(RepeatLogic logic, int index) async {
    final keys = [
      I18nKey.labelRenameTip.tr,
      I18nKey.labelDelete.tr,
    ];
    final selected = await Select.showSheet(title: tipDisplayName(logic, index), keys: keys);
    if (selected == null) {
      return;
    }
    if (keys[selected] == I18nKey.labelRenameTip.tr) {
      renameTip(logic, index);
    } else {
      deleteTip(logic, index);
    }
  }

  /// 第 [index] 条提示显示的名字：没起名字就用序号，跟 tab 栏一致。
  String tipDisplayName(RepeatLogic logic, int index) {
    return VerseField.tipNameOf(logic.state.helper.getClassroomMap(), index) //
        ??
        '${I18nKey.labelTips.tr}${index + 1}';
  }

  /// 删掉第 [index] 条提示：只把课堂那一层的名字清掉，tab 退回显示序号。
  /// 字体、提示服务配置和每一节已经写好的正文都原样保留——下标就是提示的身份，
  /// 从数组中间挪走会让后面几条的名字跟正文整体错位，所以这里只留个占位块。
  void deleteTip(RepeatLogic logic, int index) {
    final helper = logic.state.helper;
    final classroomMap = helper.getClassroomMap();
    if (classroomMap == null) {
      Snackbar.show(I18nKey.labelDataAnomaly.trArgs(["classroom"]));
      return;
    }
    MsgBox.yesOrNo(
      title: I18nKey.labelWarning.tr,
      desc: I18nKey.labelDeleteTip.tr,
      yes: () async {
        Get.back();
        VerseField.setStr(classroomMap, VerseField.ref(QaType.tip.acronym, index), VerseField.tipName, null);
        // setStr 传 null 会把末尾连着的空块截掉，补回来才不会让这一条整体消失。
        VerseField.ensureTipCount(classroomMap, index + 1);
        await Db().db.classroomDao.updateContent(Classroom.curr, jsonEncode(classroomMap));
        logic.update([RepeatLogic.id]);
        Snackbar.show(I18nKey.labelDeleted.tr);
      },
    );
  }

  /// 给第 [index] 条提示改名。名字定义在课堂那一层，所以整个课堂第 index 个 tab 都跟着改。
  /// 清空名字就退回显示序号——这时候要把占位块留住，不然这一条会连着被截掉。
  void renameTip(RepeatLogic logic, int index) {
    final helper = logic.state.helper;
    final classroomMap = helper.getClassroomMap();
    if (classroomMap == null) {
      Snackbar.show(I18nKey.labelDataAnomaly.trArgs(["classroom"]));
      return;
    }
    final name = RxString(VerseField.tipNameOf(classroomMap, index) ?? '');
    MsgBox.strInputWithYesOrNo(
      name,
      I18nKey.labelTipName.tr,
      null,
      yes: () async {
        VerseField.setStr(classroomMap, VerseField.ref(QaType.tip.acronym, index), VerseField.tipName, name.value);
        VerseField.ensureTipCount(classroomMap, index + 1);
        await Db().db.classroomDao.updateContent(Classroom.curr, jsonEncode(classroomMap));
        Get.back();
        logic.update([RepeatLogic.id]);
      },
    );
  }

  /// 加一条提示：往课堂的 't' 数组末尾补一个空块，整个课堂就多一个 tab。
  Future<void> addTip(RepeatLogic logic) async {
    final helper = logic.state.helper;
    final classroomMap = helper.getClassroomMap();
    if (classroomMap == null) {
      Snackbar.show(I18nKey.labelDataAnomaly.trArgs(["classroom"]));
      return;
    }
    final count = helper.currTipCount();
    if (count >= VerseField.maxTip) {
      return;
    }
    VerseField.ensureTipCount(classroomMap, count + 1);
    await Db().db.classroomDao.updateContent(Classroom.curr, jsonEncode(classroomMap));
    helper.currentTipTabIndex.value = count;
    logic.update([RepeatLogic.id]);
    // 新加的这条在最右边，等这一帧画完把 tab 栏滚过去，不然加完看不见自己加了什么。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 横竖屏切换那一瞬间可能同时挂着两个 tab 栏，这时候读 position 会断言失败，跳过就行。
      final controller = helper.tipTabScrollController;
      if (controller.positions.length == 1) {
        controller.jumpTo(controller.position.maxScrollExtent);
      }
    });
  }

  /// 编辑框/选择框标题：提示有名字就用名字（多条提示时"提示"分不清是哪条）。
  String fieldTitle(RepeatLogic logic, String fieldRef) {
    final name = VerseField.tipNameOf(logic.state.helper.getClassroomMap(), VerseField.indexOf(fieldRef));
    if (name != null && VerseField.baseOf(fieldRef) == QaType.tip.acronym) {
      return name;
    }
    return QaType.fromAcronym(VerseField.baseOf(fieldRef))?.i18n.tr ?? fieldRef;
  }

  Future<void> modify(Map<String, dynamic> map, RepeatLogic logic, String fieldRef) async {
    var helper = logic.state.helper;
    helper.stopMedia(false);

    await Nav.editor.push(
      arguments: EditorArgs(
        title: fieldTitle(logic, fieldRef),
        value: VerseField.getText(map, fieldRef) ?? '',
        save: (str) async {
          VerseField.setText(map, fieldRef, str);
          String jsonStr = jsonEncode(map);
          var verseId = helper.getCurrVerse()!.verseId;
          await Db().db.verseDao.updateVerseContent(verseId, jsonStr);
          logic.update([RepeatLogic.id]);
        },
      ),
    );
    helper.stopMedia(true);
  }

  Future<void> fullModify(Map<String, dynamic> map, RepeatLogic logic, String fieldRef) async {
    var helper = logic.state.helper;
    helper.stopMedia(false);
    String text = VerseField.getText(map, fieldRef) ?? '';
    var keys = [
      I18nKey.font.tr,
      I18nKey.content.tr,
    ];
    int? index = await Select.showSheet(title: I18nKey.editWhat.trArgs([fieldTitle(logic, fieldRef)]), keys: keys);
    if (index == null) {
      return;
    }
    if (keys[index] == I18nKey.font.tr) {
      // 提示的字体是课堂级的（bookId 传 null），'q'/'a'/'n' 还是每本书各配各的。
      final isTip = VerseField.baseOf(fieldRef) == QaType.tip.acronym;
      final fontMap = fontMapOf(logic, fieldRef);
      final verse = helper.getCurrVerse();
      if (fontMap == null || (!isTip && verse == null)) {
        return;
      }
      logic.adjustFont.open(
        bookId: isTip ? null : verse!.bookId,
        fontPrefix: fieldRef,
        map: fontMap,
      );
    } else if (keys[index] == I18nKey.content.tr) {
      await Nav.editor.push(
        arguments: EditorArgs(
          title: fieldTitle(logic, fieldRef),
          value: text,
          save: (str) async {
            VerseField.setText(map, fieldRef, str);
            String jsonStr = jsonEncode(map);
            var verseId = helper.getCurrVerse()!.verseId;
            await Db().db.verseDao.updateVerseContent(verseId, jsonStr);
            logic.update([RepeatLogic.id]);
          },
        ),
      );
    }
    helper.stopMedia(true);
  }

  double? fontSize(RepeatLogic logic, QaType type) => fontSizeOf(logic, type.acronym);

  String? fontAlias(RepeatLogic logic, QaType type) => fontAliasOf(logic, type.acronym);

  /// 字体存在字段块里：'q'/'a'/'n' 在 book 那一层，提示（'t'/'t1'/…）在课堂那一层，
  /// 每一条各存各的。
  Map<String, dynamic>? fontMapOf(RepeatLogic logic, String fieldRef) {
    final helper = logic.state.helper;
    return VerseField.baseOf(fieldRef) == QaType.tip.acronym //
        ? helper.getClassroomMap()
        : helper.getCurrBookMap();
  }

  double? fontSizeOf(RepeatLogic logic, String fieldRef) {
    final map = fontMapOf(logic, fieldRef);
    if (map == null) {
      return null;
    }
    final val = VerseField.getStr(map, fieldRef, VerseField.fontSize);
    if (val != null) {
      return double.parse(val);
    }
    return null;
  }

  String? fontAliasOf(RepeatLogic logic, String fieldRef) {
    final map = fontMapOf(logic, fieldRef);
    if (map == null) {
      return null;
    }
    return VerseField.getStr(map, fieldRef, VerseField.fontAlias);
  }

  Widget fullScreenPanel(RepeatLogic logic) {
    final helper = logic.state.helper;
    if (logic.state.fullScreenMode.value == RepeatFullScreenMode.none) {
      return SizedBox.shrink();
    } else if (logic.state.fullScreenMode.value == RepeatFullScreenMode.gameWebView) {
      var webviewArgs = logic.state.webviewArgs;
      if (webviewArgs == null) {
        return SizedBox.shrink();
      }
      return logic.webviewLogic.build(
        webviewArgs,
        () async {
          logic.state.fullScreenMode.value = RepeatFullScreenMode.none;
          await logic.openGame();
        },
        Get.context!,
      );
    } else {
      return CloseEyesPanel.build(
        key: closeEyeKey,
        height: helper.screenHeight,
        width: helper.screenWidth,
        showFinger: false,
        direct: DirectEnum.values[logic.state.closeEyesDirect],
        changeDirect: (DirectEnum direct) {
          logic.state.closeEyesDirect = direct.index;
          Db().db.kvDao.insertOrReplace(Kv(K.closeEyesDirect, "${direct.index}"));
        },
        getName: (int index, int total) {
          final repeatLogic = logic.repeatFlow;
          if (total == 1) {
            return repeatLogic?.leftLabel ?? '$index';
          } else if (total == 2) {
            if (index == 0) {
              return repeatLogic?.leftLabel ?? '$index';
            } else {
              return repeatLogic?.rightLabel ?? '$index';
            }
          } else if (total == 3) {
            if (index == 0) {
              return repeatLogic?.leftLabel ?? '$index';
            } else if (index == 1) {
              return I18nKey.tips.tr;
            } else {
              return repeatLogic?.rightLabel ?? '$index';
            }
          }
          if (index == 0) {
            return repeatLogic?.leftLabel ?? '$index';
          } else if (index == 1) {
            return I18nKey.tips.tr;
          } else if (index == 2) {
            return '${I18nKey.tips.tr}\nTTS';
          } else {
            return repeatLogic?.rightLabel ?? '$index';
          }
        },
        getColor: (int index, int total) {
          if (total == 1 && index == 0) {
            return Colors.red.withValues(alpha: 0.5);
          } else if (total == 2) {
            if (index == 0 || index == 3) {
              return Colors.red.withValues(alpha: 0.5);
            }
          } else if (total == 3) {
            if (index == 0 || index == 1 || index == 3) {
              return Colors.red.withValues(alpha: 0.5);
            }
          } else if (total >= 4) {
            return Colors.red.withValues(alpha: 0.5);
          }
          return Colors.white70;
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
          logic.state.fullScreenMode.value = RepeatFullScreenMode.none;
        },
        help: () {
          MsgBox.tips(desc: I18nKey.closeEyesTips.tr);
        },
      );
    }
  }
}
