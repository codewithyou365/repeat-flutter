// entity/verse_content_version.dart

import 'package:floor/floor.dart';

import 'text_version.dart';

enum VerseContentType {
  verseContent,
  verseNote,
}

@Entity(
  indices: [
    Index(value: ['classroomId']),
    Index(value: ['bookId']),
    Index(value: ['chapterKeyId']),
  ],
  primaryKeys: ['verseKeyId', 't', 'version'],
)
class VerseContentVersion implements ContentVersion {
  final int classroomId;
  final int bookId;
  final int chapterKeyId;
  final int verseKeyId;
  final VerseContentType t;
  final int version;
  final VersionReason reason;
  final String content;
  final DateTime createTime;

  VerseContentVersion({
    required this.classroomId,
    required this.bookId,
    required this.chapterKeyId,
    required this.verseKeyId,
    required this.t,
    required this.version,
    required this.reason,
    required this.content,
    required this.createTime,
  });

  @override
  String getContent() {
    return content;
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
