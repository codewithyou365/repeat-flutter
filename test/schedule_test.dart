// import 'package:flutter_test/flutter_test.dart';
// import 'package:repeat_flutter/db/dao/schedule_dao.dart';
// import 'package:repeat_flutter/db/database.dart';
// import 'package:repeat_flutter/db/entity/schedule.dart';
//
// void main() {
//   group('ScheduleDAO', () {
//     test('Test1', () async {
//       await Db().init(inMemory: true);
//       final dao = Db().db.scheduleDao;
//
//       ScheduleDao.ebbinghausForgettingCurve = [0, 1, 5, 7, 9];
//       ScheduleDao.intervalSeconds = 1;
//       ScheduleDao.learnCountPerDay = 6;
//       ScheduleDao.learnCountPerGroup = 2;
//       ScheduleDao.maxRepeatTime = 3;
//       List<Schedule> entities = [];
//       entities.add(Schedule("apple", 0, 1, 0, 0, 0, DateTime.now(), 0));
//       entities.add(Schedule("pear", 0, 2, 0, 0, 0, DateTime.now(), 1));
//       entities.add(Schedule("peach", 0, 3, 0, 0, 0, DateTime.now(), 2));
//       await dao.insertSchedules(entities);
//       entities = await Db().db.scheduleDao.findVerseOverallPrg(30, DateTime.now());
//
//       var result = await dao.initToday();
//       expect(result.schedulesToday.length, 3);
//       expect(result.schedulesToday[0].key, "apple");
//       expect(result.schedulesToday[1].key, "pear");
//       expect(result.schedulesToday[2].key, "peach");
//       var pear = result.schedulesCurrent[1];
//       await dao.error(pear);
//       var scheduleCurrent = await dao.getOneScheduleCurrent("pear");
//       var schedule = await dao.getVerseOverallPrg("pear");
//       expect(scheduleCurrent!.progress, 0);
//       expect(schedule!.progress, 0);
//       await dao.right(pear);
//       scheduleCurrent = await dao.getOneScheduleCurrent("pear");
//       schedule = await dao.getVerseOverallPrg("pear");
//       expect(scheduleCurrent!.progress, 1);
//       expect(schedule!.progress, 0);
//       await dao.right(pear);
//       scheduleCurrent = await dao.getOneScheduleCurrent("pear");
//       schedule = await dao.getVerseOverallPrg("pear");
//       expect(scheduleCurrent!.progress, 2);
//       expect(schedule!.progress, 0);
//       await Future.delayed(const Duration(seconds: 1));
//       await dao.right(pear);
//       scheduleCurrent = await dao.getOneScheduleCurrent("pear");
//       schedule = await dao.getVerseOverallPrg("pear");
//       expect(scheduleCurrent!.progress, 3);
//       expect(schedule!.progress, 0);
//
//       await Future.delayed(const Duration(seconds: 1));
//       await dao.right(pear);
//       scheduleCurrent = await dao.getOneScheduleCurrent("pear");
//       schedule = await dao.getVerseOverallPrg("pear");
//       expect(scheduleCurrent!.progress, 3);
//       expect(schedule!.progress, 1);
//
//       result = await dao.initToday();
//       expect(result.schedulesToday.length, 3);
//       expect(result.schedulesToday[0].key, "apple");
//       expect(result.schedulesToday[1].key, "pear");
//       expect(result.schedulesToday[2].key, "peach");
//       var apple = result.schedulesCurrent[0];
//       await dao.right(apple);
//       scheduleCurrent = await dao.getOneScheduleCurrent("apple");
//       schedule = await dao.getVerseOverallPrg("apple");
//       expect(scheduleCurrent!.progress, ScheduleDao.maxRepeatTime);
//       expect(schedule!.progress, 1);
//
//       await Future.delayed(const Duration(seconds: 1));
//       await dao.right(apple);
//       scheduleCurrent = await dao.getOneScheduleCurrent("apple");
//       schedule = await dao.getVerseOverallPrg("apple");
//       expect(scheduleCurrent!.progress, ScheduleDao.maxRepeatTime);
//       expect(schedule!.progress, 2);
//
//       await Future.delayed(const Duration(seconds: 5));
//       await dao.right(apple);
//       scheduleCurrent = await dao.getOneScheduleCurrent("apple");
//       schedule = await dao.getVerseOverallPrg("apple");
//       expect(scheduleCurrent!.progress, ScheduleDao.maxRepeatTime);
//       expect(schedule!.progress, 3);
//       await Future.delayed(const Duration(seconds: 7));
//       await dao.right(apple);
//       scheduleCurrent = await dao.getOneScheduleCurrent("apple");
//       schedule = await dao.getVerseOverallPrg("apple");
//       expect(scheduleCurrent!.progress, ScheduleDao.maxRepeatTime);
//       expect(schedule!.progress, 4);
//
//       await Future.delayed(const Duration(seconds: 9));
//       await dao.right(apple);
//       scheduleCurrent = await dao.getOneScheduleCurrent("apple");
//       schedule = await dao.getVerseOverallPrg("apple");
//       expect(scheduleCurrent!.progress, ScheduleDao.maxRepeatTime);
//       expect(schedule!.progress, 5);
//
//       await Future.delayed(const Duration(seconds: 9));
//       await dao.right(apple);
//       scheduleCurrent = await dao.getOneScheduleCurrent("apple");
//       schedule = await dao.getVerseOverallPrg("apple");
//       expect(scheduleCurrent!.progress, ScheduleDao.maxRepeatTime);
//       expect(schedule!.progress, 6);
//
//       result = await dao.initToday();
//       expect(result.schedulesToday.length, 3);
//       expect(result.schedulesToday[0].key, "apple");
//       expect(result.schedulesToday[1].key, "pear");
//       expect(result.schedulesToday[2].key, "peach");
//     });
//
//     test('Test2', () async {});
//   });
// }
