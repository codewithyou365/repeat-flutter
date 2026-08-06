import 'package:get/get.dart';

import 'media_item.dart';

class MediaListState {
  final RxList<MediaItem> items = <MediaItem>[].obs;
  final RxBool loading = true.obs;

  /// 是否只显示有名字(d[].n 非空)的媒体，默认开启。
  final RxBool onlyNamed = true.obs;
}
