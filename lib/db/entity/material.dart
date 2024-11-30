// entity/material.dart

import 'package:floor/floor.dart';

@Entity(
  indices: [
    Index(value: ['classroomId', 'name'], unique: true),
    Index(value: ['classroomId', 'serial'], unique: true),
    Index(value: ['classroomId', 'sort'], unique: true),
    Index(value: ['sort', 'id']),
  ],
)
class Material {
  @PrimaryKey(autoGenerate: true)
  final int? id;

  final int classroomId;

  // serial number in classroom
  final int serial;

  String name;
  String desc;
  int docId;
  int sort;
  bool hide;

  Material(
    this.classroomId,
    this.serial,
    this.name,
    this.desc,
    this.docId,
    this.sort,
    this.hide, {
    this.id,
  });
}
