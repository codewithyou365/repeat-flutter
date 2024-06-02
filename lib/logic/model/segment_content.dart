import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/segment.dart';
import 'package:repeat_flutter/widget/player_bar/player_bar.dart';

@Entity(tableName: "")
class SegmentContentInDb extends Segment {
  @primaryKey
  final String crn;
  final String k;
  final String indexDocUrl;
  final String indexDocPath;
  final String mediaDocPath;

  SegmentContentInDb(
    super.segmentKeyId,
    super.indexDocId,
    super.mediaDocId,
    super.lessonIndex,
    super.segmentIndex,
    super.sort,
    this.crn,
    this.k,
    this.indexDocUrl,
    this.indexDocPath,
    this.mediaDocPath,
  );
}

class SegmentContent extends SegmentContentInDb {
  List<MediaSegment> qMediaSegments = [];
  List<MediaSegment> aMediaSegments = [];
  MediaSegment? titleMediaSegment;
  var title = "";
  var prevAnswer = "";
  var question = "";
  var tip = "";
  var answer = "";

  SegmentContent(
    super.segmentKeyId,
    super.indexDocId,
    super.mediaDocId,
    super.lessonIndex,
    super.segmentIndex,
    super.sort,
    super.crn,
    super.k,
    super.indexDocUrl,
    super.indexDocPath,
    super.mediaDocPath,
  );

  static SegmentContent from(SegmentContentInDb d) {
    return SegmentContent(
      d.segmentKeyId,
      d.indexDocId,
      d.mediaDocId,
      d.lessonIndex,
      d.segmentIndex,
      d.sort,
      d.crn,
      d.k,
      d.indexDocUrl,
      d.indexDocPath,
      d.mediaDocPath,
    );
  }
}
