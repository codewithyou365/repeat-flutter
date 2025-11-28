import 'package:floor/floor.dart';

final m4_5 = Migration(4, 5, (database) async {
  await database.execute('alter table Game add game INTEGER default 1 not null');
});
