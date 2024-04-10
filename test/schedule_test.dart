import 'package:flutter_test/flutter_test.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/schedule.dart';

void main() {
  group('ScheduleDAO', () {
    test('Test1', () async {
      await Db().init(inMemory: true);
      final dao = Db().db.scheduleDao;

      List<Schedule> entities = [];
      entities.add(Schedule('apple', 'indexUrl', 'dataUrl', 0, 0, DateTime.now(), 0));
      entities.add(Schedule('pear', 'indexUrl', 'dataUrl', 0, 0, DateTime.now(), 1));
      entities.add(Schedule('peach', 'indexUrl', 'dataUrl', 0, 0, DateTime.now(), 2));
      await dao.insertSchedules(entities);
      entities = await Db().db.scheduleDao.findSchedule(30);

      var result0 = await dao.initCurrent();
      var result1 = await dao.initCurrent();
      var result2 = await dao.initCurrent();

    });

    test('Test2', () async {});

    // Add more test cases as needed for other DAO operations
  });
}
