import 'package:floor/floor.dart';
import 'package:repeat_flutter/db/entity/video_attribute.dart';

@dao
abstract class VideoAttributeDao {
  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertVideoAttribute(VideoAttribute entity);

  @Query('SELECT * FROM VideoAttribute WHERE path = :path')
  Future<VideoAttribute?> one(String path);
}
