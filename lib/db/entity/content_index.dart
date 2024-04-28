// entity/content_index.dart

import 'package:floor/floor.dart';

@Entity(
  primaryKeys: ['group', 'url'],
  indices: [
    Index(value: ['sort'], unique: true),
  ],
)
class ContentIndex {
  final String group;
  final String url;

  final int sort;

  ContentIndex(
    this.url,
    this.sort, {
    this.group = "en",
  });
}
