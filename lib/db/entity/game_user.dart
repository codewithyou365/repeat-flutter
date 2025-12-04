// entity/game_user.dart

import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/date.dart';
import 'package:repeat_flutter/common/ws/server.dart';

@Entity(
  indices: [
    Index(value: ['name'], unique: true),
    Index(value: ['token'], unique: true),
  ],
)
class GameUser extends UserId {
  @PrimaryKey(autoGenerate: true)
  int? id;
  String name;
  String password;
  String nonce;
  Date createDate;

  String token;
  Date tokenExpiredDate;

  bool needToResetPassword;

  GameUser({
    required this.name,
    required this.password,
    required this.nonce,
    required this.createDate,
    required this.token,
    required this.tokenExpiredDate,
    required this.needToResetPassword,
    this.id,
  });

  static GameUser empty() => GameUser(
    name: '',
    password: '',
    nonce: '',
    createDate: Date(0),
    token: '',
    tokenExpiredDate: Date(0),
    needToResetPassword: false,
  );

  bool isEmpty() => name.isEmpty;

  @override
  int getId() {
    return id!;
  }
}
