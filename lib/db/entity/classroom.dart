// entity/segment.dart

import 'package:floor/floor.dart';

@Entity(
  primaryKeys: ['name'],
  indices: [
    Index(value: ['sort'], unique: true),
  ],
)
class Classroom {
  final String name;
  final String arg;
  final int sort;

  Classroom(
    this.name,
    this.arg,
    this.sort,
  );
}
