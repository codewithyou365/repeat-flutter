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
  final int? id;
  String name;
  String password;
  String nonce;
  Date createDate;

  String token;
  Date tokenExpiredDate;

  GameUser(
    this.name,
    this.password,
    this.nonce,
    this.createDate,
    this.token,
    this.tokenExpiredDate, {
    this.id,
  });

  static empty() => GameUser('', '', '', Date(0), '', Date(0));

  isEmpty() => name.isEmpty;

  @override
  int getId() {
    return id!;
  }
}
