// entity/book_content_version.dart

import 'package:floor/floor.dart';

import 'content_version.dart';

@Entity(
  indices: [
    Index(value: ['classroomId', 'version'], unique: true),
  ],
  primaryKeys: ['bookId', 'version'],
)
class BookContentVersion implements ContentVersion {
  final int classroomId;
  final int bookId;
  final int version;
  final VersionReason reason;
  final String content;
  final DateTime createTime;

  BookContentVersion({
    required this.classroomId,
    required this.bookId,
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
