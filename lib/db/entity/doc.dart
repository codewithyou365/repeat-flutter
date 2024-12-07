// entity/doc.dart

import 'package:floor/floor.dart';

@Entity(indices: [
  Index(value: ['path'], unique: true),
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

  factory Doc.fromJson(Map<String, dynamic> json) {
    return Doc(
      json['url'] as String,
      json['path'] as String,
      json['hash'] as String,
      id: json['id'] as int?,
      msg: json['msg'] as String? ?? "",
      count: json['count'] as int? ?? 0,
      total: json['total'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'path': path,
      'count': count,
      'total': total,
      'msg': msg,
      'hash': hash,
    };
  }
}
