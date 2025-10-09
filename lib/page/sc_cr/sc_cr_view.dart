import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/verse_today_prg.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/nav.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';

import 'sc_cr_logic.dart';
import 'sc_cr_state.dart';

class ScCrPage extends StatelessWidget {
  const ScCrPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<ScCrLogic>();
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
                    logic.openFullCustom(context);
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
        title: Text(Classroom.currName),
      ),
      bottomNavigationBar: SizedBox(
        height: 60.h,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          // Distribute buttons evenly
          children: [
            InkWell(
              onTap: () => {Nav.scCrMaterial.push()},
              child: Container(
                width: 180.w,
                alignment: Alignment.center,
                child: Text(I18nKey.material.tr),
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
    final logic = Get.find<ScCrLogic>();
    final state = logic.state;
    return GetBuilder<ScCrLogic>(
      id: ScCrLogic.id,
      builder: (_) {
        return GroupedListView<VerseTodayPrgInView, String>(
          elements: state.verses,
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
                onTap: () => {logic.tryStartGroup(element.type, mode: RepeatType.justView)},
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
                          "${I18nKey.labelALL.tr}: ${state.learnedTotalCount}/${state.learnTotalCount}",
                          style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      PopupMenuItem<String>(
                        onTap: () => {logic.tryStartAll(mode: RepeatType.justView)},
                        child: Text(I18nKey.btnBrowse.tr),
                      ),
                      PopupMenuItem<String>(
                        onTap: logic.tryStartAll,
                        child: Text(I18nKey.btnExamine.tr),
                      ),
                      PopupMenuItem<String>(
                        onTap: () {
                          MsgBox.yesOrNo(
                            title: I18nKey.labelReset.tr,
                            desc: I18nKey.labelResetAllDesc.tr,
                            yes: logic.resetAllSchedule,
                          );
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
                        onTap: () => {logic.tryStartGroup(element.type, mode: RepeatType.justView)},
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
          itemBuilder: (context, VerseTodayPrgInView element) => Card(
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
                  onTap: () => {logic.tryStart(element.verses, mode: RepeatType.justView)},
                  child: Text(I18nKey.btnBrowse.tr),
                ),
                PopupMenuItem<String>(
                  onTap: () => {logic.tryStart(element.verses, grouping: true)},
                  child: Text(I18nKey.btnExamine.tr),
                ),
                PopupMenuItem<String>(
                  onTap: () => {logic.copy(context, element.verses)},
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
}
