import 'dart:convert';

import 'package:repeat_flutter/common/ws/message.dart' as message;
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/logic/game_server/constant.dart';

class LoginOrRegister {
  String userName;
  String password;

  LoginOrRegister(this.userName, this.password);

  Map<String, dynamic> toJson() {
    return {
      'userName': userName,
      'password': password,
    };
  }

  factory LoginOrRegister.fromJson(Map<String, dynamic> json) {
    return LoginOrRegister(
      json['userName'] as String,
      json['password'] as String,
    );
  }
}

Future<message.Response?> loginOrRegister(message.Request req) async {
  final data = LoginOrRegister.fromJson(req.data);
  final token = await Db().db.gameUserDao.loginOrRegister(data.userName, data.password);
  if (token != "") {
    return message.Response(data: token);
  }
  return message.Response(error: GameServerError.tokenExpired.name);
}
