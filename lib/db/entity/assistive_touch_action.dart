// entity/assistive_touch_action.dart

import 'package:floor/floor.dart';

@Entity()
class AssistiveTouchAction {
  @PrimaryKey(autoGenerate: true)
  final int? id;

  String name;
  int sourceIndex;
  int templateIndex;
  int targetIndex;
  bool enableAudio;
  bool addToNextVerse;
  int sort;

  AssistiveTouchAction({
    this.id,
    required this.name,
    required this.sourceIndex,
    required this.templateIndex,
    required this.targetIndex,
    required this.enableAudio,
    required this.addToNextVerse,
    required this.sort,
  });
}
