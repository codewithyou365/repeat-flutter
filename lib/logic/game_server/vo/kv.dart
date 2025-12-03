
class Kv {
  final String k;
  final String v;

  Kv({
    required this.k,
    required this.v,
  });

  Map<String, dynamic> toJson() {
    return {
      'k': k,
      'v': v,
    };
  }

  factory Kv.fromJson(Map<String, dynamic> json) {
    return Kv(
      k: json['k'] as String,
      v: json['v'] as String,
    );
  }
}
