import 'package:floor/floor.dart';

@Entity(tableName: "")
class KeyId {
  @primaryKey
  final int id;
  final String k;

  KeyId(
    this.id,
    this.k,
  );
}
