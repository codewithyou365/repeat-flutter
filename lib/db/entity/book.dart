// entity/book.dart

import 'package:floor/floor.dart';

@Entity(
  indices: [
    Index(value: ['classroomId', 'name'], unique: true),
    Index(value: ['classroomId', 'sort'], unique: true),
    Index(value: ['classroomId', 'updateTime']),
    Index(value: ['sort', 'id']),
  ],
)
class Book {
  @PrimaryKey(autoGenerate: true)
  final int? id;

  final int classroomId;

  String name;
  String desc;
  int docId;
  String url;
  String content;
  int contentVersion;
  int sort;
  bool hide;
  int createTime;
  int updateTime;

  Book({
    this.id,
    required this.classroomId,
    required this.name,
    required this.desc,
    required this.docId,
    required this.url,
    required this.content,
    required this.contentVersion,
    required this.sort,
    required this.hide,
    required this.createTime,
    required this.updateTime,
  });

  static Book empty() {
    return Book(
      id: null,
      classroomId: 0,
      name: '',
      desc: '',
      docId: 0,
      url: '',
      content: '',
      contentVersion: 0,
      sort: 0,
      hide: false,
      createTime: 0,
      updateTime: 0,
    );
  }
}
