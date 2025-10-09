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

class ScCrState {
  List<VerseTodayPrgInView> verses = [];
  List<VerseTodayPrg> all = [];
  List<VerseTodayPrg> learn = [];
  List<VerseTodayPrg> review = [];
  List<VerseTodayPrg> fullCustom = [];

  var learnedTotalCount = 0;
  var learnTotalCount = 0;
  var learnDeadlineTips = "";
  int learnDeadline = 0;
}
