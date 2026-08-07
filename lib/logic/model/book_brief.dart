/// 书本的轻量视图：只留 id、书名、排序。
///
/// [Book.content] 可能挺大（'d' 下载列表），但页面真正要的往往只是书名。
/// 加载时解析出名字就把 content 丢掉，拿着它的页面只常驻几十个短字符串。
/// 需要正文的场景请单独查 [BookDao.getContentById]，别把 content 存进来。
class BookBrief {
  final int bookId;
  final String name;
  final int sort;

  const BookBrief({
    required this.bookId,
    required this.name,
    required this.sort,
  });
}
