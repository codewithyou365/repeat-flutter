// entity/content.dart

import 'package:floor/floor.dart';

enum WarningType {
  none,
  lessonWarning,
  segmentWarning,
  lessonSegmentWarning,
}

@Entity(
  indices: [
    Index(value: ['classroomId', 'name'], unique: true),
    Index(value: ['classroomId', 'serial'], unique: true),
    Index(value: ['classroomId', 'sort'], unique: true),
    Index(value: ['classroomId', 'updateTime']),
    Index(value: ['sort', 'id']),
  ],
)
class Content {
  @PrimaryKey(autoGenerate: true)
  final int? id;

  final int classroomId;

  // serial number in classroom
  final int serial;

  String name;
  String desc;
  int docId;
  String url;
  int sort;
  bool hide;
  WarningType warning;
  int createTime;
  int updateTime;

  Content({
    this.id,
    required this.classroomId,
    required this.serial,
    required this.name,
    required this.desc,
    required this.docId,
    required this.url,
    required this.sort,
    required this.hide,
    required this.warning,
    required this.createTime,
    required this.updateTime,
  });
}
