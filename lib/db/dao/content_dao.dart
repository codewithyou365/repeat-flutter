// dao/content_dao.dart

import 'dart:convert' as convert;

import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/num.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/content.dart';
import 'package:repeat_flutter/db/entity/text_version.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/model/book_show.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

@dao
abstract class ContentDao {
  late AppDatabase db;
  static BookShow? Function(int chapterKeyId)? getBookShow;
  static List<void Function(int chapterKeyId)> setBookShowContent = [];

  @Query('SELECT id bookId'
      ',name'
      ',sort'
      ',content bookContent'
      ',contentVersion bookContentVersion'
      ' FROM Content where classroomId=:classroomId and hide=false and docId!=0 ORDER BY sort')
  Future<List<BookShow>> getAllBook(int classroomId);

  @Query('SELECT * FROM Content where classroomId=:classroomId and hide=false ORDER BY sort')
  Future<List<Content>> getAllContent(int classroomId);

  @Query('SELECT max(verseWarning) FROM Content where classroomId=:classroomId and docId!=0 and hide=false')
  Future<bool?> hasWarning(int classroomId);

  @Query('SELECT * FROM Content where classroomId=:classroomId and docId!=0 and hide=false ORDER BY sort')
  Future<List<Content>> getAllEnableContent(int classroomId);

  @Query('SELECT ifnull(max(serial),0) FROM Content WHERE classroomId=:classroomId')
  Future<int?> getMaxSerial(int classroomId);

  @Query('SELECT ifnull(serial,0) FROM Content WHERE classroomId=:classroomId and serial=:serial')
  Future<int?> existBySerial(int classroomId, int serial);

  @Query('SELECT ifnull(max(sort),0) FROM Content WHERE classroomId=:classroomId')
  Future<int?> getMaxSort(int classroomId);

  @Query('SELECT ifnull(sort,0) FROM Content WHERE classroomId=:classroomId and sort=:sort')
  Future<int?> existBySort(int classroomId, int sort);

  @Query('SELECT * FROM Content WHERE id=:id')
  Future<Content?> getById(int id);

  @Query('SELECT * FROM Content WHERE classroomId=:classroomId and serial=:serial')
  Future<Content?> getBySerial(int classroomId, int serial);

  @Query('SELECT * FROM Content WHERE classroomId=:classroomId and name=:name')
  Future<Content?> getContentByName(int classroomId, String name);

  @Query('UPDATE Content set content=:content,contentVersion=:contentVersion WHERE Content.id=:id')
  Future<void> updateContentVersion(int id, String content, int contentVersion);

  @Query('UPDATE Content set docId=:docId,url=:url,chapterWarning=:chapterWarning,verseWarning=:verseWarning,updateTime=:updateTime WHERE Content.id=:id')
  Future<void> updateContent(int id, int docId, String url, bool chapterWarning, bool verseWarning, int updateTime);

  @Query('UPDATE Content set chapterWarning=:chapterWarning,verseWarning=:verseWarning,updateTime=:updateTime WHERE Content.id=:id')
  Future<void> updateContentWarning(int id, bool chapterWarning, bool verseWarning, int updateTime);

  @Query('UPDATE Content set chapterWarning=:chapterWarning,updateTime=:updateTime WHERE Content.id=:id')
  Future<void> updateContentWarningForChapter(int id, bool chapterWarning, int updateTime);

  @Query('UPDATE Content set verseWarning=:verseWarning,updateTime=:updateTime WHERE Content.id=:id')
  Future<void> updateContentWarningForVerse(int id, bool verseWarning, int updateTime);

  @Insert(onConflict: OnConflictStrategy.fail)
  Future<void> insertContent(Content entity);

  @Query('UPDATE Content set hide=true'
      ' WHERE Content.id=:id')
  Future<void> hide(int id);

  @Query('UPDATE Content set hide=false'
      ' WHERE Content.id=:id')
  Future<void> showContent(int id);

  @Query('UPDATE Content set docId=:docId'
      ' WHERE Content.id=:id')
  Future<void> updateDocId(int id, int docId);

  @transaction
  Future<void> updateBookContent(int bookId, String content) async {
    Content? book = await getById(bookId);
    if (book == null) {
      Snackbar.show(I18nKey.labelNotFoundVerse.trArgs([bookId.toString()]));
      return;
    }

    try {
      Map<String, dynamic> contentM = convert.jsonDecode(content);
      content = convert.jsonEncode(contentM);
    } catch (e) {
      Snackbar.show(e.toString());
      return;
    }

    if (book.content == content) {
      return;
    }

    var now = DateTime.now();
    await updateContentVersion(bookId, content, book.contentVersion + 1);
    await db.textVersionDao.insertOrIgnore(TextVersion(
      t: TextVersionType.bookContent,
      id: bookId,
      version: book.contentVersion + 1,
      reason: TextVersionReason.editor,
      text: content,
      createTime: now,
    ));
    if (getBookShow != null) {
      BookShow? bookShow = getBookShow!(bookId);
      if (bookShow != null) {
        bookShow.bookContent = content;
        for (var set in setBookShowContent) {
          set(bookId);
        }
        bookShow.bookContentVersion++;
      }
    }
  }

  @transaction
  Future<Content> add(String name) async {
    await db.lockDao.forUpdate();
    var ret = await getContentByName(Classroom.curr, name);
    if (ret != null) {
      if (ret.hide == false) {
        Snackbar.show(I18nKey.labelDataDuplication.tr);
        return ret;
      }
      await showContent(ret.id!);
    } else {
      var maxSerial = await getMaxSerial(Classroom.curr);
      var serial = await Num.getNextId(maxSerial, id: Classroom.curr, existById2: existBySerial);

      var maxSort = await getMaxSort(Classroom.curr);
      var sort = await Num.getNextId(maxSort, id: Classroom.curr, existById2: existBySort);

      var now = DateTime.now().millisecondsSinceEpoch;
      ret = Content(
        classroomId: Classroom.curr,
        serial: serial,
        name: name,
        desc: '',
        docId: 0,
        url: '',
        content: '',
        contentVersion: 0,
        sort: sort,
        hide: false,
        chapterWarning: false,
        verseWarning: false,
        createTime: now,
        updateTime: now,
      );
      await insertContent(ret);
    }
    return ret;
  }

  Future<void> import(int contentSerial, String content) async {
    Content? oldContent = await getBySerial(Classroom.curr, contentSerial);
    TextVersion? oldContentVersion = await db.textVersionDao.getTextForContent(contentSerial, oldContent!.contentVersion);

    if (oldContentVersion == null || oldContentVersion.text != content) {
      var maxVersion = oldContent.contentVersion;
      var nextVersion = maxVersion + 1;
      TextVersion insertContentVersion = TextVersion(
        t: TextVersionType.bookContent,
        id: oldContent.serial,
        version: nextVersion,
        reason: TextVersionReason.import,
        text: content,
        createTime: DateTime.now(),
      );
      await db.textVersionDao.insertOrIgnore(insertContentVersion);
      await updateContentVersion(oldContent.id!, content, nextVersion);
    }
  }
}
