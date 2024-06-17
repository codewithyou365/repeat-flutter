// entity/doc.dart

import 'package:floor/floor.dart';

@Entity(indices: [
  Index(value: ['url'], unique: true),
])
class Doc {
  @PrimaryKey(autoGenerate: true)
  final int? id;

  final String url;

  final String path;

  final int count;
  final int total;
  final String msg;
  final String hash;

  Doc(this.url, this.path, this.hash, {this.id, this.msg = "", this.count = 0, this.total = 1});
}
