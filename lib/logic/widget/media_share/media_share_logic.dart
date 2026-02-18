import 'dart:io';

import 'package:get/get.dart';
import 'package:repeat_flutter/common/await_util.dart';
import 'package:repeat_flutter/common/http_media.dart';
import 'package:repeat_flutter/common/ip.dart';
import 'package:repeat_flutter/common/path.dart';
import 'package:repeat_flutter/common/ssl.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/kv.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/page/repeat/logic/constant.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

import 'media_share_args.dart';
import 'media_share_page.dart';
import 'media_share_state.dart';

class MediaShareLogic {
  static const int defaultPort = 4324;
  RxInt port = defaultPort.obs;
  static const String id = "MediaShareLogic";
  HttpServer? _httpServer;
  final MediaShareState state = MediaShareState();
  final MediaSharePage page = MediaSharePage();

  MediaShareLogic();

  Future<void> open(MediaShareArgs args) async {
    state.args = args;
    port.value = await Db().db.kvDao.getIntWithDefault(K.mediaSharePort, port.value);
    if (port.value > 50000) {
      port.value = defaultPort;
    }
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
        _httpServer = await HttpServer.bindSecure(InternetAddress.anyIPv4, port.value, context);
      } else {
        _httpServer = await HttpServer.bind(InternetAddress.anyIPv4, port.value);
      }
      _httpServer!.listen((HttpRequest request) async {
        _handleRequest(request);
      });
    } catch (e) {
      await Db().db.kvDao.insertOrReplace(Kv(K.mediaSharePort, '${port.value + 10}'));
      Snackbar.show('Error starting media service: $e \n System has changed the port, please try again');
      _stopHttpService(tip: false);
      Get.back();
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

  Future<void> _stopHttpService({tip = true}) async {
    if (_httpServer != null) {
      await _httpServer!.close();
      if (tip) {
        Snackbar.show('media service stopped');
      }
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
    List<String> allowedExtensions = MediaType.audio.allowedExtensions;
    final lowerPath = file.path.toLowerCase();
    if (allowedExtensions.any((ext) => lowerPath.endsWith(ext.toLowerCase()))) {
      await HttpMedia.play(request, file);
    } else {
      response.statusCode = HttpStatus.badRequest;
      response.write('the file is not media');
      await response.close();
    }
  }
}
