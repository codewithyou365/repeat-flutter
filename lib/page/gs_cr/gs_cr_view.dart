import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:grouped_list/grouped_list.dart';
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
                    add(context);
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
          groupBy: (element) => element.type.name,
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

  Widget CupertinoItem(String title) {
    return Column(
      children: [
        Text(title),
        const SizedBox(height: 3),
        SizedBox(
          width: 80.w,
          height: 64,
          child: CupertinoPicker(
            itemExtent: 32.0, // Height of each item
            onSelectedItemChanged: (index) {
              print('Selected: ${index + 1}');
            },
            children: List.generate(10, (index) {
              return Center(child: Text('${index + 1}'));
            }),
          ),
        ),
      ],
    );
  }

  void add(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return SizedBox(
          width: screenSize.width,
          height: screenSize.height / 2.5,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0.w, vertical: 20.0),
            child: ListView(
              children: [
                Row(
                  children: [
                    const Text('Max: 100'),
                    const Spacer(),
                    Text(I18nKey.btnSave.tr),
                  ],
                ),
                const SizedBox(height: 20),
                const Text('From:'),
                const SizedBox(height: 5),
                Row(
                  children: [
                    CupertinoItem("Content"),
                    const Spacer(),
                    CupertinoItem("Lesion"),
                    const Spacer(),
                    CupertinoItem("Segment"),
                  ],
                ),
                const SizedBox(height: 20),
                const Text('To:'),
                const SizedBox(height: 5),
                Row(
                  children: [
                    CupertinoItem("Content"),
                    const Spacer(),
                    CupertinoItem("Lesion"),
                    const Spacer(),
                    CupertinoItem("Segment"),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
