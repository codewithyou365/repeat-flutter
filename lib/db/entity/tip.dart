// entity/tip.dart

import 'package:floor/floor.dart';

@Entity(
  indices: [
    Index(value: ['bookId', 't'], unique: true),
    Index(value: ['classroomId']),
  ],
)
class Tip {
  @primaryKey
  final int? id;

  final int classroomId;
  final int bookId;
  String t;
  String k;
  String hash;
  String service;

  final int createTime;

  Tip({
    required this.classroomId,
    required this.bookId,
    required this.t,
    required this.k,
    required this.hash,
    required this.service,
    required this.createTime,
    this.id,
  });
}
