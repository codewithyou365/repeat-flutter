import 'package:get/get.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/logic/widget/book_editor/book_editor_args.dart';
import 'package:repeat_flutter/logic/widget/book_editor/book_editor_logic.dart';

/// 材料页的"网络编辑"。和分享页一样：网络只在这一页存活，退出页面就关掉。
class ScCrMaterialEditLogic extends GetxController {
  static const String id = BookEditorLogic.id;
  late final BookEditorLogic<ScCrMaterialEditLogic> editor = BookEditorLogic<ScCrMaterialEditLogic>(this);

  @override
  void onInit() {
    super.onInit();
    initArgs();
  }

  /// 从材料页进来没有"当前句子"，默认落在当前课堂的第一本可用书上；
  /// 一本都没有时给 0，网页那边自己会去 /classroom 里挑。
  Future<void> initArgs() async {
    var books = await Db().db.bookDao.getByEnable(Classroom.curr, true);
    var bookId = books.isNotEmpty ? books.first.id! : 0;
    editor.setArgs(BookEditorArgs(bookId: bookId, chapterIndex: 0, verseIndex: 0));
  }

  @override
  void onClose() {
    super.onClose();
    editor.switchWeb(false);
  }
}
