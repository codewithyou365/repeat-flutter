import 'kv.dart';

class KvList {
  final List<Kv> list;

  KvList(this.list);

  Map<String, dynamic> toJson() {
    return {
      'list': list.map((e) => e.toJson()).toList(),
    };
  }

  factory KvList.fromJson(Map<String, dynamic> json) {
    return KvList(
      (json['list'] as List<dynamic>).map((e) => Kv.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
