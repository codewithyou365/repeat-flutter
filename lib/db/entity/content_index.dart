// entity/content_index.dart

import 'package:floor/floor.dart';

@Entity(
  primaryKeys: ['g', 'url'],
  indices: [
    Index(value: ['sort'], unique: true),
  ],
)
class ContentIndex {
  final String g;
  final String url;

  final int sort;

  ContentIndex(
    this.url,
    this.sort, {
    this.g = "en",
  });
}
