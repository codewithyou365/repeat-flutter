import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/segment.dart';
import 'package:repeat_flutter/widget/player_bar/player_bar.dart';

@Entity(tableName: "")
class SegmentContentInDb extends Segment {
  final String indexFileUrl;
  final String indexFilePath;
  final String mediaFilePath;

  SegmentContentInDb(
    super.key,
    super.indexFileId,
    super.mediaFileId,
    super.lessonIndex,
    super.segmentIndex,
    this.indexFileUrl,
    this.indexFilePath,
    this.mediaFilePath,
  );
}

class SegmentContent extends SegmentContentInDb {
  List<MediaSegment> mediaSegments = [];
  var question = "";
  var answer = "";

  SegmentContent(
    super.key,
    super.indexFileId,
    super.mediaFileId,
    super.lessonIndex,
    super.segmentIndex,
    super.indexFileUrl,
    super.indexFilePath,
    super.mediaFilePath,
  );

  static SegmentContent from(SegmentContentInDb d) {
    return SegmentContent(
      d.key,
      d.indexFileId,
      d.mediaFileId,
      d.lessonIndex,
      d.segmentIndex,
      d.indexFileUrl,
      d.indexFilePath,
      d.mediaFilePath,
    );
  }
}
