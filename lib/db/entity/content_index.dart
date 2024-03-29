// entity/content_index.dart

import 'package:floor/floor.dart';

@entity
class ContentIndex {
  @primaryKey
  final String url;
  final bool success;

  final String msg;

  ContentIndex(this.url, this.success, {this.msg = ""});
}
