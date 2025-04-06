// entity/text_version.dart

import 'package:floor/floor.dart';

enum TextVersionType {
  segmentContent,
  segmentNote,
}

enum TextVersionReason {
  import,
  editor,
}

@Entity(
  primaryKeys: ['type', 'id', 'version'],
)
class TextVersion {
  final TextVersionType type;
  final int id;
  final int version;
  final TextVersionReason reason;
  final String text;
  final DateTime createTime;

  TextVersion(
    this.type,
    this.id,
    this.version,
    this.reason,
    this.text,
    this.createTime,
  );
}
