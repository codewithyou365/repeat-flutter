import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/verse.dart';

@Entity(tableName: "")
class VerseContentInDb extends Verse {
  @primaryKey
  final String contentName;

  VerseContentInDb({
    required super.verseKeyId,
    required super.classroomId,
    required super.bookSerial,
    required super.chapterIndex,
    required super.verseIndex,
    required super.sort,
    required this.contentName,
  });
}

class VerseContent extends VerseContentInDb {
  var mediaDocPath = "";
  var mediaHash = "";
  var mediaExtension = "";
  var prevAnswer = "";
  var question = "";
  var tip = "";
  var answer = "";
  var aStart = "";
  var aEnd = "";
  var word = "";
  var k = "";
  var miss = false;

  VerseContent({
    required super.verseKeyId,
    required super.classroomId,
    required super.bookSerial,
    required super.chapterIndex,
    required super.verseIndex,
    required super.sort,
    required super.contentName,
  });

  static VerseContent empty() {
    return VerseContent(
      verseKeyId: 0,
      classroomId: 0,
      bookSerial: 0,
      chapterIndex: 0,
      verseIndex: 0,
      sort: 0,
      contentName: "",
    );
  }

  static VerseContent from(VerseContentInDb d) {
    return VerseContent(
      verseKeyId: d.verseKeyId,
      classroomId: d.classroomId,
      bookSerial: d.bookSerial,
      chapterIndex: d.chapterIndex,
      verseIndex: d.verseIndex,
      sort: d.sort,
      contentName: d.contentName,
    );
  }
}
