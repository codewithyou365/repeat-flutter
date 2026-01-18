import 'dart:convert';
import 'dart:io';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/book.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';

class BookRes {
  String name;
  int id;
  int classroomId;

  BookRes({
    required this.name,
    required this.id,
    required this.classroomId,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'id': id,
    'classroomId': classroomId,
  };
}

class ClassroomRes {
  String name;
  int id;
  List<BookRes> books;

  ClassroomRes({
    required this.name,
    required this.id,
    required this.books,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'id': id,
    'books': books.map((b) => b.toJson()).toList(),
  };
}

class Res {
  int currentBookId;
  List<ClassroomRes> classrooms;

  Res({
    required this.currentBookId,
    required this.classrooms,
  });

  Map<String, dynamic> toJson() => {
    'currentBookId': currentBookId,
    'classrooms': classrooms.map((c) => c.toJson()).toList(),
  };
}

Future<void> handleClassroom(HttpRequest request, int bookId) async {
  final response = request.response;

  try {
    final List<Book> books = await Db().db.bookDao.all();
    final List<Classroom> classrooms = await Db().db.classroomDao.getAllClassroom();

    final Map<int, Classroom> classroomMap = {
      for (final c in classrooms) c.id: c,
    };

    final Map<int, List<Book>> tempMap = {};
    for (final book in books) {
      if (!classroomMap.containsKey(book.classroomId)) continue;
      tempMap.putIfAbsent(book.classroomId, () => []).add(book);
    }

    final List<ClassroomRes> classroomResList = tempMap.entries.map((entry) {
      final classroom = classroomMap[entry.key]!;
      final bookResList = entry.value
          .map(
            (b) => BookRes(
              name: b.name,
              id: b.id!,
              classroomId: b.classroomId,
            ),
          )
          .toList();
      bookResList.sort((a, b) => a.id.compareTo(b.id));
      return ClassroomRes(
        name: classroom.name,
        id: classroom.id,
        books: bookResList,
      );
    }).toList();

    classroomResList.sort((a, b) => a.id.compareTo(b.id));

    final res = Res(currentBookId: bookId, classrooms: classroomResList);

    response.headers.contentType = ContentType.json;
    response.write(jsonEncode(res.toJson()));
  } catch (e) {
    response.statusCode = HttpStatus.internalServerError;
    response.write(jsonEncode({'error': e.toString()}));
  } finally {
    await response.close();
  }
}
