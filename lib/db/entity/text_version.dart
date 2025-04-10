// entity/text_version.dart

import 'package:floor/floor.dart';

enum TextVersionType {
  segmentContent,
  segmentNote,
  lessonContent,
}

enum TextVersionReason {
  import,
  editor,
}

@Entity(
  primaryKeys: ['t', 'id', 'version'],
)
class TextVersion {
  final TextVersionType t;
  final int id;
  final int version;
  final TextVersionReason reason;
  final String text;
  final DateTime createTime;

  TextVersion(
    this.t,
    this.id,
    this.version,
    this.reason,
    this.text,
    this.createTime,
  );
}
