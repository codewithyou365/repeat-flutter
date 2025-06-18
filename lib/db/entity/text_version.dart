// entity/text_version.dart

import 'package:floor/floor.dart';

enum TextVersionType {
  verseContent,
  verseNote,
  chapterContent,
  bookContent,
}

enum TextVersionReason {
  import,
  editor,
}

@Entity(
  indices: [
    Index(value: ['classroomId', 'bookSerial', 't', 'id']),
  ],
  primaryKeys: ['t', 'id', 'version'],
)
class TextVersion {
  final TextVersionType t;
  int id;
  final int version;
  final int classroomId;
  final int bookSerial;
  final TextVersionReason reason;
  final String text;
  final DateTime createTime;

  TextVersion({
    required this.t,
    this.id = 0,
    required this.version,
    required this.classroomId,
    required this.bookSerial,
    required this.reason,
    required this.text,
    required this.createTime,
  });
}
