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

  /// 指令模版原文（不是渲染结果）：用户在扩展助手里直接写，里面可以放
  /// {{question}}/{{answer}}/{{tip1}}..{{tip8}}（取当前小节的正文）和
  /// {{input1}}..{{input10}}（执行前弹框让用户填）。
  /// 要哪几个参数不再单独存，按模版里实际写了哪几个 inputN 扫出来（见 ExpandLogic.inputNumbersOf）。
  String template;
  int targetIndex;
  bool enableAudio;

  /// ExpandBehavior 的下标：0 请求并覆盖到作用位置，1 作用位置有内容则播放否则覆盖。
  int behavior;
  int sort;

  AssistiveTouchAction({
    this.id,
    required this.classroomId,
    required this.name,
    required this.template,
    required this.targetIndex,
    required this.enableAudio,
    required this.behavior,
    required this.sort,
  });
}
