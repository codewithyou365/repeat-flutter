// entity/cache_file.dart

import 'package:floor/floor.dart';

@entity
class CacheFile {
  @primaryKey
  final String url;
  final bool success;

  final String msg;

  CacheFile(this.url, this.success, {this.msg = ""});
}
