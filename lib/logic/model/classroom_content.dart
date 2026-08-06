/// 课堂级文档的字段约定。
///
/// 课堂文档 = [Classroom.content] 的所有 key + 一个 [books] 数组，数组里是每本书的完整文档
/// （就是单本书网络编辑/分享用的那份，含 'c' 章节和句子），只多一个 'i' 书本 id：
///
/// ```json
/// {"s":"...", "d":[...],        // 课堂自己的内容，来自 Classroom.content
///  "b":[                        // ClassroomDocField.books
///    {"i":4, "n":"书名", "s":"...", "d":[...], "c":[...]},
///    {...}
///  ]}
/// ```
///
/// 书名 'n' 本来就是书本内容的一部分（见 [Book.name]），不是额外挂上去的元数据。
/// desc / sort / enable / url 这些不在文档里，只能在 App 里改。
class ClassroomDocField {
  /// 课堂文档里书本数组的 key。这个 key 不会存进 Classroom.content。
  static const String books = 'b';

  /// 书本 id。只在网络编辑（databaseData=true）时带上：
  /// 有 id 就是改已有的书，没 id 就是新建一本。
  /// 对外分享的文档不带它，所以导入方一律新建。
  static const String bookId = 'i';

  /// 单本网络编辑（/book + /commit）时挂在书本文档最前面的课堂内容，
  /// 内容就是 [Classroom.content]（游戏 'g'、课堂媒体 'd' 等），
  /// 让"只编辑一本书"也能看到并改到课堂级的东西：
  ///
  /// ```json
  /// {"cr":{"g":[...],"d":[...]}, "n":"书名", "s":"...", "d":[...], "c":[...]}
  /// ```
  ///
  /// 只用于网络编辑，不会存进 [Book.content]，提交时会被摘出来单独写回课堂。
  /// 课堂级编辑（All books）不用它——那边课堂内容本来就在文档顶层。
  static const String classroom = 'cr';
}
