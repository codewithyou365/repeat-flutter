// entity/content_index.dart

import 'package:floor/floor.dart';

@entity
class ContentIndex {
  @primaryKey
  final String url;

  ContentIndex(this.url);
}
