import 'package:get/get.dart';
import 'package:repeat_flutter/db/entity/content_index.dart';

class MainContentState {
  final List<ContentIndex> indexes = <ContentIndex>[];
  var loading = false.obs;
  var indexCount = 0.obs;
  var indexTotal = 1.obs;
  var contentProgress = 0.0.obs;
}
