// entity/book.dart

import 'dart:convert' as convert;

import 'package:floor/floor.dart';

/// 书名在 [content] 的 'n' 里，见 [Book.name]。
const String bookNameKey = 'n';

@Entity(
  indices: [
    Index(value: ['classroomId', 'sort'], unique: true),
    Index(value: ['classroomId', 'updateTime']),
    Index(value: ['sort', 'id']),
  ],
)
class Book {
  @PrimaryKey(autoGenerate: true)
  final int? id;

  final int classroomId;

  String desc;
  bool enable;
  String url;
  String content;
  int contentVersion;
  int sort;
  int createTime;
  int updateTime;

  Book({
    this.id,
    required this.classroomId,
    required this.desc,
    required this.enable,
    required this.url,
    required this.content,
    required this.contentVersion,
    required this.sort,
    required this.createTime,
    required this.updateTime,
  });

  /// 解析结果按 content 原串缓存：书本列表里 name 会被反复读，
  /// content 可能挺大（'d' 下载列表），不能每次都 jsonDecode。
  @ignore
  String? nameCache;
  @ignore
  String? nameCacheSource;

  /// 书名。**不是数据库列**，就存在 [content] 的 'n' 里，
  /// 这样网络编辑的课堂文档里改书名就是改内容，不用另外一套元数据。
  /// SQL 里查不到书名 —— 用 json_extract 的话要 SQLite 的 JSON1 扩展，
  /// Android 11 以下没有，而 minSdk 是 24。所以 BookShow 自己带着 content 直接解析，
  /// ChapterShow / VerseShow 按 bookId 从 BookHelp 缓存里查。
  String get name {
    if (!identical(nameCacheSource, content)) {
      nameCacheSource = content;
      nameCache = nameOf(content);
    }
    return nameCache ?? '';
  }

  set name(String value) {
    Map<String, dynamic> map;
    try {
      map = convert.jsonDecode(content) as Map<String, dynamic>;
    } catch (e) {
      map = {};
    }
    map[bookNameKey] = value;
    content = convert.jsonEncode(map);
  }

  static String nameOf(String content) {
    try {
      final map = convert.jsonDecode(content);
      if (map is Map && map[bookNameKey] is String) {
        return map[bookNameKey] as String;
      }
    } catch (e) {
      // content 还没内容（新建的空书）就没有名字
    }
    return '';
  }

  /// 往一段 content 里塞书名，不动其他 key
  static String withName(String content, String name) {
    Map<String, dynamic> map;
    try {
      map = convert.jsonDecode(content) as Map<String, dynamic>;
    } catch (e) {
      map = {};
    }
    map[bookNameKey] = name;
    return convert.jsonEncode(map);
  }

  static Book empty() {
    return Book(
      id: null,
      classroomId: 0,
      desc: '',
      enable: false,
      url: '',
      content: '',
      contentVersion: 0,
      sort: 0,
      createTime: 0,
      updateTime: 0,
    );
  }
}
