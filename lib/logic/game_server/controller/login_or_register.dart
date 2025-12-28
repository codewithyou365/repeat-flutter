import 'package:repeat_flutter/common/ws/message.dart' as message;
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/kv.dart';
import 'package:repeat_flutter/logic/game_server/constant.dart';

class LoginOrRegister {
  String userName;
  String password;
  String newPassword;
  String gamePassword;

  LoginOrRegister(
    this.userName,
    this.password,
    this.newPassword,
    this.gamePassword,
  );

  Map<String, dynamic> toJson() {
    return {
      'userName': userName,
      'password': password,
      'newPassword': newPassword,
      'gamePassword': gamePassword,
    };
  }

  factory LoginOrRegister.fromJson(Map<String, dynamic> json) {
    return LoginOrRegister(
      json['userName'] as String,
      json['password'] as String,
      json['newPassword'] as String,
      json['gamePassword'] as String,
    );
  }
}

class LoginOrRegisterRes {
  final int userId;
  final String token;

  LoginOrRegisterRes({
    required this.userId,
    required this.token,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'token': token,
    };
  }

  factory LoginOrRegisterRes.fromJson(Map<String, dynamic> json) {
    return LoginOrRegisterRes(
      userId: json['userId'] as int,
      token: json['token'] as String,
    );
  }
}

Future<message.Response?> loginOrRegister(message.Request req) async {
  final data = LoginOrRegister.fromJson(req.data);
  List<String> error = [];
  final gameUser = await Db().db.gameUserDao.loginOrRegister(
    data.userName,
    data.password,
    data.newPassword,
    error,
  );
  if (gameUser.id == null) {
    return message.Response(error: error.first);
  }
  var gamePassword = await Db().db.kvDao.getStr(K.gamePassword) ?? '';
  if (gamePassword.isNotEmpty && data.gamePassword != gamePassword) {
    return message.Response(error: GameServerError.gamePasswordError.name);
  }
  return message.Response(
    data: LoginOrRegisterRes(
      userId: gameUser.id!,
      token: gameUser.token,
    ),
  );
}
