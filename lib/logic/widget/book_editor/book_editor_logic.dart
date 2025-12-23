import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle, ByteData;
import 'package:get/get.dart';
import 'package:repeat_flutter/common/await_util.dart';
import 'package:repeat_flutter/common/ip.dart';
import 'package:repeat_flutter/common/path.dart';
import 'package:repeat_flutter/common/string_util.dart';
import 'package:repeat_flutter/common/url.dart';
import 'package:repeat_flutter/common/ws/message.dart' as message;
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/kv.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/logic/event_bus.dart';
import 'package:repeat_flutter/logic/model/chapter_show.dart';
import 'package:repeat_flutter/logic/model/verse_show.dart';
import 'package:repeat_flutter/logic/widget/book_editor/logic/history.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

import 'book_editor_args.dart';
import 'book_editor_page.dart';
import 'book_editor_state.dart';
import 'logic/book.dart';
import 'logic/browse.dart';
import 'logic/commit.dart';
import 'logic/delete.dart';
import 'logic/play.dart';
import 'logic/upload.dart';
import 'logic/editor.dart';
import 'ws/user.dart';
import 'ws/web_server.dart';

class BookEditorLogic<T extends GetxController> {
  static const int port = 40321;
  static const String id = "BookEditorLogic";
  final BookEditorState state = BookEditorState();
  final BookEditorPage page = BookEditorPage<T>();
  Directory? editorDir;
  final T parentLogic;
  late final WebServer server;
  final SubList<int> bookVersionSub = [];
  final SubList<ChapterShow> bookVersionWithChapterSub = [];
  final SubList<VerseShow> bookVersionWithVerseSub = [];

  BookEditorLogic(this.parentLogic) {
    server = WebServer();
  }

  void onEvent() {
    bookVersionSub.on([EventTopic.deleteBook, EventTopic.updateBookContent], (int? bookId) {
      if (bookId != null) {
        pushRefresh(bookId);
      }
    });

    bookVersionWithChapterSub.on([EventTopic.addChapter, EventTopic.deleteChapter, EventTopic.updateChapterContent], (ChapterShow? chapterShow) {
      if (chapterShow == null) return;
      pushRefresh(chapterShow.bookId);
    });

    bookVersionWithVerseSub.on([EventTopic.addVerse, EventTopic.deleteVerse, EventTopic.updateVerseContent, EventTopic.updateVerseProgress], (VerseShow? verseShow) {
      if (verseShow == null) return;
      pushRefresh(verseShow.bookId);
    });
  }

  void offEvent() {
    bookVersionSub.off();
    bookVersionWithChapterSub.off();
    bookVersionWithVerseSub.off();
  }

  Future<void> open(BookEditorArgs args) async {
    state.args = args;

    await page.open(this);
  }

  String get title {
    if (state.webStart.value) {
      return "${I18nKey.advancedEdit.tr}:${state.bookName}";
    }
    return I18nKey.advancedEdit.tr;
  }

  void pushRefresh(int bookId) {
    if (bookId == state.bookId) {
      server.broadcast(
        message.Request(
          path: "refresh",
        ),
      );
    }
  }

  Future<void> _initEditorDir(int bookId) async {
    final rootDir = await DocPath.getContentPath();
    final appDir = rootDir.joinPath(DocPath.getRelativePath(bookId));
    editorDir = Directory(appDir);
    if (!await editorDir!.exists()) {
      await editorDir!.create(recursive: true);
    }
  }

  void switchWeb(bool enable) {
    AwaitUtil.tryDo(() async {
      state.addresses.clear();
      if (enable) {
        state.chapterIndex = state.args.chapterIndex;
        state.verseIndex = state.args.verseIndex;
        state.bookId = state.args.bookId;
        state.bookName = state.args.bookName;
        tryRefreshCredential();
        clearActiveDownloads();
        await _initEditorDir(state.bookId);
        await _startHttpService();
      } else {
        await _stopHttpService();
      }
      state.webStart.value = enable;
    });
  }

  Future<EditorUser?> auth(HttpRequest request) async {
    final username = state.user.value;
    final password = state.password.value;
    final authHeader = request.headers.value(HttpHeaders.authorizationHeader);
    final expectedAuth = 'Basic ${base64.encode(utf8.encode('$username:$password'))}';

    if (authHeader == expectedAuth) {
      return EditorUser(credential: int.parse("$username$password"));
    } else {
      return null;
    }
  }

  Future<void> _startHttpService() async {
    List<String> ips = [];
    try {
      ips = await Ip.getLanIps();
    } catch (e) {
      Snackbar.show('Error getting LAN IP : $e');
      return;
    }

    try {
      server.start(port, auth, _handleRequest);
      onEvent();
    } catch (e) {
      Snackbar.show('Error starting HTTPS service: $e');
      return;
    }
    state.addresses.clear();
    for (var i = 0; i < ips.length; i++) {
      String ip = ips[i];
      state.addresses.add(Address("${I18nKey.labelLanAddress.tr} $i", getUrl(ip)));
    }

    Snackbar.show('HTTPS service started1');
    parentLogic.update([id]);
  }

  String getUrl(String ip) {
    final chapterIndex = state.chapterIndex;
    final verseIndex = state.verseIndex;
    String url = 'https://$ip:$port${state.lanAddressSuffix}';

    url += "?";
    List<String> params = [];
    params.add("c=${chapterIndex + 1}");
    params.add("v=${verseIndex + 1}");
    url += params.join("&");
    return url;
  }

