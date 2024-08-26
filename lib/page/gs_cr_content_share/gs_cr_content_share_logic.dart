import 'dart:io';

import 'package:get/get.dart';
import 'package:repeat_flutter/common/path.dart';
import 'package:repeat_flutter/common/url.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/constant.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

import 'gs_cr_content_share_state.dart';

class GsCrContentShareLogic extends GetxController {
  static const String id = "GsCrContentLogic";
  final GsCrContentShareState state = GsCrContentShareState();
  HttpServer? _httpServer;

  @override
  void onInit() {
    super.onInit();
    List<String> arguments = Get.arguments as List<String>;
    state.addresses.add(Address(I18nKey.labelOriginalAddress.tr, arguments[0]));

    if (arguments.length > 1) {
      state.lanAddressSuffix = "/${arguments[1].replaceAll(RegExp(r'^/+'), '')}";
    }
    if (arguments.length > 2) {
      state.manifestJson = arguments[2];
    }
    if (state.lanAddressSuffix.isNotEmpty) {
      _startHttpService();
    }
  }

  @override
  void onClose() {
    super.onClose();
    if (state.lanAddressSuffix.isNotEmpty) {
      _stopHttpService();
    }
  }

  Future<void> _startHttpService() async {
    var port = 40321;
    List<String> ips = [];
    try {
      ips = await getLanIps();
    } catch (e) {
      Snackbar.show('Error getting LAN IP : $e');
      return;
    }

    try {
      _httpServer = await HttpServer.bind(InternetAddress.anyIPv4, port);
      _httpServer!.listen((HttpRequest request) async {
        _handleRequest(request);
      });
    } catch (e) {
      Snackbar.show('Error starting HTTP service: $e');
      return;
    }
    for (var i = 0; i < ips.length; i++) {
      String ip = ips[i];
      state.addresses.add(Address("${I18nKey.labelLanAddress.tr} $i", 'http://$ip:$port${state.lanAddressSuffix}'));
    }
    update([id]);
  }

  Future<void> _stopHttpService() async {
    if (_httpServer != null) {
      await _httpServer!.close();
      Snackbar.show('HTTP service stopped');
      _httpServer = null;
    }
  }

  void _handleRequest(HttpRequest request) async {
    final response = request.response;
    if (request.uri.path == '/___hello_world') {
      response.statusCode = HttpStatus.ok;
      response.write('{"message": "Hello, World!"}');
    } else {
      await _serveFile(request.uri.pathSegments, response);
    }

    await response.close();
  }

  Future<List<String>> getLanIps() async {
    List<String> ret = [];
    for (var interface in await NetworkInterface.list()) {
      for (var addr in interface.addresses) {
        if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
          ret.add(addr.address);
        }
      }
    }
    return ret; // Fallback if no LAN IP found
  }

  Future<void> _serveFile(List<String> pathSegments, HttpResponse response) async {
    var path = Url.toPath(pathSegments);
    if (state.manifestJson != "" && path == state.lanAddressSuffix) {
      response.headers.contentType = ContentType.binary;
      response.headers.set('Content-Disposition', 'attachment; filename="${pathSegments.last}"');
      response.write(state.manifestJson);
      return;
    }
    var directory = await DocPath.getRootPath();
    var filePath = directory.joinPath(path);
    final file = File(filePath);
    if (await file.exists()) {
      // Set headers for file download
      response.headers.contentType = ContentType.binary;
      response.headers.set('Content-Disposition', 'attachment; filename="${file.uri.pathSegments.last}"');

      // Stream the file content to the response
      await file.openRead().pipe(response);
    } else {
      response
        ..statusCode = HttpStatus.notFound
        ..write('File not found');
    }
  }
}
