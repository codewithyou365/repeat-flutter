// entity/game.dart

import 'package:floor/floor.dart';

/// 游戏是整个课堂全局的：宣告在 [Classroom.content] 的 'g' 里，
/// zip 放在课堂自己的资源目录（[DocPath.getClassroomResRelativePath]），不挂在某一本书下面。
@Entity(
  indices: [
    Index(value: ['classroomId', 'name'], unique: true),
  ],
)
class Game {
  @primaryKey
  final int? id;

  final int classroomId;
  String k;
  String name;
  String hash;
  String data;
  String service;

  final int createTime;

  Game({
    required this.classroomId,
    required this.k,
    required this.name,
    required this.hash,
    required this.data,
    required this.service,
    required this.createTime,
    this.id,
  });
}
