import 'package:flutter/cupertino.dart';
import 'helper.dart';
import 'model_media_range.dart';

abstract class RepeatView {
  Helper? helper;

  void init(Helper helper);

  void dispose();

  Widget body();

  /// 同一节里视图类型会变（比如问题是视频、答案是字段专属的音频），切过去之前要把上一个
  /// 视图的播放器停下来，否则两个播放器会一起出声。默认什么都不做（文本视图没有播放器）。
  void stopPlayback() {}

  /// 直接放指定文件的指定区间，用于"播某个字段"的入口（悬浮球的 Play-*、扩展助手的播放行为）：
  /// 该字段的媒体可能不是当前视图正显示的那个文件，所以要先 load 再播。
  Future<void> playFieldMedia(String path, MediaRange range) async {}
}
