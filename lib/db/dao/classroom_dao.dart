import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';

@dao
abstract class ClassroomDao {
  @Query('SELECT * FROM Lock where id=1 for update')
  Future<void> forUpdate();

  @Query('SELECT * FROM Classroom order by sort')
  Future<List<Classroom>> getAllClassroom();

  @Query('SELECT Id99999.id FROM Id99999'
      ' LEFT JOIN Classroom ON Classroom.sort = Id99999.id'
      ' WHERE Classroom.sort IS NULL'
      ' limit 1')
  Future<int?> getIdleSortSequenceNumber();

  @Insert(onConflict: OnConflictStrategy.ignore)
  Future<void> insertClassroom(Classroom entity);

  @delete
  Future<void> deleteContentIndex(Classroom data);

  @transaction
  Future<Classroom> add(String name) async {
    var classroom = Classroom(name, "", DateTime.now().millisecondsSinceEpoch);
    await insertClassroom(classroom);
    return classroom;
  }
}
