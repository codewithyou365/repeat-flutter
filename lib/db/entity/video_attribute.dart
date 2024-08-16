// entity/video_attribute.dart

import 'package:floor/floor.dart';

@entity
class VideoAttribute {
  @primaryKey
  final String path;
  final double maskRatio;

  VideoAttribute(this.path, this.maskRatio);
}
