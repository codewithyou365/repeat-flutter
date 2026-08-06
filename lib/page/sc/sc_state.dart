import 'package:get/get.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';

class ScState {
  List<Classroom> list = <Classroom>[];

  /// 课堂导入进度：已处理的书本 / 总书本数
  RxDouble importProgress = 0.0.obs;
}
