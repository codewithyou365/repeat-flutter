// entity/cache_file.dart

import 'package:floor/floor.dart';

@Entity(indices: [
  Index(value: ['url'], unique: true),
])
class CacheFile {
  @PrimaryKey(autoGenerate: true)
  final int? id;

  final String url;

  final String path;

  final int count;
  final int total;
  final String msg;

  CacheFile(this.url, this.path, {this.id, this.msg = "", this.count = 0, this.total = 1});
}
