// entity/segment.dart

import 'package:floor/floor.dart';

@entity
class Segment {
  @primaryKey
  final String key;
  final int indexFileId;
  final String indexFileUrl;
  final String indexFilePath;
  final int lessonIndex;
  final int segmentIndex;

  final String lessonFilePath;

  Segment(this.key, this.indexFileId, this.indexFileUrl, this.indexFilePath, this.lessonIndex, this.segmentIndex, this.lessonFilePath);
}
