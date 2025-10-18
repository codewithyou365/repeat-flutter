import 'dart:convert' as convert;

import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/date.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/book.dart';
import 'package:repeat_flutter/db/entity/chapter.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/content_version.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';
import 'package:repeat_flutter/db/entity/verse.dart';
import 'package:repeat_flutter/db/entity/verse_content_version.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/cache_help.dart';
import 'package:repeat_flutter/logic/event_bus.dart';
import 'package:repeat_flutter/logic/model/verse_show.dart';
import 'package:repeat_flutter/logic/verse_help.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

@dao
abstract class VerseDao {
  late AppDatabase db;

  @Update(onConflict: OnConflictStrategy.fail)
  Future<void> updateOrFail(List<Verse> entities);

  @Query('SELECT * FROM Verse where id=:id')
  Future<Verse?> getById(int id);

  @Query('SELECT * FROM Verse where bookId=:bookId')
  Future<List<Verse>> findByBookId(int bookId);

  @Query(
    'SELECT * FROM Verse'
    ' WHERE bookId=:bookId'
    ' AND chapterIndex=:chapterIndex'
    ' AND verseIndex=:verseIndex',
  )
  Future<Verse?> getByIndex(int bookId, int chapterIndex, int verseIndex);

  @Query(
    'SELECT * FROM Verse'
    ' WHERE bookId=:bookId AND chapterIndex>=:minChapterIndex order by chapterIndex,verseIndex limit 1',
  )
  Future<Verse?> last(int bookId, int minChapterIndex);

  @Query(
    'SELECT * FROM Verse'
    ' WHERE bookId=:bookId AND chapterIndex=:chapterIndex AND verseIndex>=:minVerseIndex',
  )
  Future<List<Verse>> findByMinVerseIndex(int bookId, int chapterIndex, int minVerseIndex);

  @Query(
    'DELETE FROM Verse'
    ' WHERE bookId=:bookId AND chapterIndex=:chapterIndex AND verseIndex>=:minVerseIndex',
  )
  Future<void> deleteByMinVerseIndex(int bookId, int chapterIndex, int minVerseIndex);

  @Query(
    'SELECT * FROM Verse'
    ' WHERE bookId=:bookId AND chapterIndex>=:minChapterIndex order by chapterIndex,verseIndex',
  )
  Future<List<Verse>> findByMinChapterIndex(int bookId, int minChapterIndex);

  @Query(
    'DELETE FROM Verse'
    ' WHERE bookId=:bookId AND chapterIndex>=:minChapterIndex',
  )
  Future<void> deleteByMinChapterIndex(int bookId, int minChapterIndex);

  @Query('DELETE FROM Verse WHERE classroomId=:classroomId')
  Future<void> deleteByClassroomId(int classroomId);

  @Query(
    'SELECT id FROM Verse'
    ' WHERE bookId=:bookId',
  )
  Future<List<int>> getIds(int bookId);

  @Query(
    'DELETE FROM Verse'
    ' WHERE Verse.bookId=:bookId',
  )
  Future<void> deleteByBookId(int bookId);

  @Query('DELETE FROM Verse WHERE chapterId=:chapterId')
  Future<void> deleteByChapterKeyId(int chapterId);

  @Query(
    'UPDATE Verse'
    ' SET contentVersion = ('
    ' SELECT MAX(version)'
    ' FROM VerseContentVersion'
    ' WHERE VerseContentVersion.verseId = Verse.id'
    ' AND VerseContentVersion.bookId = Verse.bookId'
    ' )'
    ' WHERE bookId = :bookId',
  )
  Future<void> syncContentVersion(int bookId);

  @Query(
    'SELECT count(1) FROM Verse'
    ' WHERE id in (:ids)',
  )
  Future<int?> countByIds(List<int> ids);

  @Insert(onConflict: OnConflictStrategy.fail)
  Future<void> insertOrFail(List<Verse> entities);

  @Query('UPDATE Verse set note=:note,noteVersion=:noteVersion WHERE id=:id')
  Future<void> updateNote(int id, String note, int noteVersion);

  @Query('UPDATE Verse set content=:content,contentVersion=:contentVersion WHERE id=:id')
  Future<void> updateContent(int id, String content, int contentVersion);

  Future<void> deleteByChapter(Book book, Chapter chapter) async {
    int chapterIndex = chapter.chapterIndex;
    return deleteByChapterIndexes(book.id!, book.sort, [chapterIndex]);
  }

