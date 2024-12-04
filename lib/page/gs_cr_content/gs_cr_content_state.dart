import 'package:get/get.dart';
import 'package:repeat_flutter/db/entity/content.dart';

class GsCrContentState {
  final List<Content> list = <Content>[];
  var loading = false.obs;
  var indexCount = 0.obs;
  var indexTotal = 1.obs;
  var contentProgress = 0.0.obs;
}
