import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:repeat_flutter/common/ip.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/kv.dart';

/// 给本机起一个固定的局域网域名（形如 `repeat-3f2a.local`），分享地址就不用跟着 IP 变。
///
/// 原理同 Mac 的 `macbook-pro.local`：mDNS。局域网里有人组播问"谁是 xxx.local"，
/// 这里收到就回一条 A 记录。只答自己这一个名字，不做服务发现、不做冲突探测
/// （名字带 4 位随机后缀，撞名概率可以忽略）。
///
/// 应答器只在 Android 上开；iOS 直接用系统的设备名，见 [_systemName]。
/// Android 不持有 WifiManager.MulticastLock 的话，很多机型 Wi-Fi 驱动会把组播包直接丢掉，
/// 所以开的时候先通过 MainActivity 拿锁。
///
/// 解析是在访问端做的：Mac/iPhone/Windows 10+ 能直接认 `.local`，Android 浏览器基本不行，
/// 所以调用方一律把 IP 地址也列在后面兜底，见 [hosts]。
///
/// 多个分享服务共用一个应答器，按 owner 计数：[start]/[stop] 对同一个 owner 是幂等的，
/// 所有 owner 都停了才真正关掉。
class LanHost {
  static const MethodChannel _channel = MethodChannel('repeat_flutter/multicast');
  static const int _port = 5353;
  static const int _ttl = 120;
  static final InternetAddress _group = InternetAddress('224.0.0.251');

  static final Set<String> _owners = {};
  static RawDatagramSocket? _socket;
  static Timer? _rejoinTimer;
  static final Set<String> _joined = {};
  static String? _name;
  static Future<void>? _starting;

  /// 当前对外的完整域名（带 `.local`），应答器没跑起来时为 null。
  static String? get name => _socket == null ? null : _name;

  /// iOS 跟 Mac 一样，系统的 mDNSResponder 自己就会应答 `设备名.local`，直接拿来用。
  /// 拿到的是 localhost 之类没法给别人用的名字时返回 null。
  static String? _systemName() {
    try {
      var h = Platform.localHostname.trim();
      if (h.isEmpty || h.toLowerCase().startsWith('localhost')) {
        return null;
      }
      if (!h.toLowerCase().endsWith('.local')) {
        h = '$h.local';
      }
      return h;
    } catch (e) {
      debugPrint('LanHost.localHostname failed: $e');
      return null;
    }
  }

  /// 分享地址里该用的主机列表：固定域名在前，IP 在后兜底。
  static Future<List<String>> hosts() async {
    final ips = await Ip.getLanIps();
    final n = Platform.isIOS ? _systemName() : name;
    debugPrint('LanHost.hosts name=$n ips=$ips');
    if (n == null || ips.isEmpty) {
      return ips;
    }
    return [n, ...ips];
  }

  static Future<void> start(String owner) async {
    if (!Platform.isAndroid) {
      return;
    }
    _owners.add(owner);
    if (_socket != null) {
      return;
    }
    // 两个服务几乎同时开时只起一次
    _starting ??= _doStart().whenComplete(() => _starting = null);
    await _starting;
  }

  static Future<void> stop(String owner) async {
    if (!_owners.remove(owner) || _owners.isNotEmpty) {
      return;
    }
    await _starting;
    _rejoinTimer?.cancel();
    _rejoinTimer = null;
    final socket = _socket;
    _socket = null;
    _joined.clear();
    if (socket != null) {
      // TTL=0 的通告让别人立刻丢掉缓存，免得服务关了还解析到这台
      await _announce(socket, ttl: 0);
      socket.close();
    }
    try {
      await _channel.invokeMethod<bool>('release');
    } catch (e) {
      debugPrint('LanHost.release failed: $e');
    }
  }

  static Future<String> _loadName() async {
    final saved = await Db().db.kvDao.getStr(K.lanHostName);
    if (saved != null && saved.isNotEmpty) {
      return saved;
    }
    final r = Random.secure();
    final suffix = List.generate(4, (_) => r.nextInt(16).toRadixString(16)).join();
    final generated = 'repeat-$suffix';
    await Db().db.kvDao.insertOrReplace(Kv(K.lanHostName, generated));
    return generated;
  }

