// entity/content_version.dart

enum VersionReason {
  import,
  editor,
}

abstract class ContentVersion {
  String getContent();

  int getVersion();

  DateTime getCreateTime();
}
