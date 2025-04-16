// entity/text_version.dart

import 'package:floor/floor.dart';

enum TextVersionType {
  segmentContent,
  segmentNote,
  lessonContent,
  rootContent,
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

  TextVersion({
    required this.t,
    required this.id,
    required this.version,
    required this.reason,
    required this.text,
    required this.createTime,
  });
}
