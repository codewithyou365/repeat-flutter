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

  Classroom(
    this.id,
    this.name,
    this.sort,
    this.hide,
  );
}
