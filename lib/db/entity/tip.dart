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

  /// 这条提示服务挂在哪个字段上，存的是字段引用串（见 VerseField.ref）：
  /// 'q'/'a'/'n' 各一个，提示是 't'（第 1 条）、't1'（第 2 条）、't2'……
  /// 提示变成数组后这一列的取值就不再是固定 4 个了，索引 ['bookId','t'] 照样成立。
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
