import 'package:get/get.dart';

import 'media_item.dart';

class MediaListState {
  final RxList<MediaItem> items = <MediaItem>[].obs;
  final RxBool loading = true.obs;
}
