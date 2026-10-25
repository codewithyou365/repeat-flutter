import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:repeat_flutter/common/mdns_lookup.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/kv.dart';

/// 域名别名：跟 hosts 文件一个意思，一个名字对应一个或多个主机（IP 或 `xxx.local`）。
///
/// 地址照常写完整 URL，主机部分写别名名字，比如 `http://home-pc:8767/v1/chat`；
/// 发请求前用 [resolveUri] 把主机换成实际能连上的那台。别名只管主机，不含协议和端口。
///
/// 整台设备一份，存在 [K.domainAliases]，不跟课堂走、不分享：
/// 别名指向的是"我这台手机所在网络里的机器"，换个人换个网络就不是同一台了。
///
/// 名字就是键（大小写不敏感，不能重名）：URL 里写的就是它。改了名字，
/// 还写着旧名字的地址就不再走别名了，跟改 hosts 文件一样。
class DomainAlias {
  final String name;
  final List<String> targets;

  DomainAlias({required this.name, required this.targets});

  static DomainAlias? fromJson(Object? json) {
    if (json is! Map || json['n'] is! String) {
      return null;
    }
    final t = json['t'];
    return DomainAlias(
      name: json['n'] as String,
      targets: t is List ? t.whereType<String>().toList() : [],
    );
  }

  Map<String, dynamic> toJson() => {'n': name, 't': targets};

  /// 主机名里允许的字符：字母数字、连字符、点。别名名字和目标都按这个校验，
  /// 顺带把 `http://`、`:8767`、`/path` 这些挡在外面。
  static final RegExp _hostPattern = RegExp(r'^[A-Za-z0-9]([A-Za-z0-9.-]*[A-Za-z0-9])?$');

  static bool isValidName(String v) => _hostPattern.hasMatch(v);

  /// 目标可以是 IP（含 IPv6）或主机名（含 `.local`）。
  static bool isValidTarget(String v) => InternetAddress.tryParse(v) != null || _hostPattern.hasMatch(v);

  // ------------------------------------------------------------------ 存取

  static List<DomainAlias>? _cache;

  static Future<List<DomainAlias>> loadAll() async {
    final cached = _cache;
    if (cached != null) {
      return cached;
    }
    var list = <DomainAlias>[];
    try {
      final raw = await Db().db.kvDao.getStr(K.domainAliases);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          list = decoded.map(fromJson).whereType<DomainAlias>().toList();
        }
      }
    } catch (e) {
      debugPrint('DomainAlias.loadAll failed: $e');
    }
    return _cache = list;
  }

  static Future<void> saveAll(List<DomainAlias> list) async {
    await Db().db.kvDao.insertOrReplace(Kv(K.domainAliases, jsonEncode(list.map((e) => e.toJson()).toList())));
    _cache = List.of(list);
    _resolved.clear();
  }

  // ------------------------------------------------------------------ 解析

  /// 「主机:端口」→ 选中的实际主机。联网动作每秒轮询一次 /status，
  /// 不能每次都重新 mDNS + 试连，所以选好的结果记一会儿。
  static final Map<String, (String, DateTime)> _resolved = {};
  static const Duration _resolvedTtl = Duration(seconds: 60);

  /// 多个目标时，每个目标试连的超时。局域网里连得上的机器远快于这个数。
  static const Duration _probeTimeout = Duration(milliseconds: 800);

  /// 字符串版的 [resolveUri]。解析不了的串原样返回，让后面的请求自己报错。
  static Future<String> resolveUrl(String url) async {
    final trimmed = url.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri == null || uri.host.isEmpty) {
      return url;
    }
    return (await resolveUri(uri)).toString();
  }

  /// 把 [uri] 的主机换成实际要连的那台：
  /// - 主机是某个别名的名字：按顺序挑目标里第一台连得上的（只有一个目标就不试连，直接用）；
  /// - 主机是 `xxx.local`（没配别名）：用 mDNS 解析成 IP；
  /// - 其它：原样返回。
  ///
  /// 目标里的 `xxx.local` 同样走 mDNS。一台都解析不出 / 连不上时返回第一个候选，
  /// 让真正的请求去报连不上的错，而不是在这里吞掉。
  ///
  /// 注意 https 换成 IP 后证书里的域名就对不上了，别名主要给局域网 http 服务用。
  static Future<Uri> resolveUri(Uri uri) async {
    final host = uri.host.toLowerCase();
    if (host.isEmpty) {
      return uri;
    }
    final aliases = await loadAll();
    DomainAlias? alias;
    for (final a in aliases) {
      if (a.name.toLowerCase() == host) {
        alias = a;
        break;
      }
    }
    final candidates = alias?.targets ?? (host.endsWith('.local') ? [host] : const <String>[]);
    if (candidates.isEmpty) {
      return uri;
    }
    final port = uri.hasPort ? uri.port : (uri.scheme == 'https' ? 443 : 80);
    final key = '$host:$port';
    final hit = _resolved[key];
    if (hit != null && DateTime.now().isBefore(hit.$2)) {
      return uri.replace(host: hit.$1);
    }

    final hosts = (await Future.wait(candidates.map(_hostOf))).whereType<String>().toList();
    if (hosts.isEmpty) {
      debugPrint('DomainAlias: nothing resolved for $host');
      return uri;
    }
    var chosen = hosts.first;
    if (hosts.length > 1) {
      final ok = await Future.wait(hosts.map((h) => _probe(h, port)));
      final i = ok.indexOf(true);
      if (i >= 0) {
        chosen = hosts[i];
      }
    }
    debugPrint('DomainAlias: $host -> $chosen');
    _resolved[key] = (chosen, DateTime.now().add(_resolvedTtl));
    return uri.replace(host: chosen);
  }

  /// 目标 → 能直接拿去连的主机：IP 和普通主机名原样，`.local` 走 mDNS（解析不出返回 null）。
  static Future<String?> _hostOf(String target) async {
    final t = target.trim();
    if (t.isEmpty) {
      return null;
    }
    if (InternetAddress.tryParse(t) == null && t.toLowerCase().endsWith('.local')) {
      return await MdnsLookup.lookup(t);
    }
    return t;
  }

  static Future<bool> _probe(String host, int port) async {
    try {
      final socket = await Socket.connect(host, port, timeout: _probeTimeout);
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }
}
