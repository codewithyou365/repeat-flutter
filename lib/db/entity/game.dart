// entity/game.dart

import 'package:floor/floor.dart';

@Entity(
  indices: [
    Index(value: ['classroomId', 'name'], unique: true),
    Index(value: ['bookId']),
  ],
)
class Game {
  @primaryKey
  final int? id;

  final int classroomId;
  final int bookId;
  String k;
  String name;
  String hash;
  String data;
  String service;

  final int createTime;

  Game({
    required this.classroomId,
    required this.bookId,
    required this.k,
    required this.name,
    required this.hash,
    required this.data,
    required this.service,
    required this.createTime,
    this.id,
  });
}
