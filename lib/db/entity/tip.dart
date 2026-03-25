// entity/game.dart

import 'package:floor/floor.dart';

@Entity(
  indices: [
    Index(value: ['classroomId', 'k'], unique: true),
    Index(value: ['bookId']),
    Index(value: ['classroomId', 'hash']),
  ],
)
class Tip {
  @primaryKey
  final int? id;

  final int classroomId;
  final int bookId;
  String k;
  String hash;
  String service;

  final int createTime;

  Tip({
    required this.classroomId,
    required this.bookId,
    required this.k,
    required this.hash,
    required this.service,
    required this.createTime,
    this.id,
  });
}
