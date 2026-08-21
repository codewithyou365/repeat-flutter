import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:repeat_flutter/db/entity/book.dart';
import 'package:repeat_flutter/logic/model/classroom_content.dart';

Book book(String content) => Book(
      classroomId: 1,
      desc: '',
      enable: true,
      url: '',
      content: content,
      contentVersion: 0,
      sort: 0,
      createTime: 0,
      updateTime: 0,
    );

void main() {
  test('书名从 content 的 n 里读出来', () {
    expect(book('{"n":"书名","s":"video"}').name, '书名');
  });

  test('content 没有 n、是空串、或者根本不是 JSON，都返回空名字而不是抛', () {
    expect(book('{"s":"video"}').name, '');
    expect(book('').name, '');
    expect(book('not json').name, '');
    expect(book('[]').name, '');
    expect(book('{"n":123}').name, '');
  });

  test('改书名只动 n，其他内容原样留着', () {
    final b = book('{"s":"video","d":[{"h":"x"}]}');
    b.name = '新名字';

    final map = jsonDecode(b.content) as Map<String, dynamic>;
    expect(map['n'], '新名字');
    expect(map['s'], 'video');
    expect(map['d'], [
      {'h': 'x'}
    ]);
    expect(b.name, '新名字');
  });

  test('content 换掉之后 name 跟着变（缓存不会读到旧值）', () {
    final b = book('{"n":"旧"}');
    expect(b.name, '旧');
    b.content = '{"n":"新"}';
    expect(b.name, '新');
  });

  test('withName 往一段内容里塞名字，坏内容也不会炸', () {
    expect(jsonDecode(Book.withName('{"s":"a"}', 'x')), {'s': 'a', 'n': 'x'});
    expect(jsonDecode(Book.withName('', 'x')), {'n': 'x'});
    expect(jsonDecode(Book.withName('[]', 'x')), {'n': 'x'});
  });

  test('课堂文档的保留 key', () {
    // 'b' 是课堂文档里的书本数组，'i' 是每本书的 id
    expect(ClassroomDocField.books, 'b');
    expect(ClassroomDocField.bookId, 'i');
    // 书名不是元数据，就是内容里的一个普通 key
    expect(bookNameKey, 'n');
  });
}
