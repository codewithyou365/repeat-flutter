import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/db/database.dart';

import 'package:repeat_flutter/db/entity/game_user.dart';
import 'package:repeat_flutter/db/entity/kv.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';

import 'package:repeat_flutter/widget/dialog/msg_box.dart';
import 'package:repeat_flutter/widget/row/row_widget.dart';

class UserManager<T extends GetxController> {
  static const String id = "UserManager";

  List<GameUser> users = [];
  int allowRegisterNumber = 1;
  final T parentLogic;
  String text = "";

  UserManager(this.parentLogic);

  Future<void> init() async {
    users = await Db().db.gameUserDao.getAllUser();
    allowRegisterNumber = await getAllowRegisterNumber();
  }

  static Future<int> getAllowRegisterNumber() async {
    var v = await Db().db.kvDao.one(K.allowRegisterNumber);
    return int.parse(v?.value ?? "1");
  }

  Future<void> setAllowRegisterNumber(int value) async {
    allowRegisterNumber = value;
    await Db().db.kvDao.insertKv(Kv(K.allowRegisterNumber, "$value"));
  }

  void show(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    this.text = text;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return SizedBox(
          width: screenSize.width,
          height: screenSize.height / 2,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.0.w, vertical: 20.0),
            child: GetBuilder<T>(
              id: UserManager.id,
              builder: (_) {
                var localAllowRegisterNumber = RxString("$allowRegisterNumber");
                return ListView(children: [
                  RowWidget.buildTextWithEdit(
                    I18nKey.labelAllowRegisterNumber.tr,
                    localAllowRegisterNumber,
                    inputType: InputType.number,
                    yes: () async {
                      allowRegisterNumber = int.parse(localAllowRegisterNumber.value);
                      await setAllowRegisterNumber(allowRegisterNumber);
                      parentLogic.update([UserManager.id]);
                      Get.back();
                    },
                    refresh: () async {
                      await init();
                      parentLogic.update([UserManager.id]);
                    },
                  ),
                  RowWidget.buildDivider(),
                  ...List.generate(
                    users.length,
                    (index) => Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Card(
                        color: Theme.of(context).secondaryHeaderColor,
                        child: PopupMenuButton<String>(
                          child: RowWidget.buildText(users[index].name, "在线"),
                          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                            PopupMenuItem<String>(
                              onTap: () {
                                //TODO
                              },
                              child: Text(I18nKey.labelResetPassword.tr),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                ]);
              },
            ),
          ),
        );
      },
    );
  }
}
