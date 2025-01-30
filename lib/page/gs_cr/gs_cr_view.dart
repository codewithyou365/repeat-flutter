import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:repeat_flutter/db/entity/segment_today_prg.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/nav.dart';
import 'package:repeat_flutter/page/gs_cr/gs_cr_state.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';

import 'gs_cr_logic.dart';

class GsCrPage extends StatelessWidget {
  const GsCrPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<GsCrLogic>();
    return Scaffold(
      appBar: AppBar(
        actions: <Widget>[
          Padding(
            padding: EdgeInsets.all(8.0.w),
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  onTap: () {
                    add(context, logic);
                  },
                  child: Text(I18nKey.btnAddSchedule.tr),
                ),
                PopupMenuItem<String>(
                  onTap: () {
                    Nav.gsCrSettings.push();
                  },
                  child: Text(I18nKey.btnConfigSettings.tr),
                ),
              ],
            ),
          ),
        ],
        title: const Text(""),
      ),
      bottomNavigationBar: SizedBox(
        height: 60.h,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          // Distribute buttons evenly
          children: [
            InkWell(
              onTap: () => {Nav.gsCrContent.push()},
              child: Container(
                width: 180.w,
                alignment: Alignment.center,
                child: Text(I18nKey.content.tr),
              ),
            ),
            InkWell(
              onTap: () => {Nav.gsCrStats.push()},
              child: Container(
                width: 180.w,
                alignment: Alignment.center,
                child: Text(I18nKey.statistic.tr),
              ),
            ),
          ],
        ),
      ),
      body: buildDetailContent(context),
    );
  }

  Widget buildDetailContent(BuildContext context) {
    final logic = Get.find<GsCrLogic>();
    final state = logic.state;
    return GetBuilder<GsCrLogic>(
      id: GsCrLogic.id,
      builder: (_) {
        return GroupedListView<SegmentTodayPrgInView, String>(
          elements: state.segments,
          groupBy: (element) => "${element.type.index}",
          groupHeaderBuilder: (element) => PopupMenuButton<String>(
            child: SizedBox(
              height: 40,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  children: [
                    Text(
                      element.groupDesc,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                onTap: () => {logic.tryStartGroup(element.type, mode: Repeat.justView)},
                child: Text(I18nKey.btnBrowse.tr),
              ),
              PopupMenuItem<String>(
                onTap: () => {logic.tryStartGroup(element.type)},
                child: Text(I18nKey.btnExamine.tr),
              ),
              PopupMenuItem<String>(
                onTap: () => {logic.resetSchedule(element.type)},
                child: Text(I18nKey.labelReset.tr),
              ),
              if (element.type != TodayPrgType.fullCustom)
                PopupMenuItem<String>(
                  onTap: () => {logic.config(element.type)},
                  child: Text(I18nKey.settings.tr),
                ),
            ],
          ),
          groupStickyHeaderBuilder: (element) => Container(
            color: Theme.of(context).secondaryHeaderColor,
            height: 120,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: Text(state.learnDeadlineTips),
                  ),
                  PopupMenuButton<String>(
                    child: Row(
                      children: [
                        Text(
                          "${I18nKey.labelAll.tr}: ${state.learnedTotalCount}/${state.learnTotalCount}",
                          style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      PopupMenuItem<String>(
                        onTap: () => {logic.tryStartAll(mode: Repeat.justView)},
                        child: Text(I18nKey.btnBrowse.tr),
                      ),
                      PopupMenuItem<String>(
                        onTap: logic.tryStartAll,
                        child: Text(I18nKey.btnExamine.tr),
                      ),
                      PopupMenuItem<String>(
                        onTap: () {
                          MsgBox.yesOrNo(I18nKey.labelReset.tr, I18nKey.labelResetAllDesc.tr, yes: logic.resetAllSchedule);
                        },
                        child: Text(I18nKey.labelReset.tr),
                      ),
                    ],
                  ),
                  PopupMenuButton<String>(
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            element.groupDesc,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      PopupMenuItem<String>(
                        onTap: () => {logic.tryStartGroup(element.type, mode: Repeat.justView)},
                        child: Text(I18nKey.btnBrowse.tr),
                      ),
                      PopupMenuItem<String>(
                        onTap: () => {logic.tryStartGroup(element.type)},
                        child: Text(I18nKey.btnExamine.tr),
                      ),
                      PopupMenuItem<String>(
                        onTap: () => {logic.resetSchedule(element.type)},
                        child: Text(I18nKey.labelReset.tr),
                      ),
                      if (element.type != TodayPrgType.fullCustom)
                        PopupMenuItem<String>(
                          onTap: () => {logic.config(element.type)},
                          child: Text(I18nKey.settings.tr),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          itemBuilder: (context, SegmentTodayPrgInView element) => Card(
            elevation: 8.0,
            margin: EdgeInsets.fromLTRB(6, element.uniqIndex == 0 ? 90 : 10.0, 6.0, 10.0),
            child: PopupMenuButton<String>(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                title: Row(
                  children: [
                    Text(element.name),
                  ],
                ),
                subtitle: Text(element.desc),
              ),
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  onTap: () => {logic.tryStart(element.segments, mode: Repeat.justView)},
                  child: Text(I18nKey.btnBrowse.tr),
                ),
                PopupMenuItem<String>(
                  onTap: () => {logic.tryStart(element.segments, grouping: true)},
                  child: Text(I18nKey.btnExamine.tr),
                ),
                PopupMenuItem<String>(
                  onTap: () => {logic.copy(context, element.segments)},
                  child: Text(I18nKey.btnCopy.tr),
                ),
              ],
            ),
          ),
          itemComparator: (item1, item2) => item1.index.compareTo(item2.index),
          // optional
          useStickyGroupSeparators: true,
          // optional
          floatingHeader: false,
          // optional
          order: GroupedListOrder.ASC, // optional
        );
      },
    );
  }

  Widget cupertinoItem(List<String> titles, ValueChanged<int> changed, GestureTapCallback? tap, {List<String>? select, int? count}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (tap != null) tap();
    });
    return Column(
      children: [
        for (var title in titles) Text(title),
        const SizedBox(height: 3),
        SizedBox(
          width: 80.w,
          height: 64,
          child: count != null && count < 0
              ? CupertinoPicker(
                  itemExtent: 32.0,
                  onSelectedItemChanged: changed,
                  children: List.generate(1, (index) {
                    return Center(child: Text("${index + 1}"));
                  }),
                )
              : CupertinoPicker(
                  itemExtent: 32.0,
                  onSelectedItemChanged: changed,
                  children: count != null
                      ? List.generate(count, (index) {
                          return Center(child: Text("${index + 1}"));
                        })
                      : List.generate(select!.length, (index) {
                          return Center(child: Text(select[index]));
                        }),
                ),
        ),
      ],
    );
  }

  void add(BuildContext context, GsCrLogic logic) async {
    final Size screenSize = MediaQuery.of(context).size;
    var ok = await logic.initForAdd();
    if (!ok) {
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return SizedBox(
          width: screenSize.width,
          height: screenSize.height / 3.5,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.0.w, vertical: 20.0),
            child: ListView(
              children: [
                Row(
                  children: [
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        logic.addSchedule();
                      },
                      child: Text(I18nKey.btnOk.tr),
                    ),
                    SizedBox(width: 5.w),
                  ],
                ),
                const SizedBox(height: 20),
                GetBuilder<GsCrLogic>(
                    id: GsCrLogic.idForAdd,
                    builder: (_) {
                      return Row(
                        children: [
                          Card(
                            elevation: 8.0,
                            color: Theme.of(context).secondaryHeaderColor,
                            child: Row(
                              children: [
                                cupertinoItem(['', I18nKey.content.tr], logic.selectContent, null, select: logic.state.forAdd.contentNames),
                                cupertinoItem([I18nKey.labelFrom.tr, I18nKey.labelLesson.tr], logic.selectLesson, logic.initLesson, count: logic.state.forAdd.maxLesson),
                                cupertinoItem(['', I18nKey.labelSegment.tr], logic.selectSegment, logic.initSegment, count: logic.state.forAdd.maxSegment),
                              ],
                            ),
                          ),
                          const Spacer(),
                          cupertinoItem([I18nKey.btnAdd.tr, I18nKey.labelScheduleCount.tr], logic.selectCount, null, count: 100),
                        ],
                      );
                    })
              ],
            ),
          ),
        );
      },
    );
  }
}
