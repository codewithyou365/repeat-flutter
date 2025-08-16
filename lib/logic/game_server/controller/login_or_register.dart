import 'package:repeat_flutter/common/ws/message.dart' as message;
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/logic/game_server/constant.dart';

class LoginOrRegister {
  String userName;
  String password;
  String newPassword;

  LoginOrRegister(
    this.userName,
    this.password,
    this.newPassword,
  );

  Map<String, dynamic> toJson() {
    return {
      'userName': userName,
      'password': password,
      'newPassword': newPassword,
    };
  }

  factory LoginOrRegister.fromJson(Map<String, dynamic> json) {
    return LoginOrRegister(
      json['userName'] as String,
      json['password'] as String,
      json['newPassword'] as String,
    );
  }
}

Future<message.Response?> loginOrRegister(message.Request req) async {
  final data = LoginOrRegister.fromJson(req.data);
  final user = await Db().db.gameUserDao.loginOrRegister(
    data.userName,
    data.password,
    data.newPassword,
  );
  if (!user.isEmpty()) {
    if (user.needToResetPassword) {
      return message.Response(error: GameServerError.needToResetPassword.name);
    }
    return message.Response(data: user.token);
  }
  return message.Response(error: GameServerError.userOrPasswordError.name);
}
