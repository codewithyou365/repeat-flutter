// entity/assistive_touch_action.dart

import 'package:floor/floor.dart';

@Entity(
  indices: [
    Index(value: ['classroomId']),
  ],
)
class AssistiveTouchAction {
  @PrimaryKey(autoGenerate: true)
  final int? id;

  final int classroomId;

  String name;
  int sourceIndex;
  int templateIndex;
  int targetIndex;
  bool enableAudio;

  /// ExpandBehavior 的下标：0 请求并覆盖到作用位置，1 作用位置有内容则播放否则覆盖。
  int behavior;

  /// 指令模版里用到的参数个数（0~10）。大于 0 时点这个动作会先弹框，
  /// 让用户依次填 input1..inputN，填完再渲染模版发给助手服务。
  int inputCount;
  int sort;

  AssistiveTouchAction({
    this.id,
    required this.classroomId,
    required this.name,
    required this.sourceIndex,
    required this.templateIndex,
    required this.targetIndex,
    required this.enableAudio,
    required this.behavior,
    this.inputCount = 0,
    required this.sort,
  });
}
