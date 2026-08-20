import 'package:get/get.dart';
import 'package:repeat_flutter/db/entity/book.dart';
import 'package:repeat_flutter/logic/ai/record_session.dart';

class ScCrMaterialRecordReviewState {
  late Book book;
  late String sessionDir;

  final RxBool loading = true.obs;
  final RxBool busy = false.obs;
  final RxString error = ''.obs;

  RecordSession? session;

  /// 展示顺序即数组顺序，跟 session.segments 是同一批对象
  final RxList<RecordSegment> segments = <RecordSegment>[].obs;

  /// 正在重跑的段序号，-1 表示没有
  final RxInt workingIndex = (-1).obs;

  int get pendingCount =>
      segments.where((e) => e.state != RecordSegmentState.done).length;
}
