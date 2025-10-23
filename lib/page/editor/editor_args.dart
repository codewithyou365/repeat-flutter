import 'dart:ui';

import 'package:repeat_flutter/logic/event_bus.dart';

class EditorArgs {
  VoidCallback? onAdvancedEdit;
  VoidCallback? onHistory;
  String title;
  Future<void> Function(String) save;
  String value;
  final List<EventTopic>? contentChangeTopics;
  final String Function()? getContent;

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
