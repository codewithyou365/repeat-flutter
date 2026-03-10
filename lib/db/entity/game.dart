// entity/game.dart

import 'package:floor/floor.dart';

@Entity(
  indices: [
    Index(value: ['classroomId', 'name'], unique: true),
    Index(value: ['classroomId', 'key'], unique: true),
    Index(value: ['bookId']),
    Index(value: ['classroomId', 'hash']),
  ],
)
class Game {
  @primaryKey
  final int? id;

  final int classroomId;
  final int bookId;
  final String key;
  String name;
  String hash;
  String data;

  final int ownerUserId;
  final int createTime;

  Game({
    required this.classroomId,
    required this.bookId,
    required this.key,
    required this.name,
    required this.hash,
    required this.data,
    required this.ownerUserId,
    required this.createTime,
    this.id,
  });
}
