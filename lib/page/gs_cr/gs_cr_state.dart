import 'package:repeat_flutter/db/entity/book.dart';
import 'package:repeat_flutter/db/entity/verse_today_prg.dart';

class VerseTodayPrgInView {
  int index;
  int uniqIndex;
  String name;
  TodayPrgType type;
  String groupDesc;
  String desc;

  List<VerseTodayPrg> verses;

  VerseTodayPrgInView(
    this.verses, {
    this.index = 0,
    this.uniqIndex = 0,
    this.name = "",
    this.type = TodayPrgType.none,
    this.groupDesc = "",
    this.desc = "",
  });
}

class ForAdd {
  List<Book> contents = [];
  List<String> bookNames = [];
  int maxChapter = 1;
  int maxVerse = 1;

  Book? fromBook;
  int fromContentIndex = 0;
  int fromChapterIndex = 0;
  int fromVerseIndex = 0;
  int count = 1;
}

class GsCrState {
  List<VerseTodayPrgInView> verses = [];
  List<VerseTodayPrg> all = [];
  List<VerseTodayPrg> learn = [];
  List<VerseTodayPrg> review = [];
  List<VerseTodayPrg> fullCustom = [];

  ForAdd forAdd = ForAdd();

  var learnedTotalCount = 0;
  var learnTotalCount = 0;
  var learnDeadlineTips = "";
  int learnDeadline = 0;
}
