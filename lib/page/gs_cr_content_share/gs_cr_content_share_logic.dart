import 'dart:io';

import 'package:get/get.dart';
import 'package:repeat_flutter/common/path.dart';
import 'package:repeat_flutter/common/url.dart';
import 'package:repeat_flutter/logic/constant.dart';

import 'gs_cr_content_share_state.dart';

class GsCrContentShareLogic extends GetxController {
  static const String id = "GsCrContentLogic";
  final GsCrContentShareState state = GsCrContentShareState();
  HttpServer? _httpServer;

  @override
  void onInit() {
    super.onInit();
    List<String> arguments = Get.arguments as List<String>;
    state.originalAddress = arguments[0];
    if (arguments.length > 1) {
      state.lanAddressSuffix = arguments[1];
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
    try {
      var port = 12413;
      _httpServer = await HttpServer.bind(InternetAddress.anyIPv4, port);
      List<String> ips = await getLanIps();
      state.lanAddress.value = ips.map((ip) => 'http://$ip:$port/${state.lanAddressSuffix}').join("\n");
      _httpServer!.listen((HttpRequest request) async {
        _handleRequest(request);
      });
    } catch (e) {
      print('Error starting HTTP service: $e');
    }
  }

  Future<void> _stopHttpService() async {
    if (_httpServer != null) {
      await _httpServer!.close();
      print('HTTP service stopped');
      _httpServer = null;
    }
  }

  void _handleRequest(HttpRequest request) async {
    final response = request.response;
    print(request.uri.pathSegments);
    if (request.uri.path == '/___hello_world') {
      response.statusCode = HttpStatus.ok;
      response.write('{"message": "Hello, World!"}');
    } else {
      await _serveFile(Url.toPath(request.uri.pathSegments), response);
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

  Future<void> _serveFile(String path, HttpResponse response) async {
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
