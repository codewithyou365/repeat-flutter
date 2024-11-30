import 'package:get/get.dart';
import 'package:repeat_flutter/db/entity/material.dart';

class GsCrContentState {
  final List<Material> list = <Material>[];
  var loading = false.obs;
  var indexCount = 0.obs;
  var indexTotal = 1.obs;
  var contentProgress = 0.0.obs;
}
