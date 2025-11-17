// entity/edit_book_history.dart

import 'package:floor/floor.dart';

@Entity(
  indices: [
    Index(value: ['commitDate', 'bookId'], unique: true),
  ],
)
class EditBookHistory {
  @PrimaryKey(autoGenerate: true)
  final int? id;
  int bookId;
  DateTime commitDate;
  String content;

  EditBookHistory({
    this.id,
    required this.bookId,
    required this.commitDate,
    required this.content,
  });
}