  static Future<void> _doStart() async {
    try {
      _name = '${await _loadName()}.local';
      try {
        await _channel.invokeMethod<bool>('acquire');
      } catch (e) {
        debugPrint('LanHost.acquire failed: $e');
      }
      RawDatagramSocket socket;
      try {
        socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, _port, reuseAddress: true, reusePort: true);
      } catch (_) {
        // 有的系统不支持 SO_REUSEPORT，退回只用 SO_REUSEADDR
        socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, _port, reuseAddress: true);
      }
      socket.multicastLoopback = false;
      socket.listen((event) {
        if (event == RawSocketEvent.read) {
          final d = socket.receive();
          if (d != null) {
            _onPacket(socket, d);
          }
        }
      });
      _socket = socket;
      await _joinAll(socket);
      // 换 Wi-Fi / 重连之后网卡地址会变，原来的组播成员资格也就没了，定期补一下
      _rejoinTimer = Timer.periodic(const Duration(seconds: 30), (_) => _joinAll(socket));
      await _announce(socket, ttl: _ttl);
    } catch (e) {
      debugPrint('LanHost.start failed: $e');
      _socket?.close();
      _socket = null;
      _joined.clear();
    }
  }

  static Future<List<(NetworkInterface, InternetAddress)>> _lanAddrs() async {
    final ret = <(NetworkInterface, InternetAddress)>[];
    for (final i in await NetworkInterface.list(type: InternetAddressType.IPv4)) {
      for (final a in i.addresses) {
        if (!a.isLoopback) {
          ret.add((i, a));
        }
      }
    }
    return ret;
  }

  static Future<void> _joinAll(RawDatagramSocket socket) async {
    if (_socket != socket) {
      return;
    }
    for (final (i, a) in await _lanAddrs()) {
      final key = '${i.name}/${a.address}';
      if (_joined.contains(key)) {
        continue;
      }
      try {
        socket.joinMulticast(_group, i);
        _joined.add(key);
      } catch (e) {
        debugPrint('LanHost.joinMulticast ${i.name} failed: $e');
      }
    }
  }

  static Future<void> _announce(RawDatagramSocket socket, {required int ttl}) async {
    for (final (_, a) in await _lanAddrs()) {
      _sendMulticast(socket, a, _buildResponse(id: 0, ip: a, ttl: ttl, cacheFlush: true));
    }
  }

  static void _sendMulticast(RawDatagramSocket socket, InternetAddress via, Uint8List packet) {
    try {
      // 手机常常 Wi-Fi 和蜂窝同时在线，不指定出口的话组播可能从蜂窝出去，局域网里谁都收不到
      socket.setRawOption(RawSocketOption(RawSocketOption.levelIPv4, RawSocketOption.IPv4MulticastInterface, via.rawAddress));
    } catch (e) {
      debugPrint('LanHost.setMulticastInterface failed: $e');
    }
    socket.send(packet, _group, _port);
  }

  static Future<void> _onPacket(RawDatagramSocket socket, Datagram d) async {
    final q = _parseQuery(d.data);
    if (q == null || !q.asksFor(_name!)) {
      return;
    }
    final ip = await _pickAddress(d.address);
    if (ip == null || _socket != socket) {
      return;
    }
    if (d.port != _port) {
      // 传统单播查询（Windows 的部分解析器就这么问）：原样回 id 并带上问题，直接单播回去
      socket.send(_buildResponse(id: q.id, ip: ip, ttl: 10, cacheFlush: false, echoQuestion: true), d.address, d.port);
      return;
    }
    final packet = _buildResponse(id: 0, ip: ip, ttl: _ttl, cacheFlush: true);
    if (q.unicastResponse(_name!)) {
      socket.send(packet, d.address, d.port);
    } else {
      _sendMulticast(socket, ip, packet);
    }
  }

  /// 从本机的几个地址里挑跟提问方前缀最长的那个，也就是同一个子网里的地址。
  static Future<InternetAddress?> _pickAddress(InternetAddress from) async {
    InternetAddress? best;
    var bestBits = -1;
    for (final (_, a) in await _lanAddrs()) {
      final bits = _commonPrefix(a.rawAddress, from.rawAddress);
      if (bits > bestBits) {
        best = a;
        bestBits = bits;
      }
    }
    return best;
  }

  static int _commonPrefix(Uint8List a, Uint8List b) {
    if (a.length != b.length) {
      return 0;
    }
    var bits = 0;
    for (var i = 0; i < a.length; i++) {
      final x = a[i] ^ b[i];
      if (x == 0) {
        bits += 8;
        continue;
      }
      var mask = 0x80;
      while (x & mask == 0) {
        bits++;
        mask >>= 1;
      }
      break;
    }
    return bits;
  }

  static Uint8List _buildResponse({
    required int id,
    required InternetAddress ip,
    required int ttl,
    required bool cacheFlush,
    bool echoQuestion = false,
  }) {
    final b = BytesBuilder();
    void u16(int v) => b.add([(v >> 8) & 0xff, v & 0xff]);
    void u32(int v) => b.add([(v >> 24) & 0xff, (v >> 16) & 0xff, (v >> 8) & 0xff, v & 0xff]);
    final name = _encodeName(_name!);

    u16(id);
    u16(0x8400); // 响应 + 权威
    u16(echoQuestion ? 1 : 0);
    u16(1);
    u16(0);
    u16(0);
    if (echoQuestion) {
      b.add(name);
      u16(_typeA);
      u16(1);
    }
    b.add(name);
    u16(_typeA);
    u16(cacheFlush ? 0x8001 : 0x0001);
    u32(ttl);
    u16(4);
    b.add(ip.rawAddress);
    return b.toBytes();
  }

  static Uint8List _encodeName(String name) {
    final b = BytesBuilder();
    for (final label in name.split('.')) {
      final bytes = label.codeUnits;
      b.addByte(bytes.length);
      b.add(bytes);
    }
    b.addByte(0);
    return b.toBytes();
  }

  static const int _typeA = 1;
  static const int _typeAny = 255;

  static _Query? _parseQuery(Uint8List data) {
    try {
      if (data.length < 12) {
        return null;
      }
      final view = ByteData.sublistView(data);
      final id = view.getUint16(0);
      final flags = view.getUint16(2);
      if (flags & 0x8000 != 0) {
        return null; // 别人的响应，不管
      }
      final qd = view.getUint16(4);
      var off = 12;
      final questions = <(String, int, bool)>[];
      for (var i = 0; i < qd; i++) {
        final (name, next) = _readName(data, off);
        if (next + 4 > data.length) {
          return null;
        }
        final type = view.getUint16(next);
        final cls = view.getUint16(next + 2);
        questions.add((name, type, cls & 0x8000 != 0));
        off = next + 4;
      }
      return _Query(id, questions);
    } catch (_) {
      return null;
    }
  }

  /// 读一个域名，支持压缩指针。返回 (小写域名, 紧跟在域名后面的偏移)。
  static (String, int) _readName(Uint8List data, int off) {
    final labels = <String>[];
    var end = -1;
    var jumps = 0;
    while (true) {
      final len = data[off];
      if (len == 0) {
        off++;
        break;
      }
      if (len & 0xc0 == 0xc0) {
        if (++jumps > 16) {
          throw const FormatException('mdns name loop');
        }
        if (end < 0) {
          end = off + 2;
        }
        off = ((len & 0x3f) << 8) | data[off + 1];
        continue;
      }
      labels.add(String.fromCharCodes(data.sublist(off + 1, off + 1 + len)));
      off += 1 + len;
    }
    return (labels.join('.').toLowerCase(), end < 0 ? off : end);
  }
}

class _Query {
  final int id;

  /// (域名, 类型, QU 位：要求单播回复)
  final List<(String, int, bool)> questions;

  _Query(this.id, this.questions);

  bool _matches((String, int, bool) q, String name) {
    return q.$1 == name.toLowerCase() && (q.$2 == LanHost._typeA || q.$2 == LanHost._typeAny);
  }

  bool asksFor(String name) => questions.any((q) => _matches(q, name));

  /// 问到本机的那几条全都带了 QU 位才单播回，否则按规矩组播
  bool unicastResponse(String name) => questions.where((q) => _matches(q, name)).every((q) => q.$3);
}
