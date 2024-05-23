import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/segment.dart';
import 'package:repeat_flutter/widget/player_bar/player_bar.dart';

@Entity(tableName: "")
class SegmentContentInDb extends Segment {
  @primaryKey
  final String indexDocUrl;
  final String indexDocPath;
  final String mediaDocPath;

  SegmentContentInDb(
    super.crn,
    super.k,
    super.indexDocId,
    super.mediaDocId,
    super.lessonIndex,
    super.segmentIndex,
    super.sort,
    this.indexDocUrl,
    this.indexDocPath,
    this.mediaDocPath,
  );
}

class SegmentContent extends SegmentContentInDb {
  List<MediaSegment> mediaSegments = [];
  var title = "";
  var prevQuestion = "";
  var prevAnswer = "";
  var question = "";
  var tip = "";
  var answer = "";

  SegmentContent(
    super.crn,
    super.k,
    super.indexDocId,
    super.mediaDocId,
    super.lessonIndex,
    super.segmentIndex,
    super.sort,
    super.indexDocUrl,
    super.indexDocPath,
    super.mediaDocPath,
  );

  static SegmentContent from(SegmentContentInDb d) {
    return SegmentContent(
      d.crn,
      d.k,
      d.indexDocId,
      d.mediaDocId,
      d.lessonIndex,
      d.segmentIndex,
      d.sort,
      d.indexDocUrl,
      d.indexDocPath,
      d.mediaDocPath,
    );
  }
}
