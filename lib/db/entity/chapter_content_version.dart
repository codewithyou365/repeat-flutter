// entity/chapter_content_version.dart

import 'package:floor/floor.dart';

import 'content_version.dart';

@Entity(
  indices: [
    Index(value: ['classroomId']),
    Index(value: ['bookId']),
  ],
  primaryKeys: ['chapterId', 'version'],
)
class ChapterContentVersion implements ContentVersion {
  final int classroomId;
  final int bookId;
  int chapterId;
  final int version;
  final VersionReason reason;
  final String content;
  final DateTime createTime;

  ChapterContentVersion({
    required this.classroomId,
    required this.bookId,
    required this.chapterId,
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
