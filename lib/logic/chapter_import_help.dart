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
  static String? showTypeForExtension(String ext) {
    switch (ext.toLowerCase()) {
      case 'mp3':
        return RepeatViewEnum.audio.name;
      case 'mp4':
        return RepeatViewEnum.video.name;
      default:
        return null;
    }
  }

  /// A source is either a remote url or a path to a local file.
  static bool isUrl(String source) {
    return source.startsWith('http://') || source.startsWith('https://');
  }

  /// Extracts the file extension of a source. For a url the query string and
  /// the fragment have to be dropped first, otherwise they end up in the
  /// extension.
  static String _extensionOf(String source) {
    var path = source;
    if (isUrl(path)) {
      for (var separator in ['#', '?']) {
        var i = path.indexOf(separator);
        if (i != -1) {
          path = path.substring(0, i);
        }
      }
    }
    return path.split('.').last;
  }

  /// Imports a chapter. [mediaSource] and [srtSource] are resolved
  /// independently, so one may be a url while the other is a local file.
  static Future<bool> import({
    required int bookId,
    required String mediaSource,
    required String srtSource,
    DownloadProgressCallback? progressCallback,
  }) async {
    var mediaExt = _extensionOf(mediaSource);
    var showType = showTypeForExtension(mediaExt);
    if (showType == null) {
      Snackbar.show(I18nKey.labelDataAnomaly.trArgs(["ext($mediaExt)"]));
      return false;
    }

    var rootPath = await DocPath.getContentPath();

    String srtText;
    if (isUrl(srtSource)) {
      var tempSrtRelPath = 'temp_srt_${DateTime.now().millisecondsSinceEpoch}.srt';
      var srtResult = await DownloadDoc.start(srtSource, tempSrtRelPath, progressCallback: progressCallback, skipSsl: true);
      if (srtResult != DownloadDocResult.success) {
        return false;
      }
      var tempSrtFile = File(rootPath.joinPath(tempSrtRelPath));
      srtText = await tempSrtFile.readAsString();
      await tempSrtFile.delete();
    } else {
      var srtFile = File(srtSource);
      if (!await srtFile.exists()) {
        Snackbar.show(I18nKey.labelDocCantBeFound.trArgs([srtSource]));
        return false;
      }
      srtText = await srtFile.readAsString();
    }

    DownloadContent download;
    String mediaPath;
    if (isUrl(mediaSource)) {
      var tempMediaRelPath = 'temp_media_${DateTime.now().millisecondsSinceEpoch}.$mediaExt';
      var mediaResult = await DownloadDoc.start(mediaSource, tempMediaRelPath, progressCallback: progressCallback, skipSsl: true);
      if (mediaResult != DownloadDocResult.success) {
        return false;
      }
      mediaPath = rootPath.joinPath(tempMediaRelPath);
      download = DownloadContent(url: mediaSource, hash: await Hash.toSha1(mediaPath));
    } else {
      mediaPath = mediaSource;
      if (!await File(mediaPath).exists()) {
        Snackbar.show(I18nKey.labelDocCantBeFound.trArgs([mediaSource]));
        return false;
      }
      download = DownloadContent(url: 'local.$mediaExt', hash: await Hash.toSha1(mediaPath));
    }
    var finalPath = rootPath.joinPath(DocPath.getFilesRelativePath()).joinPath(download.path);
    await Folder.ensureExists(File(finalPath).parent.path);
    if (isUrl(mediaSource)) {
      await File(mediaPath).rename(finalPath);
    } else {
      await File(mediaPath).copy(finalPath);
    }

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
    // 整章共用这一个音视频：'d' 登记文件对象，'m' 指明它就是整节媒体，每一节都继承得到。
    // 'm' 是显式引用，所以某一节之后自己长出 'd'（比如扩展助手生成的字段音频）也遮蔽不掉它。
    var chapterContent = jsonEncode({
      's': showType,
      'd': [download.toJson()],
      VerseField.sectionMediaHash: download.hash,
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
