String urlToFileName(String urlPath) {
  var ret = urlPath.split("/").last;
  return ret;
}

String urlToRootPath(String urlPath) {
  var ret = urlPath.split("://").last;
  return ret.substring(0, ret.lastIndexOf("/"));
}
