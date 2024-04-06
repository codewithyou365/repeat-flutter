// entity/content_index.dart

import 'package:floor/floor.dart';

@Entity(indices: [
  Index(value: ['sort'], unique: true),
])
class ContentIndex {
  @primaryKey
  final String url;

  final int sort;

  ContentIndex(this.url, this.sort);
}
