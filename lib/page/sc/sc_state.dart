import 'package:get/get.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';

class ScState {
  List<Classroom> list = <Classroom>[];

  /// 还没有任何书的课堂，界面上标红，点它会先问要不要导入
  Set<int> emptyIds = {};

  /// 课堂导入进度：已处理的书本 / 总书本数
  RxDouble importProgress = 0.0.obs;

  /// 当前这个文件的下载进度；总大小未知时为 null（进度条显示为不确定）
  RxnDouble downloadProgress = RxnDouble(0);
}
