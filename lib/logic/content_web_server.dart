import 'dart:async';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:repeat_flutter/common/path.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/kv.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/logic/model/book_content.dart';

/// content 数组里网页项的静态托管。
///
/// **为什么不直接 `file://` 加载。** 网页项常见的形态是 three.js 之类的场景，模型（.glb）
/// 和贴图是用 fetch/XHR 取的，`file://` 下会被同源策略挡死（Android WebView 尤其严）。
/// 走一个回环上的 http 服务这个问题就整个消失了。
///
/// **跟 GameWebServer 的区别。** 那个是给局域网上的学生端用的：绑 anyIPv4、上 TLS、
/// 带鉴权、注册一堆业务 controller、还挂着 JsRuntime。这里一个都不要——网页项只要
/// 静态文件，多一个口子就多一份暴露面。所以这里只绑回环、只响应 GET、只读课堂文件目录。
class ContentWebServer {
  ContentWebServer._();

  static final ContentWebServer instance = ContentWebServer._();

  HttpServer? _server;

  /// 托管的根目录（课堂的文件目录）。换课堂时会变，变了就重启。
  String _root = '';

  /// 同一时刻只允许一个 [ensureStarted] 在真正启动，否则一节里几个网页项同时首次渲染
  /// 会各起一个 server。
  Future<String?>? _starting;

  /// 网页内容允不允许出网，由**使用者**在设置里开关（[K.contentWebNetwork]，默认开），
  /// 不是内容自己声明的——内容是能从外部导入的，让它自己决定要不要联网等于没有开关。
  ///
  /// 每次 [ensureStarted] 读一遍，所以在设置里改完回到学习页就生效，不用重启。
  bool _allowNetwork = true;

  String? get baseUrl {
    final s = _server;
    return s == null ? null : 'http://${s.address.address}:${s.port}';
  }

  /// 保证服务起着并且托管的是当前课堂的文件目录，返回 `http://127.0.0.1:<port>`。
  /// 起不来返回 null，调用方显示一个占位而不是崩掉。
  Future<String?> ensureStarted() async {
    // 默认开：只有显式存了 '0' 才算关。
    _allowNetwork = (await Db().db.kvDao.getStr(K.contentWebNetwork)) != '0';
    final rootPath = await DocPath.getContentPath();
    final root = rootPath.joinPath(DocPath.getFilesRelativePath());
    if (_server != null && _root == root) {
      return baseUrl;
    }
    return _starting ??= _start(root).whenComplete(() => _starting = null);
  }

  Future<String?> _start(String root) async {
    await stop();
    try {
      // 端口交给系统挑：写死端口会跟 GameWebServer 或者别的进程撞上。
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      _server = server;
      _root = root;
      server.listen(_serve, onError: (Object e) => debugPrint('[contentWeb] $e'));
      return baseUrl;
    } catch (e) {
      debugPrint('[contentWeb] start failed: $e');
      _server = null;
      _root = '';
      return null;
    }
  }

  Future<void> stop() async {
    final s = _server;
    _server = null;
    _root = '';
    // 地址里带着端口，服务重启后端口会变，缓存必须跟着作废。
    _urlCache.clear();
    if (s != null) {
      try {
        await s.close(force: true);
      } catch (_) {}
    }
  }

  Future<void> _serve(HttpRequest request) async {
    final res = request.response;
    try {
      if (request.method != 'GET') {
        res.statusCode = HttpStatus.methodNotAllowed;
        await res.close();
        return;
      }
      // 使用者关掉了联网就用 CSP 关死：比 WebView 那几个拦截回调靠谱——它们要么只管
      // 跳转不管子资源，要么只有 Android 有。CSP 挂在文档这一份响应上，
      // 整份文档连同它拉的所有子资源都受它管。
      if (!_allowNetwork) {
        res.headers.add(
          'Content-Security-Policy',
          "default-src 'self' 'unsafe-inline' 'unsafe-eval' data: blob:",
        );
      }
      final file = _resolve(request.uri.path);
      if (file == null || !await file.exists()) {
        res.statusCode = HttpStatus.notFound;
        res.write('404');
        await res.close();
        return;
      }
      res.headers.contentType = ContentType.parse(_contentType(file.path));
      await res.addStream(file.openRead());
      await res.close();
    } catch (e) {
      debugPrint('[contentWeb] serve failed: $e');
      try {
        res.statusCode = HttpStatus.internalServerError;
        await res.close();
      } catch (_) {}
    }
  }

  File? _resolve(String requestPath) => resolveWithin(_root, requestPath);

