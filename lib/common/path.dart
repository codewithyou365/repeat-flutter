import 'package:path_provider/path_provider.dart';

// - `NSCachesDirectory` on iOS and macOS.
// - `Context.getCacheDir` on Android.
Future<String> urlToCachePath(String prefix, String urlPath) async {
  var directory = await getTemporaryDirectory();
  var ret = urlPath.split("://").last;
  return "${directory.path}/$prefix/$ret";
}