  Future<void> deleteByChapterIndexes(int bookId, int bookSort, List<int> chapterIndexes) async {
    chapterIndexes = chapterIndexes.toSet().toList()..sort();

    int minIndex = chapterIndexes.first;
    List<Verse> entities = await findByMinChapterIndex(bookId, minIndex);

    List<Verse> inserts = [];

    for (var entity in entities) {
      if (chapterIndexes.contains(entity.chapterIndex)) {
        continue;
      }

      int shift = chapterIndexes.where((idx) => idx < entity.chapterIndex).length;
      entity.chapterIndex -= shift;
      entity.sort = bookSort * 10000000000 + entity.chapterIndex * 100000 + entity.verseIndex;
      inserts.add(entity);
    }

    await deleteByMinChapterIndex(bookId, minIndex);
    await updateOrFail(inserts);
  }

  Future<void> deleteByVerse(Book book, Verse verse) async {
    return deleteByVerseIndexes(book.id!, book.sort, verse.chapterIndex, [verse.verseIndex]);
  }

  Future<void> deleteByVerseIndexes(int bookId, int bookSort, int chapterIndex, List<int> verseIndexes) async {
    verseIndexes = verseIndexes.toSet().toList()..sort();

    int minIndex = verseIndexes.first;
    List<Verse> entities = await findByMinVerseIndex(bookId, chapterIndex, minIndex);

    List<Verse> needToInserts = [];

    for (var entity in entities) {
      if (verseIndexes.contains(entity.verseIndex)) {
        continue;
      }

      int shift = verseIndexes.where((idx) => idx < entity.chapterIndex).length;
      entity.verseIndex -= shift;
      entity.sort = bookSort * 10000000000 + entity.chapterIndex * 100000 + entity.verseIndex;
      needToInserts.add(entity);
    }

    await deleteByMinVerseIndex(bookId, chapterIndex, minIndex);
    await insertOrFail(needToInserts);
  }

  Future<bool> delete(int verseId) async {
    var verse = await innerDelete(verseId);
    if (verse.id != null) {
      await CacheHelp.refreshVerse(
        query: QueryChapter(
          bookId: verse.bookId,
          chapterIndex: verse.chapterIndex,
        ),
      );
      EventBus().publish<int>(EventTopic.deleteVerse, null);
      return true;
    }
    return false;
  }

  @transaction
  Future<Verse> innerDelete(int verseId) async {
    var verse = await db.verseDao.getById(verseId);
    if (verse == null) {
      Snackbar.showAndThrow(I18nKey.labelDataAnomaly.trArgs(["cant find the data($verseId)"]));
      return Verse.empty();
    }
    Book? book = await db.bookDao.getById(verse.bookId);
    if (book == null) {
      Snackbar.showAndThrow(I18nKey.labelDataAnomaly.trArgs(["cant find the content data($verse.bookId)"]));
      return Verse.empty();
    }
    //await db.bookDao.deleteByClassroomId(classroomId);
    //await db.bookContentVersionDao.deleteByClassroomId(classroomId);
    //await db.chapterDao.deleteByClassroomId(classroomId);
    //await db.chapterContentVersionDao.deleteByClassroomId(classroomId);
    //await deleteById(classroomId);
    //await db.crKvDao.deleteByClassroomId(classroomId);
    await db.gameDao.deleteByVerseId(verseId);
    await db.gameUserInputDao.deleteByVerseId(verseId);
    //await db.timeStatsDao.deleteByClassroomId(classroomId);
    await deleteByVerse(book, verse);
    await db.verseContentVersionDao.deleteByVerseId(verseId);
    await db.verseReviewDao.deleteByVerseId(verseId);
    await db.verseStatsDao.deleteByVerseId(verseId);
    await db.verseTodayPrgDao.deleteByVerseId(verseId);
    return verse;
  }

