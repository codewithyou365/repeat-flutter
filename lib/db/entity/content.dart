// entity/content.dart

import 'package:floor/floor.dart';

@Entity(
  indices: [
    Index(value: ['classroomId', 'name'], unique: true),
    Index(value: ['classroomId', 'serial'], unique: true),
    Index(value: ['classroomId', 'sort'], unique: true),
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
  bool warning;

  Content(
    this.classroomId,
    this.serial,
    this.name,
    this.desc,
    this.docId,
    this.url,
    this.sort,
    this.hide,
    this.warning, {
    this.id,
  });
}
