// entity/content.dart

import 'package:floor/floor.dart';


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
  bool lessonWarning;
  bool segmentWarning;
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
    required this.lessonWarning,
    required this.segmentWarning,
    required this.createTime,
    required this.updateTime,
  });
}
