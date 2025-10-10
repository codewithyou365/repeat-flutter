import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/book.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/widget/overlay/overlay.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

class ForAdd {
  List<Book> books = [];
  List<String> bookNames = [];
  int maxChapter = 1;
  int maxVerse = 1;

  Book? fromBook;
  int fromBookIndex = 0;
  int fromChapterIndex = 0;
  int fromVerseIndex = 0;
  int count = 1;
}

class FullCustom<T extends GetxController> {
  static const String bodyId = "FullCustom.bodyId";
  ForAdd forAdd = ForAdd();
  final T parentLogic;

  FullCustom(this.parentLogic);

  Future<void> show(BuildContext context, VoidCallback callback) async {
    final Size screenSize = MediaQuery.of(context).size;
    var ok = await initForAdd();
    if (!ok) {
      return;
    }
    return showModalBottomSheet(
      context: Get.context!,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return SizedBox(
          width: screenSize.width,
          height: screenSize.height / 3.5,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.0.w, vertical: 20.0),
            child: ListView(
              children: [
                Row(
                  children: [
                    const Spacer(),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await addSchedule();
                        callback();
                      },
                      child: Text(I18nKey.btnOk.tr),
                    ),
                    SizedBox(width: 5.w),
                  ],
                ),
                const SizedBox(height: 20),
                GetBuilder<T>(
                  id: bodyId,
                  builder: (_) {
                    return Row(
                      children: [
                        Card(
                          elevation: 8.0,
                          color: Theme.of(context).secondaryHeaderColor,
                          child: Row(
                            children: [
                              cupertinoItem(['', I18nKey.labelBook.tr], selectBook, null, select: forAdd.bookNames),
                              cupertinoItem([I18nKey.labelFrom.tr, I18nKey.labelChapter.tr], selectChapter, initChapter, count: forAdd.maxChapter),
                              cupertinoItem(['', I18nKey.labelVerse.tr], selectVerse, initVerse, count: forAdd.maxVerse),
                            ],
                          ),
                        ),
                        const Spacer(),
                        cupertinoItem([I18nKey.btnAdd.tr, I18nKey.labelScheduleCount.tr], selectCount, null, count: 100),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget cupertinoItem(List<String> titles, ValueChanged<int> changed, GestureTapCallback? tap, {List<String>? select, int? count}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (tap != null) tap();
    });
    return Column(
      children: [
        for (var title in titles) Text(title),
        const SizedBox(height: 3),
        SizedBox(
          width: 80.w,
          height: 64,
          child: count != null && count < 0
              ? CupertinoPicker(
                  itemExtent: 32.0,
                  onSelectedItemChanged: changed,
                  children: List.generate(1, (index) {
                    return Center(child: Text("${index + 1}"));
                  }),
                )
              : CupertinoPicker(
                  itemExtent: 32.0,
                  onSelectedItemChanged: changed,
                  children: count != null
                      ? List.generate(count, (index) {
                          return Center(child: Text("${index + 1}"));
                        })
                      : List.generate(select!.length, (index) {
                          return Center(child: Text(select[index]));
                        }),
                ),
        ),
      ],
    );
  }

  // for add schedule

  Future<bool> initForAdd() async {
    forAdd.books = await Db().db.bookDao.getByEnable(Classroom.curr, true);
    forAdd.bookNames = forAdd.books.map((e) => e.name).toList();
    if (forAdd.books.isEmpty) {
      Snackbar.show(I18nKey.labelNoContent.tr);
      return false;
    }
    await showTransparentOverlay(() async {
      forAdd.maxChapter = -1;
      forAdd.maxVerse = -1;
      forAdd.fromBook = forAdd.books[0];
      await initChapter(updateView: false);
      await initVerse(updateView: false);
      forAdd.fromBookIndex = 0;
      forAdd.fromChapterIndex = 0;
      forAdd.fromVerseIndex = 0;
      forAdd.count = 1;
    });
    return true;
  }

  Future<void> initChapter({bool updateView = true}) async {
    if (forAdd.maxChapter < 0) {
      var bookId = forAdd.fromBook!.id!;
      var maxChapter = await Db().db.scheduleDao.getMaxChapterIndex(bookId);
      forAdd.maxChapter = (maxChapter ?? 1) + 1;
      if (updateView) {
        parentLogic.update([bodyId]);
      }
    }
  }

  Future<void> initVerse({bool updateView = true}) async {
    if (forAdd.maxChapter < 0) {
      return;
    }
    if (forAdd.maxVerse < 0) {
      var bookId = forAdd.fromBook!.id!;
      var maxVerse = await Db().db.scheduleDao.getMaxVerseIndex(bookId, forAdd.fromChapterIndex);
      forAdd.maxVerse = (maxVerse ?? 1) + 1;
      if (updateView) {
        parentLogic.update([bodyId]);
      }
    }
  }

  void selectBook(int bookIndex) async {
    var book = forAdd.books[bookIndex];
    forAdd.maxChapter = -1;
    forAdd.maxVerse = -1;
    forAdd.fromBook = book;
    forAdd.fromBookIndex = bookIndex;
    forAdd.fromChapterIndex = 0;
    forAdd.fromVerseIndex = 0;

    parentLogic.update([bodyId]);
  }

  void selectChapter(int chapterIndex) async {
    forAdd.maxVerse = -1;
    forAdd.fromChapterIndex = chapterIndex;
    forAdd.fromVerseIndex = 0;
    parentLogic.update([bodyId]);
  }

  void selectVerse(int verseIndex) async {
    forAdd.fromVerseIndex = verseIndex;
  }

  void selectCount(int count) async {
    forAdd.count = count + 1;
  }

  Future<void> addSchedule() async {
    if (forAdd.maxChapter < 0) {
      return;
    }
    if (forAdd.maxVerse < 0) {
      return;
    }
    await Db().db.scheduleDao.addFullCustom(
      forAdd.fromBook!.id!,
      forAdd.fromChapterIndex,
      forAdd.fromVerseIndex,
      forAdd.count,
    );
  }
}