  Future<void> _stopHttpService() async {
    try {
      offEvent();
      await server.stop();
      Snackbar.show('HTTPS service stopped');
      parentLogic.update([id]);
    } catch (e) {
      Snackbar.show('Error starting HTTPS service: $e');
      return;
    }
  }

  Future<String> tryRefreshCredential() async {
    String? credential = await Db().db.kvDao.getStr(K.credential);
    int? credentialExpireTime = await Db().db.kvDao.getInt(K.credentialExpireTime);
    final now = DateTime.now().millisecondsSinceEpoch;
    if (credential == null || credentialExpireTime == null || credentialExpireTime < now) {
      credential = StringUtil.generateRandom09(9);

      await Db().db.kvDao.insertKv(Kv(K.credential, credential));
      final expireAt = now + const Duration(hours: 4).inMilliseconds;
      await Db().db.kvDao.insertKv(Kv(K.credentialExpireTime, expireAt.toString()));
    }
    return credential;
  }

  Future<void> openCredentialDialog() async {
    String credential = await tryRefreshCredential();
    state.user.value = credential.substring(0, 3);
    state.password.value = credential.substring(3);
    MsgBox.myDialog(
      title: title,
      content: Obx(() {
        return MsgBox.content(I18nKey.keyContent.trParams([state.user.value, state.password.value]));
      }),
      action: MsgBox.yesOrNoAction(
        yes: () {
          String credential = StringUtil.generateRandom09(9);
          state.user.value = credential.substring(0, 3);
          state.password.value = credential.substring(3);
          Db().db.kvDao.insertKv(Kv(K.credential, credential));
          final now = DateTime.now().millisecondsSinceEpoch;
          final expireAt = now + const Duration(hours: 4).inMilliseconds;
          Db().db.kvDao.insertKv(Kv(K.credentialExpireTime, expireAt.toString()));
        },
        yesBtnTitle: I18nKey.refresh.tr,
        noBtnTitle: I18nKey.close.tr,
      ),
    );
  }

  Future<void> _handleRequest(HttpRequest request) async {
    final response = request.response;
    final username = state.user.value;
    final password = state.password.value;

    final authHeader = request.headers.value(HttpHeaders.authorizationHeader);
    final expectedAuth = 'Basic ${base64.encode(utf8.encode('$username:$password'))}';

    if (authHeader != expectedAuth) {
      response
        ..statusCode = HttpStatus.unauthorized
        ..headers.set('WWW-Authenticate', 'Basic realm="BookEditor"')
        ..write('Unauthorized');
      await response.close();
      return;
    }

    final path = request.uri.path;
    if (path == '/___hello_world') {
      response.statusCode = HttpStatus.ok;
      response.write('{"message": "Hello, World!"}');
    } else if (path == '/browse' && request.method == 'POST') {
      await handleBrowse(request, editorDir);
    } else if (path == '/checkDownloadStatus') {
      await handleCheckDownloadStatus(request);
    } else if (path == '/play') {
      await handlePlay(request, editorDir);
    } else if (path == '/delete' && request.method == 'POST') {
      await handleDelete(request, editorDir);
    } else if (path == '/upload' && request.method == 'POST') {
      await handleUpload(request, editorDir);
    } else if (path == '/commit' && request.method == 'POST') {
      await handleCommit(request, state.bookId);
    } else if (path == '/book' && request.method == 'POST') {
      await handleBook(request, state.bookId);
    } else if (path == '/getVimMode' && request.method == 'POST') {
      await handleGetEditorStatus(request, K.bookAdvancedEditorVimMode);
    } else if (path == '/setVimMode' && request.method == 'POST') {
      await handleSetEditorStatus(request, K.bookAdvancedEditorVimMode);
    } else if (path == '/getRelativeLineNumbers' && request.method == 'POST') {
      await handleGetEditorStatus(request, K.bookAdvancedEditorRelativeNumbers);
    } else if (path == '/setRelativeLineNumbers' && request.method == 'POST') {
      await handleSetEditorStatus(request, K.bookAdvancedEditorRelativeNumbers);
    } else if (path == '/history' && request.method == 'POST') {
      await handleHistory(request, state.bookId);
    } else {
      await _serveFile(request.uri.pathSegments, request);
    }
  }

  Future<void> _serveFile(List<String> pathVerses, HttpRequest request) async {
    var response = request.response;
    var path = Url.toPath(pathVerses);
    final Map<String, bool> map = {
      "/ace.js": true,
      "/ext-searchbox.js": true,
      "/history.html": true,
      "/index.html": true,
      "/json-source-map.js": true,
      "/keybinding-vim.min.js": true,
      "/mode-json.js": true,
      "/theme-github.js": true,
      "/worker-json.js": true,
      "/ws.js": true,
    };

    if (map[path] == true) {
      if (path.endsWith(".js")) {
        response.headers.set('Content-Type', 'application/javascript');
      }
      if (path.endsWith(".html")) {
        response.headers.contentType = ContentType.html;
      }
      ByteData content = await rootBundle.load('assets/editor'.joinPath(path));
      String str = utf8.decode(content.buffer.asUint8List());
      response.write(str);
    }
    await response.close();
  }
}
