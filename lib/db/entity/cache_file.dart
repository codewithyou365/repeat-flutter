// entity/cache_file.dart

import 'package:floor/floor.dart';

@entity
class CacheFile {
  @primaryKey
  final String url;

  final int count;
  final int total;
  final String msg;

  CacheFile(this.url, {this.msg = "", this.count = 0, this.total = 1});
}
