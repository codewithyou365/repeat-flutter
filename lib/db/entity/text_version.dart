// entity/text_version.dart

import 'package:floor/floor.dart';

enum TextVersionType {
  verseContent,
  verseNote,
  chapterContent,
}

enum VersionReason {
  import,
  editor,
}

abstract class ContentVersion {
  String getContent();

  int getVersion();

  DateTime getCreateTime();
}

@Entity(
  indices: [
    Index(value: ['classroomId', 'bookId', 't', 'id']),
  ],
  primaryKeys: ['t', 'id', 'version'],
)
class TextVersion implements ContentVersion {
  final TextVersionType t;
  int id;
  final int version;
  final int classroomId;
  final int bookId;
  final VersionReason reason;
  final String text;
  final DateTime createTime;

  TextVersion({
    required this.t,
    this.id = 0,
    required this.version,
    required this.classroomId,
    required this.bookId,
    required this.reason,
    required this.text,
    required this.createTime,
  });

  @override
  String getContent() {
    return text;
  }

  @override
  int getVersion() {
    return version;
  }

  @override
  DateTime getCreateTime() {
    return createTime;
  }
}
