import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/common/ws/server.dart';
import 'package:repeat_flutter/db/database.dart';

import 'package:repeat_flutter/db/entity/game_user.dart';
import 'package:repeat_flutter/db/entity/kv.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/event_bus.dart';
import 'package:repeat_flutter/logic/game_server/web_server.dart';

import 'package:repeat_flutter/widget/dialog/msg_box.dart';
import 'package:repeat_flutter/widget/row/row_widget.dart';
import 'package:repeat_flutter/widget/sheet/sheet.dart';

class UserManager<T extends GetxController> {
  static const String id = "UserManager";

  List<GameUser> users = [];
  final Map<int, bool> onlineUsers = {};
  int allowRegisterNumber = 1;
  final T parentLogic;
  String text = "";
  late WebServer web;
  final SubList<WsEvent> sub = [];

  UserManager(this.parentLogic);

  Future<void> init(WebServer web) async {
    users = await Db().db.gameUserDao.getAllUser();
    allowRegisterNumber = await getAllowRegisterNumber();
    this.web = web;
  }

  static Future<int> getAllowRegisterNumber() async {
    var v = await Db().db.kvDao.one(K.allowRegisterNumber);
    return int.parse(v?.value ?? "1");
  }

  Future<void> setAllowRegisterNumber(int value) async {
    allowRegisterNumber = value;
    await Db().db.kvDao.insertOrReplace(Kv(K.allowRegisterNumber, "$value"));
  }

  Future<void> show(BuildContext context) async {
    users = await Db().db.gameUserDao.getAllUser();
    onlineUsers.clear();
    for (var userId in web.server.nodes.userId2Node.keys) {
      onlineUsers[userId] = true;
    }
    users = sortUsersByOnline(onlineUsers, users);
    sub.on([EventTopic.wsEvent], (wsEvent) async {
      if (wsEvent == null) {
        return;
      }
      switch (wsEvent.wsEventType) {
        case WsEventType.removeAll:
          onlineUsers.clear();
          break;
        case WsEventType.remove:
          onlineUsers.remove(wsEvent.id);
          break;
        case WsEventType.add:
          onlineUsers[wsEvent.id] = true;
          if (!users.any((user) => user.id == wsEvent.id)) {
            users = await Db().db.gameUserDao.getAllUser();
          }
          break;
      }
      users = sortUsersByOnline(onlineUsers, users);
      parentLogic.update([UserManager.id]);
    });
    return Sheet.showBottomSheet(
      context,
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.0.w, vertical: 20.0),
        child: GetBuilder<T>(
          id: UserManager.id,
          builder: (_) {
            var localAllowRegisterNumber = RxString("$allowRegisterNumber");
            return ListView(
              children: [
                RowWidget.buildTextWithEdit(
                  I18nKey.labelAllowRegisterNumber.tr,
                  localAllowRegisterNumber,
                  inputType: InputType.number,
                  yes: () async {
                    allowRegisterNumber = int.parse(localAllowRegisterNumber.value);
                    await setAllowRegisterNumber(allowRegisterNumber);
                    parentLogic.update([UserManager.id]);
                    EventBus().publish(EventTopic.allowRegisterNumber, allowRegisterNumber);
                    Get.back();
                  },
                ),
                RowWidget.buildDivider(),
                ...List.generate(users.length, (index) {
                  bool online = onlineUsers[users[index].id!] == true;
                  return Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Card(
                      color: Theme.of(context).secondaryHeaderColor,
                      child: PopupMenuButton<String>(
                        child: RowWidget.buildText(users[index].name, online ? I18nKey.online.tr : I18nKey.offline.tr),
                        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                          PopupMenuItem<String>(
                            onTap: () async {
                              var node = web.server.nodes.userId2Node[users[index].id!];
                              var password = await Db().db.gameUserDao.resetPassword(users[index].id!);
                              if (node != null) {
                                await node.stop();
                              }
                              MsgBox.yes(
                                I18nKey.keyTitle.tr,
                                I18nKey.keyContent.trParams([users[index].name, password]),
                              );
                            },
                            child: Text(I18nKey.labelResetPassword.tr),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    ).then((_) {
      sub.off();
    });
  }

  List<GameUser> sortUsersByOnline(Map<int, bool> onlineUsers, List<GameUser> users) {
    List<GameUser> sorted = List<GameUser>.from(users);
    sorted.sort((a, b) {
      bool aOnline = onlineUsers[a.id!] == true;
      bool bOnline = onlineUsers[b.id!] == true;
      if (aOnline == bOnline) {
        int aId = a.id ?? 0;
        int bId = b.id ?? 0;
        return aId.compareTo(bId);
      }
      return aOnline ? -1 : 1;
    });
    return sorted;
  }
}
