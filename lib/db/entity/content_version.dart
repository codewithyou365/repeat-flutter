// entity/content_version.dart

enum VersionReason {
  import,
  reimport,
  editor,
}

abstract class ContentVersion {
  String getContent();

  int getVersion();

  DateTime getCreateTime();
}
