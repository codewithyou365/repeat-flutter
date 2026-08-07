import 'dart:ui';

import 'package:repeat_flutter/logic/event_bus.dart';

class EditorArgs {
  VoidCallback? onAdvancedEdit;
  VoidCallback? onHistory;
  String title;
  Future<void> Function(String) save;
  String value;
  final List<EventTopic>? contentChangeTopics;

  /// 内容变更事件到了之后重新取一遍正文。是 async 的 —— 正文现在都从库里现查，
  /// 不再有一份全课堂常驻内存的缓存可以同步读。
  final Future<String> Function()? getContent;

  EditorArgs({
    this.onAdvancedEdit,
    this.onHistory,
    required this.title,
    required this.save,
    required this.value,
    this.contentChangeTopics,
    this.getContent,
  });
}
