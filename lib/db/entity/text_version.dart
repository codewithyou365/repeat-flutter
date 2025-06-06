// entity/text_version.dart

import 'package:floor/floor.dart';

enum TextVersionType {
  verseContent,
  verseNote,
  lessonContent,
  bookContent,
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
  int id;
  final int version;
  final TextVersionReason reason;
  final String text;
  final DateTime createTime;

  TextVersion({
    required this.t,
    this.id = 0,
    required this.version,
    required this.reason,
    required this.text,
    required this.createTime,
  });
}
