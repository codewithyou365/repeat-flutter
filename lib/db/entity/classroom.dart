// entity/classroom.dart

import 'package:floor/floor.dart';

@Entity(
  primaryKeys: ['id'],
  indices: [
    Index(value: ['name'], unique: true),
    Index(value: ['sort'], unique: true),
  ],
)
class Classroom {
  static int curr = 0;
  static String currName = '';

  final int id;

  String name;
  int sort;
  bool hide;

  /// 课堂级内容，对标 [Book.content]，是一段 JSON 字符串。
  /// 新建的课堂是 '{}'，具体放什么由使用方（网络编辑/分享）决定。
  /// 对外整体导出时，会在这份 JSON 上再挂一个 'b' 数组塞进所有书本，
  /// 所以 'b' 是保留 key，不会存进这一列。
  String content;

  /// 网络编辑课堂文档时的乐观锁版本，见 ClassroomDao.updateContent。
  int contentVersion;

  Classroom(
    this.id,
    this.name,
    this.sort,
    this.hide,
    this.content,
    this.contentVersion,
  );
}
