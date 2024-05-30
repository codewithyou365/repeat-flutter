// entity/content_index.dart

import 'package:floor/floor.dart';

@Entity(
  primaryKeys: ['crn', 'url'],
  indices: [
    Index(value: ['sort']),
  ],
)
class ContentIndex {
  final String crn;
  final String url;

  final int sort;

  ContentIndex(
    this.crn,
    this.url,
    this.sort,
  );
}