  Future<void> addChapters(int bookId, int bookSort, List<Chapter> chapters) async {
    if (chapters.isEmpty) return;

    chapters = chapters.where((c) => c.bookId == bookId).toList();
    chapters.sort((a, b) => a.chapterIndex.compareTo(b.chapterIndex));

    List<int> insertionIndexes = chapters.map((c) => c.chapterIndex).toList();

    int minIndex = insertionIndexes.reduce((a, b) => a < b ? a : b);
    List<Verse> entities = await findByMinChapterIndex(bookId, minIndex);

    List<Verse> needToInserts = [];

    for (var entity in entities) {
      int shift = 0;

      for (var idx in insertionIndexes) {
        if (entity.chapterIndex >= idx) shift++;
      }

      entity.chapterIndex += shift;
      entity.sort = VerseHelp.toVerseSort(bookSort, entity.chapterIndex, entity.verseIndex);
      needToInserts.add(entity);
    }

    await deleteByMinChapterIndex(bookId, minIndex);
    await insertOrFail(needToInserts);
  }

  Future<void> addVerses(int bookId, int bookSort, int chapterIndex, List<Verse> newEntities) async {
    if (newEntities.isEmpty) return;

    newEntities = newEntities.where((c) => c.bookId == bookId && c.chapterIndex == chapterIndex).toList();
    newEntities.sort((a, b) => a.verseIndex.compareTo(b.verseIndex));

    List<int> newIndexes = newEntities.map((c) => c.verseIndex).toList();

    int minIndex = newIndexes.reduce((a, b) => a < b ? a : b);
    List<Verse> oldEntities = await findByMinVerseIndex(bookId, chapterIndex, minIndex);

    List<Verse> needToInserts = [];

    for (var entity in oldEntities) {
      int shift = 0;

      for (var idx in newIndexes) {
        if (entity.verseIndex >= idx) shift++;
      }

      entity.verseIndex += shift;
      entity.sort = VerseHelp.toVerseSort(bookSort, entity.chapterIndex, entity.verseIndex);
      needToInserts.add(entity);
    }

    await deleteByMinVerseIndex(bookId, chapterIndex, minIndex);
    needToInserts.addAll(newEntities);
    await insertOrFail(needToInserts);
  }

  Future<int> _innerAddVerse({
    required String content,
    required int bookId,
    required int chapterId,
    required int chapterIndex,
    required int verseIndex,
  }) async {
    var now = DateTime.now();
    int classroomId = Classroom.curr;
    Book? book = await db.bookDao.getById(bookId);
    if (book == null) {
      Snackbar.showAndThrow(I18nKey.labelDataAnomaly.trArgs(["book"]));
      return 0;
    }
    Verse verse = Verse(
      classroomId: classroomId,
      bookId: bookId,
      chapterId: chapterId,
      chapterIndex: chapterIndex,
      verseIndex: verseIndex,
      sort: VerseHelp.toVerseSort(book.sort, chapterIndex, verseIndex),
      content: content,
      contentVersion: 1,
      learnDate: Date.from(now),
      progress: 0,
    );
    await addVerses(bookId, book.sort, chapterIndex, [verse]);
    Verse? temp = await getByIndex(bookId, chapterIndex, verseIndex);
    if (temp == null) {
      Snackbar.showAndThrow(I18nKey.labelDataAnomaly.trArgs(["verse"]));
      return 0;
    } else {
      verse = temp;
    }
    await db.verseContentVersionDao.insertOrFail(
      VerseContentVersion(
        classroomId: verse.classroomId,
        bookId: verse.bookId,
        chapterId: verse.chapterId,
        verseId: verse.id!,
        version: 1,
        reason: VersionReason.editor,
        content: verse.content,
        createTime: now,
      ),
    );

    return verse.id!;
  }

  Future<int> addFirstVerse(
    int bookId,
    int chapterId,
    int chapterIndex,
  ) async {
    var verseId = await innerAddFirstVerse(bookId, chapterId, chapterIndex);
    if (verseId != 0) {
      await CacheHelp.refreshVerse(
        query: QueryChapter(
          bookId: bookId,
          chapterIndex: chapterIndex,
        ),
      );
      EventBus().publish<int>(EventTopic.addVerse, null);
    }
    return verseId;
  }

  @transaction
  Future<int> innerAddFirstVerse(
    int bookId,
    int chapterId,
    int chapterIndex,
  ) async {
    return _innerAddVerse(
      content: "{}",
      bookId: bookId,
      chapterId: chapterId,
      chapterIndex: chapterIndex,
      verseIndex: 0,
    );
  }

