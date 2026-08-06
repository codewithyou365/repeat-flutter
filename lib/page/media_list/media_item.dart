enum MediaKind { audio, video, image, unknown }

/// One playable media aggregated from the `d[]` (DownloadContent) of a book,
/// chapter or verse content row. Identified by its file [hash] within a [bookId]
/// (media files are stored per book on disk).
class MediaItem {
  final String hash;
  final String url;
  final int bookId;
  final String localPath;
  final MediaKind kind;
  String displayName;

  /// Whether a custom name (`d[].n`) was explicitly set. Only named media are
  /// listed; unnamed ones are internal resources not worth showing.
  bool named;
  bool exists;

  MediaItem({
    required this.hash,
    required this.url,
    required this.bookId,
    required this.localPath,
    required this.kind,
    required this.displayName,
    required this.named,
    required this.exists,
  });
}
