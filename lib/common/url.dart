import 'package:repeat_flutter/common/path.dart';

class Url {
  static String toDocName(String urlPath) {
    var ret = urlPath.split("/").last;
    return ret;
  }

  static String toPath(List<String> urlPath) {
    String ret = "";
    for (var item in urlPath) {
      ret = ret.joinPath(item);
    }
    return ret;
  }
}
