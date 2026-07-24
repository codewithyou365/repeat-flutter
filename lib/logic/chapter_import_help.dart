import 'dart:convert';
import 'dart:io';

import 'package:repeat_flutter/common/folder.dart';
import 'package:repeat_flutter/common/hash.dart';
import 'package:repeat_flutter/common/path.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/logic/download.dart';
import 'package:repeat_flutter/logic/model/book_content.dart';
import 'package:repeat_flutter/logic/srt_parse.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

class ChapterImportHelp {
  static String? _showTypeForExtension(String ext) {
    switch (ext.toLowerCase()) {
      case 'mp3':
        return RepeatViewEnum.audio.name;
      case 'mp4':
        return RepeatViewEnum.video.name;
      default:
        return null;
    }
  }

  static Future<bool> importLocal({
    required int bookId,
    required String mediaFilePath,
    required String srtFilePath,
  }) async {
    var ext = mediaFilePath.split('.').last;
    var showType = _showTypeForExtension(ext);
    if (showType == null) {
      Snackbar.show(I18nKey.labelDataAnomaly.trArgs(["ext($ext)"]));
      return false;
    }
    var hash = await Hash.toSha1(mediaFilePath);
    var download = DownloadContent(url: 'local.$ext', hash: hash);
    var rootPath = await DocPath.getContentPath();
    var targetPath = rootPath.joinPath(DocPath.getRelativePath(bookId)).joinPath(download.path);
    await Folder.ensureExists(File(targetPath).parent.path);
    await File(mediaFilePath).copy(targetPath);

    var srtText = await File(srtFilePath).readAsString();
    return _finish(bookId: bookId, showType: showType, download: download, srtText: srtText);
  }

  static Future<bool> importRemote({
    required int bookId,
    required String mediaUrl,
    required String srtUrl,
    DownloadProgressCallback? progressCallback,
  }) async {
    var mediaExt = mediaUrl.split('.').last;
    var showType = _showTypeForExtension(mediaExt);
    if (showType == null) {
      Snackbar.show(I18nKey.labelDataAnomaly.trArgs(["ext($mediaExt)"]));
      return false;
    }

    var rootPath = await DocPath.getContentPath();

    var tempSrtRelPath = 'temp_srt_${DateTime.now().millisecondsSinceEpoch}.srt';
    var srtResult = await DownloadDoc.start(srtUrl, tempSrtRelPath, progressCallback: progressCallback, skipSsl: true);
    if (srtResult != DownloadDocResult.success) {
      return false;
    }
    var tempSrtFile = File(rootPath.joinPath(tempSrtRelPath));
    var srtText = await tempSrtFile.readAsString();
    await tempSrtFile.delete();

    var tempMediaRelPath = 'temp_media_${DateTime.now().millisecondsSinceEpoch}.$mediaExt';
    var mediaResult = await DownloadDoc.start(mediaUrl, tempMediaRelPath, progressCallback: progressCallback, skipSsl: true);
    if (mediaResult != DownloadDocResult.success) {
      return false;
    }
    var tempMediaPath = rootPath.joinPath(tempMediaRelPath);
    var hash = await Hash.toSha1(tempMediaPath);
    var download = DownloadContent(url: mediaUrl, hash: hash);
    var finalPath = rootPath.joinPath(DocPath.getRelativePath(bookId)).joinPath(download.path);
    await Folder.ensureExists(File(finalPath).parent.path);
    await File(tempMediaPath).rename(finalPath);

    return _finish(bookId: bookId, showType: showType, download: download, srtText: srtText);
  }

  static Future<bool> _finish({
    required int bookId,
    required String showType,
    required DownloadContent download,
    required String srtText,
  }) async {
    var segments = SrtParse.parse(srtText);
    if (segments.isEmpty) {
      Snackbar.show(I18nKey.labelDataAnomaly.trArgs(["srt"]));
      return false;
    }
    var verseContents = segments.map((s) => jsonEncode(s.toJson())).toList();
    var chapterContent = jsonEncode({
      's': showType,
      'd': [download.toJson()],
    });
    var chapterIndex = await Db().db.chapterDao.count(bookId) ?? 0;
    return await Db().db.chapterDao.addChapterWithVerses(
      bookId: bookId,
      chapterIndex: chapterIndex,
      chapterContent: chapterContent,
      verseContents: verseContents,
    );
  }
}
