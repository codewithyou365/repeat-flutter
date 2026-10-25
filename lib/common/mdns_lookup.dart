import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

/// 在 App 里自己解析 `xxx.local`。
///
/// Android 系统的 DNS 不认 `.local`（iOS/Mac 认），所以访问 `macbook-pro.local` 这类地址前，
/// 这里往 224.0.0.251:5353 发一条 A 记录查询，等对方回 IP。
///
/// 用随机端口发、不绑 5353：这是 RFC 6762 §6.7 的 "legacy unicast" 查询，
/// 应答方会单播回到我们的源端口，所以收包不需要加入组播组，也不需要 Android 的 MulticastLock，
/// 不会跟本机的 [LanHost] 应答器抢端口。
class MdnsLookup {
  static final InternetAddress _group = InternetAddress('224.0.0.251');
  static const int _port = 5353;
  static const int _typeA = 1;

  /// 查 [name] 的 IPv4 地址，[timeout] 内没人答返回 null。重发一次，防组播丢包。
  static Future<String?> lookup(String name, {Duration timeout = const Duration(milliseconds: 1500)}) async {
    name = name.toLowerCase().replaceAll(RegExp(r'\.$'), '');
    RawDatagramSocket? socket;
    try {
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      final id = Random().nextInt(0xffff);
      final query = _buildQuery(id, name);
      final completer = Completer<String?>();
      socket.listen((event) {
        if (event != RawSocketEvent.read || completer.isCompleted) {
          return;
        }
        final d = socket?.receive();
        if (d == null) {
          return;
        }
        final ip = _parseAnswer(d.data, name);
        if (ip != null) {
          completer.complete(ip);
        }
      });
      socket.send(query, _group, _port);
      final resend = Timer(timeout ~/ 3, () {
        if (!completer.isCompleted) {
          socket?.send(query, _group, _port);
        }
      });
      final ip = await completer.future.timeout(timeout, onTimeout: () => null);
      resend.cancel();
      return ip;
    } catch (e) {
      debugPrint('MdnsLookup($name) failed: $e');
      return null;
    } finally {
      socket?.close();
    }
  }

  static Uint8List _buildQuery(int id, String name) {
    final b = BytesBuilder();
    b.add([id >> 8, id & 0xff, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0]);
    for (final label in name.split('.')) {
      final bytes = label.codeUnits;
      b.addByte(bytes.length);
      b.add(bytes);
    }
    b.addByte(0);
    // QTYPE=A，QCLASS=IN 并置上 QU 位（希望单播回复）
    b.add([0, _typeA, 0x80, 1]);
    return b.toBytes();
  }

  /// 在应答（answer + additional 段）里找 [name] 的 A 记录。包不完整/格式不对一律返回 null。
  static String? _parseAnswer(Uint8List data, String name) {
    try {
      if (data.length < 12) {
        return null;
      }
      final flags = (data[2] << 8) | data[3];
      if (flags & 0x8000 == 0) {
        return null; // 不是应答
      }
      final qd = (data[4] << 8) | data[5];
      final rrCount = ((data[6] << 8) | data[7]) + ((data[8] << 8) | data[9]) + ((data[10] << 8) | data[11]);
      var off = 12;
      for (var i = 0; i < qd; i++) {
        off = _readName(data, off).$2 + 4;
      }
      for (var i = 0; i < rrCount; i++) {
        final (rrName, next) = _readName(data, off);
        off = next;
        final type = (data[off] << 8) | data[off + 1];
        final len = (data[off + 8] << 8) | data[off + 9];
        off += 10;
        if (type == _typeA && len == 4 && rrName.toLowerCase() == name) {
          return '${data[off]}.${data[off + 1]}.${data[off + 2]}.${data[off + 3]}';
        }
        off += len;
      }
    } catch (_) {}
    return null;
  }

  /// 读一个（可能带压缩指针的）域名，返回名字和它后面的偏移。
  static (String, int) _readName(Uint8List data, int off) {
    final labels = <String>[];
    int? end;
    var jumps = 0;
    while (true) {
      final len = data[off];
      if (len == 0) {
        off++;
        break;
      }
      if (len & 0xc0 == 0xc0) {
        end ??= off + 2;
        off = ((len & 0x3f) << 8) | data[off + 1];
        if (++jumps > 20) {
          throw const FormatException('name pointer loop');
        }
        continue;
      }
      labels.add(String.fromCharCodes(data.sublist(off + 1, off + 1 + len)));
      off += 1 + len;
    }
    return (labels.join('.'), end ?? off);
  }
}
