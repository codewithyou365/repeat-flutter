// history.dart
import 'dart:convert';
import 'dart:io';
import 'package:repeat_flutter/common/date_time_util.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/edit_book_history.dart';

Future<void> handleHistory(HttpRequest request, int bookId) async {
  try {
    final dao = Db().db.editBookHistoryDao;

    final body = await utf8.decodeStream(request);
    final json = jsonDecode(body) as Map<String, dynamic>;

    final int pageSize = json['pageSize'] as int? ?? 10;
    final int? lastId = json['lastId'] as int?;

    final count = await dao.getCount(bookId) ?? 0;

    List<EditBookHistory> historyList;
    if (lastId != null) {
      historyList = await dao.getPaginatedListWithLastId(bookId, lastId, pageSize);
    } else {
      historyList = await dao.getPaginatedList(bookId, pageSize);
    }
    final responseData = {
      'totalCount': count,
      'pageSize': pageSize,
      'history': historyList
          .map(
            (entry) => {
              'id': entry.id,
              'commitDate': DateTimeUtil.format(entry.commitDate),
              'content': entry.content,
            },
          )
          .toList(),
    };

    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(responseData));

    await request.response.close();
  } catch (e) {
    request.response
      ..statusCode = HttpStatus.internalServerError
      ..write(jsonEncode({'error': 'Failed to fetch history: $e'}));
    await request.response.close();
  }
}
