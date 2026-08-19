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

  /// 提示的定义数组，跟游戏 'g'、课堂级下载 'd' 并排放在 [Classroom.content] 里：
  ///
  /// ```json
  /// "t":[{"n":"词源","fontSize":"18.0","fontAlias":"X.ttf","fontHash":"..",
  ///       "h":"..","k":"..","s":"..","i":3},
  ///      {"n":"语法"}]
  /// ```
  ///
  /// 每一条就是 VerseField 的「字段块」，结构跟 book/verse 那层的 't' 完全一样，
  /// 所以读写直接用 VerseField.of/getStr/setStr/ref/tipNameOf/ensureTipCount。
  /// 放的只有名字（'n'）、字体（'fontSize'/'fontAlias'/'fontHash'）和提示服务配置
  /// （'h'/'k'/'s'/'i'）——正文/媒体/区间仍然逐节存在 Verse.content 的 't' 里。
  ///
  /// **下标就是提示的身份**：课堂的第 i 条名字配的就是每一节第 i 条正文，
  /// 所以这个数组只能在末尾加、清空某一条只能就地留个空块，绝不能从中间 removeAt。
  /// 字体文件和提示服务的 zip 都从课堂自己的 'd' 里找，落在
  /// [DocPath.getFilesRelativePathOf] 下（跟游戏一样）。
  static const String tips = 't';

  /// 游戏条目（'g' 里的每一项）在网络编辑时多出来的一个 key：游戏自己的数据。
  ///
  /// 它不存在 [Classroom.content] 里，真身是 Game 表的 data 列——游戏 JS 用
  /// setData/getData 读写的那份。为了能在网络编辑里改它，出去时按 'i' 从库里取出来
  /// 塞进这个 key（[ClassroomDocHelp.fillGameData]），提交时再摘走写回 Game 表
  /// （[ClassroomDocHelp.takeGameData]），所以它始终不会落进 Classroom.content。
  ///
  /// 库里存的是一个 JSON 字符串，为了好编辑，能解析就以对象/数组的原样放进文档，
  /// 解析不了才退回字符串；写回时反过来。对外分享的文档不带它（跟 'i' 一样）。
  ///
  /// 注意这个 'd' 在游戏条目里面，跟课堂顶层那个下载清单 'd' 是两回事，互不影响。
  static const String gameData = 'd';

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
