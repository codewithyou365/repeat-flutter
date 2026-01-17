import 'dart:io';

import 'package:repeat_flutter/common/await_util.dart';
import 'package:repeat_flutter/common/http_media.dart';
import 'package:repeat_flutter/common/ip.dart';
import 'package:repeat_flutter/common/path.dart';
import 'package:repeat_flutter/common/ssl.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

import 'media_share_args.dart';
import 'media_share_page.dart';
import 'media_share_state.dart';

class MediaShareLogic {
  static const int port = 40322;
  static const String id = "MediaShareLogic";
  HttpServer? _httpServer;
  final MediaShareState state = MediaShareState();
  final MediaSharePage page = MediaSharePage();

  MediaShareLogic();

  Future<void> open(MediaShareArgs args) async {
    state.args = args;
    await page.open(this);
  }

  void switchWeb(bool enable) {
    AwaitUtil.tryDo(() async {
      state.addressesLength.value = 0;
      state.addresses.clear();
      if (enable) {
        await _startHttpService();
      } else {
        await _stopHttpService();
      }
      state.webStart.value = enable;
    });
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
      if (state.enableSsl.value) {
        var sslPath = await DocPath.getSslPath();
        var context = SelfSsl.generateSecurityContext(sslPath);
        _httpServer = await HttpServer.bindSecure(InternetAddress.anyIPv4, port, context);
      } else {
        _httpServer = await HttpServer.bind(InternetAddress.anyIPv4, port);
      }
      _httpServer!.listen((HttpRequest request) async {
        _handleRequest(request);
      });
    } catch (e) {
      Snackbar.show('Error starting media service: $e');
      return;
    }
    state.addresses.clear();
    for (var i = 0; i < ips.length; i++) {
      String ip = ips[i];
      state.addresses.add(Address("${I18nKey.labelLanAddress.tr} $i", getUrl(ip)));
    }
    state.addressesLength.value = state.addresses.length;

    Snackbar.show('media share started');
  }

  String getUrl(String ip) {
    String url = "http";
    if (state.enableSsl.value) {
      url = "https";
    }
    url += '://$ip:$port${state.lanAddressSuffix}';
    String path = Uri.encodeComponent('${DocPath.getRelativePath(state.args.bookId)}/${state.args.path}');
    url += "?path=$path";
    return url;
  }

  Future<void> _stopHttpService() async {
    if (_httpServer != null) {
      await _httpServer!.close();
      Snackbar.show('media service stopped');
      _httpServer = null;
    }
  }

  void _handleRequest(HttpRequest request) async {
    final response = request.response;
    final pathParam = request.uri.queryParameters['path'];
    if (pathParam == null || pathParam.isEmpty) {
      response.statusCode = HttpStatus.badRequest;
      response.write('Missing "path" parameter');
      await response.close();
      return;
    }
    final rootPath = await DocPath.getContentPath();
    final filePath = rootPath.joinPath(pathParam);
    final file = File(filePath);
    if (file.path.toLowerCase().endsWith('.mp4') || file.path.toLowerCase().endsWith('.mp3')) {
      await HttpMedia.play(request, file);
    } else {
      response.statusCode = HttpStatus.badRequest;
      response.write('the file is not media');
      await response.close();
    }
  }
}