  Future<int> addVerse(VerseShow raw, int verseIndex) async {
    var verseId = await innerAddVerse(raw, verseIndex);
    if (verseId != 0) {
      await CacheHelp.refreshVerse(
        query: QueryChapter(
          bookId: raw.bookId,
          chapterIndex: raw.chapterIndex,
        ),
      );
      EventBus().publish<int>(EventTopic.addVerse, null);
    }
    return verseId;
  }

  @transaction
  Future<int> innerAddVerse(VerseShow raw, int verseIndex) async {
    return _innerAddVerse(
      content: raw.verseContent,
      bookId: raw.bookId,
      chapterId: raw.chapterId,
      chapterIndex: raw.chapterIndex,
      verseIndex: verseIndex,
    );
  }

  @transaction
  Future<void> updateVerseContent(int id, String content) async {
    var verse = await innerUpdateVerseContent(id, content);
    if (verse.id != null) {
      CacheHelp.updateVerseContent(verse);
      EventBus().publish<int>(EventTopic.updateVerseContent, id);
    }
  }

  @transaction
  Future<Verse> innerUpdateVerseContent(int id, String content) async {
    Verse? verse = await getById(id);
    if (verse == null) {
      Snackbar.showAndThrow(I18nKey.labelNotFoundVerse.trArgs([id.toString()]));
      return Verse.empty();
    }
    Map<String, dynamic> contentM;
    try {
      contentM = convert.jsonDecode(content);
      content = convert.jsonEncode(contentM);
    } catch (e) {
      Snackbar.showAndThrow(e.toString());
      return Verse.empty();
    }

    if (verse.content == content) {
      return Verse.empty();
    }

    var now = DateTime.now();
    await updateContent(id, content, verse.contentVersion + 1);
    await db.verseContentVersionDao.insertOrFail(
      VerseContentVersion(
        classroomId: verse.classroomId,
        bookId: verse.bookId,
        chapterId: verse.chapterId,
        verseId: id,
        version: verse.contentVersion + 1,
        reason: VersionReason.editor,
        content: content,
        createTime: now,
      ),
    );
    verse.content = content;
    verse.contentVersion++;
    //TODO remove updateVerseShowTime
    await db.crKvDao.insertOrReplace(CrKv(Classroom.curr, CrK.updateVerseShowTime, now.millisecondsSinceEpoch.toString()));
    return verse;
  }

  Future<List<Verse>> import(List<Chapter> chapters, List<Verse> list) async {
    Map<int, Chapter> chapterMap = {for (var chapter in chapters) chapter.chapterIndex: chapter};
    if (list.isNotEmpty) {
      for (var verse in list) {
        final chapter = chapterMap[verse.chapterIndex];
        if (chapter != null) {
          verse.chapterId = chapter.id!;
        }
      }
      int bookId = list.first.bookId;
      await insertOrFail(list);
      return findByBookId(bookId);
    }
    return [];
  }

  void fixChapterId(List<Chapter> insertChapters, List<Chapter> updateChapters, List<Verse> inserts, List<Verse> updates) {
    Map<int, Chapter> chapterIndex2Chapter = {};
    for (Chapter chapter in insertChapters) {
      chapterIndex2Chapter[chapter.chapterIndex] = chapter;
    }
    for (Chapter chapter in updateChapters) {
      chapterIndex2Chapter[chapter.chapterIndex] = chapter;
    }
    for (Verse verse in inserts) {
      verse.chapterId = chapterIndex2Chapter[verse.chapterIndex]!.id!;
    }
    for (Verse verse in updates) {
      verse.chapterId = chapterIndex2Chapter[verse.chapterIndex]!.id!;
    }
  }

  Future<List<int>> reimport(int bookId, List<Chapter> insertChapters, List<Chapter> updateChapters, List<Verse> inserts, List<Verse> updates) async {
    fixChapterId(insertChapters, updateChapters, inserts, updates);
    var ids = await getIds(bookId);
    await deleteByBookId(bookId);
    await insertOrFail(inserts);
    var newInserts = await findByBookId(bookId);
    inserts.sort((a, b) => a.sort.compareTo(b.sort));
    newInserts.sort((a, b) => a.sort.compareTo(b.sort));
    for (int i = 0; i < inserts.length; i++) {
      inserts[i].id = newInserts[i].id;
    }
    await insertOrFail(updates);

    var keptIds = <int>{...inserts.map((c) => c.id!), ...updates.map((c) => c.id!)};

    var deletedIds = ids.where((id) => !keptIds.contains(id)).toList();
    return deletedIds;
  }
}