  /// 把请求路径解析成根目录下的文件。**解析完必须还在根目录里面**——
  /// 网页里写一个 `../../../` 就能把整个 App 的私有目录读出来，这条不能少。
  /// 路径先解码再规整：`%2e%2e%2f` 跟 `../` 是一回事，只挡后者等于没挡。
  @visibleForTesting
  static File? resolveWithin(String root, String requestPath) {
    if (root.isEmpty) {
      return null;
    }
    String decoded;
    try {
      decoded = Uri.decodeComponent(requestPath);
    } catch (_) {
      return null;
    }
    final full = p.normalize(p.join(root, decoded.startsWith('/') ? decoded.substring(1) : decoded));
    if (!p.isWithin(root, full)) {
      return null;
    }
    return File(full);
  }

  static String _contentType(String filePath) {
    switch (p.extension(filePath).toLowerCase()) {
      case '.html':
      case '.htm':
        return 'text/html; charset=utf-8';
      case '.css':
        return 'text/css; charset=utf-8';
      case '.js':
      case '.mjs':
        return 'application/javascript; charset=utf-8';
      case '.json':
      case '.gltf':
        return 'application/json; charset=utf-8';
      case '.wasm':
        return 'application/wasm';
      case '.png':
        return 'image/png';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.svg':
        return 'image/svg+xml';
      case '.mp3':
        return 'audio/mpeg';
      case '.wav':
        return 'audio/wav';
      case '.mp4':
        return 'video/mp4';
      case '.woff2':
        return 'font/woff2';
      default:
        // .glb、.bin、模型和贴图里各种自定义扩展名都落这儿。给个通用二进制类型，
        // 别像 GameWebServer 那样返回空串把请求打回首页——那会让 three.js 拿到一份
        // HTML 当模型解析，报一个跟真实原因八竿子打不着的错。
        return 'application/octet-stream';
    }
  }

  /// 一个网页项解析好的完整地址，`null` 表示这个文件用不了（不是网页、zip 里没有
  /// index.html、解压失败）。
  ///
  /// 结果按 hash 缓存：界面每次 update 都会重建一遍内容项，不缓存的话每重建一次
  /// 就要重跑一遍启动和解压，网页也会跟着闪一下。内容按 hash 寻址，同一个 hash
  /// 解析出来的地址不会变，缓存是安全的。
  final Map<String, Future<String?>> _urlCache = {};

  Future<String?> urlOf(DownloadContent d) {
    return _urlCache[d.hash] ??= _resolveUrl(d);
  }

  Future<String?> _resolveUrl(DownloadContent d) async {
    final base = await ensureStarted();
    if (base == null) {
      return null;
    }
    final path = await entryPathOf(d, _root);
    return path == null ? null : '$base/$path';
  }

  /// 网页项指向的那个文件在服务上的相对路径。
  ///
  /// - 单个 `.html`：就是它自己，`<folder>/<name>`
  /// - `.zip`：解压到 `<folder>/<pureName>/`，入口是里面的 `index.html`
  ///
  /// 3D 场景不可能是单文件（要库、模型、贴图），所以 zip 是主要形态；
  /// 单文件留给"一段公式、一张表格"这种自包含的富文本。
  static Future<String?> entryPathOf(DownloadContent d, String root) async {
    final ext = d.extension.toLowerCase();
    if (ext == 'html' || ext == 'htm') {
      return d.path;
    }
    if (ext != 'zip') {
      return null;
    }
    final dir = p.join(root, d.folder, d.pureName);
    final ok = await unzipTo(p.join(root, d.path), dir);
    if (!ok) {
      return null;
    }
    for (var name in const ['index.html', 'index.htm']) {
      if (await File(p.join(dir, name)).exists()) {
        return '${d.folder}/${d.pureName}/$name';
      }
    }
    return null;
  }

  /// 解压到 [destPath]。已经解压过就直接用（内容按 hash 寻址，同一个 hash 内容不会变）。
  ///
  /// 逐个条目都要校验落点还在 [destPath] 里面：zip 里的条目名是内容作者写的，
  /// `../` 能把文件写到目录外面去（zip slip）。
  @visibleForTesting
  static Future<bool> unzipTo(String zipFilePath, String destPath) async {
    try {
      if (await Directory(destPath).exists()) {
        return true;
      }
      if (!await File(zipFilePath).exists()) {
        return false;
      }
      final archive = ZipDecoder().decodeStream(InputFileStream(zipFilePath));
      for (final entry in archive) {
        if (!entry.isFile) {
          continue;
        }
        final out = p.normalize(p.join(destPath, entry.name));
        if (!p.isWithin(destPath, out)) {
          debugPrint('[contentWeb] skip unsafe zip entry: ${entry.name}');
          continue;
        }
        await Directory(p.dirname(out)).create(recursive: true);
        final stream = OutputFileStream(out);
        entry.writeContent(stream);
        await stream.close();
      }
      return true;
    } catch (e) {
      debugPrint('[contentWeb] unzip failed: $e');
      // 解压到一半失败会留下一个残缺目录，下次进来会当成"已经解压过"。清掉。
      try {
        await Directory(destPath).delete(recursive: true);
      } catch (_) {}
      return false;
    }
  }
}
