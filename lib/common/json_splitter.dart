import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// 流式切分课堂文档。
///
/// 课堂文档的形状是 `{ ...小的课堂内容..., "b":[ {一本书}, {一本书}, ... ] }`，
/// 整份可能几十上百 MB，不能 `jsonDecode` 整个读进内存。
///
/// 这里逐字节扫字节流：顶层除 [arrayKey] 之外的 key 照常收进一个小 Map（课堂内容本来就小），
/// [arrayKey] 数组里的每个元素**原样按字节**（不解析、不重新编码）写成一个单独的文件，
/// 之后一本一本地 `jsonDecode` 处理，内存峰值只有一本书。
///
/// 只认结构字符（`{}[]",:`），这些都是 ASCII，UTF-8 里多字节字符的每个字节都 >= 0x80，
/// 不会被误判成结构字符，所以逐字节扫是安全的。
///
/// 限制：[arrayKey] 数组的元素必须是对象或数组，不能是裸标量。
class JsonSplitter {
  /// 顶层除 [arrayKey] 外的内容
  final Map<String, dynamic> head = {};

  /// 切出来的元素文件路径，顺序就是数组顺序
  final List<String> elementPaths = [];

  final String arrayKey;

  /// 每个元素落到 `<outDir>/<下标><outSuffix>`
  final String outDir;
  final String outSuffix;

  JsonSplitter({
    required this.outDir,
    this.arrayKey = 'b',
    this.outSuffix = '.json',
  });

  /// 切分 [file]。返回 false 表示这不是一份合法的、带 [arrayKey] 数组的顶层对象。
  Future<bool> split(File file) async {
    if (!await file.exists()) {
      return false;
    }
    await Directory(outDir).create(recursive: true);
    final scanner = _Scanner(this);
    try {
      await for (final chunk in file.openRead()) {
        if (!await scanner.feed(chunk)) {
          await scanner.abort();
          return false;
        }
      }
      return await scanner.finish();
    } catch (e) {
      await scanner.abort();
      rethrow;
    }
  }
}

enum _State {
  /// 还没进入顶层 '{'
  beforeRoot,

  /// 在顶层对象里找下一个 key
  inRootObject,

  /// 正在读一个顶层 "key": value
  copyingValue,

  /// 已经进入目标数组，等下一个元素或 ']'
  inArray,

  /// 正在抄目标数组里的一个元素
  copyingElement,
}

class _Scanner {
  final JsonSplitter owner;

  _State state = _State.beforeRoot;

  /// 当前正在攒的字节
  final BytesBuilder _buf = BytesBuilder(copy: false);

  /// 当前顶层 key（正在读它的 value 时有效）
  String? _key;

  int _depth = 0;
  bool _inString = false;
  bool _escaped = false;

  IOSink? _sink;
  bool _sawArray = false;

  _Scanner(this.owner);

  /// 返回 false 表示文档结构不合法，调用方应停止
  Future<bool> feed(List<int> chunk) async {
    for (final byte in chunk) {
      if (!await _feedByte(byte)) {
        return false;
      }
    }
    return true;
  }

  Future<bool> _feedByte(int byte) async {
    switch (state) {
      case _State.beforeRoot:
        if (byte == _Char.leftBrace) {
          state = _State.inRootObject;
        }
        return true;

      case _State.inRootObject:
        // 顶层对象里只等下一个 key 的起始引号，逗号/空白/收尾的 '}' 都可以忽略
        if (byte == _Char.quote) {
          _startKey(byte);
        }
        return true;

      case _State.copyingValue:
        return await _copyValueByte(byte);

      case _State.inArray:
        if (byte == _Char.rightBracket) {
          state = _State.inRootObject;
          return true;
        }
        if (_isWhitespace(byte) || byte == _Char.comma) {
          return true;
        }
        if (byte != _Char.leftBrace && byte != _Char.leftBracket) {
          // 数组元素必须是对象或数组
          return false;
        }
        _buf.clear();
        _depth = 0;
        _inString = false;
        _escaped = false;
        _sink = File(_nextElementPath()).openWrite();
        state = _State.copyingElement;
        await _copyElementByte(byte);
        return true;

      case _State.copyingElement:
        await _copyElementByte(byte);
        return true;
    }
  }

  void _startKey(int byte) {
    _buf.clear();
    _buf.addByte(byte);
    _inString = true;
    _escaped = false;
    _key = null;
    _depth = 0;
    state = _State.copyingValue;
  }

  /// 读一个顶层 `"key": value`：
  /// key 读完切到读 value；value 读完（深度回 0 且遇到 ',' 或顶层 '}'）落进 head，
  /// 如果 key 正好是目标数组，就切到 [_State.inArray] 让元素单独落盘。
  Future<bool> _copyValueByte(int byte) async {
    if (_inString) {
      _buf.addByte(byte);
      if (_escaped) {
        _escaped = false;
      } else if (byte == _Char.backslash) {
        _escaped = true;
      } else if (byte == _Char.quote) {
        _inString = false;
        if (_key == null && _depth == 0) {
          _key = jsonDecode(utf8.decode(_buf.takeBytes())) as String;
        }
      }
      return true;
    }

    if (_key == null) {
      // key 和 ':' 之间的空白
      return true;
    }

    if (_depth == 0 && _buf.isEmpty) {
      if (byte == _Char.colon || _isWhitespace(byte)) {
        return true;
      }
      if (byte == _Char.leftBracket && _key == owner.arrayKey) {
        _sawArray = true;
        _key = null;
        state = _State.inArray;
        return true;
      }
    }

    if (byte == _Char.quote) {
      _inString = true;
      _buf.addByte(byte);
      return true;
    }

    if (byte == _Char.leftBrace || byte == _Char.leftBracket) {
      _depth++;
      _buf.addByte(byte);
      return true;
    }

    if (byte == _Char.rightBrace || byte == _Char.rightBracket) {
      if (_depth == 0) {
        // 顶层对象的 '}'：当前 value 到此为止
        _finishValue();
        state = _State.inRootObject;
        return true;
      }
      _depth--;
      _buf.addByte(byte);
      return true;
    }

    if (_depth == 0 && byte == _Char.comma) {
      _finishValue();
      state = _State.inRootObject;
      return true;
    }

    _buf.addByte(byte);
    return true;
  }

  void _finishValue() {
    final key = _key;
    _key = null;
    final bytes = _buf.takeBytes();
    if (key == null) {
      return;
    }
    final raw = utf8.decode(bytes).trim();
    if (raw.isEmpty) {
      return;
    }
    if (key == owner.arrayKey) {
      // 'b' 是保留 key，不进 head
      return;
    }
    owner.head[key] = jsonDecode(raw);
  }

  /// 抄目标数组里的一个元素：原样按字节写进它自己的文件。
  Future<void> _copyElementByte(int byte) async {
    _buf.addByte(byte);

    if (_inString) {
      if (_escaped) {
        _escaped = false;
      } else if (byte == _Char.backslash) {
        _escaped = true;
      } else if (byte == _Char.quote) {
        _inString = false;
      }
    } else if (byte == _Char.quote) {
      _inString = true;
    } else if (byte == _Char.leftBrace || byte == _Char.leftBracket) {
      _depth++;
    } else if (byte == _Char.rightBrace || byte == _Char.rightBracket) {
      _depth--;
    }

    // 攒够一段就写出去，别让整本书都堆在内存里
    if (_buf.length >= _flushThreshold) {
      _sink!.add(_buf.takeBytes());
    }

    if (_depth == 0 && !_inString) {
      await _closeElement();
      state = _State.inArray;
    }
  }

  Future<void> _closeElement() async {
    final sink = _sink!;
    _sink = null;
    sink.add(_buf.takeBytes());
    await sink.flush();
    await sink.close();
  }

  String _nextElementPath() {
    final path = '${owner.outDir}/${owner.elementPaths.length}${owner.outSuffix}';
    owner.elementPaths.add(path);
    return path;
  }

  Future<bool> finish() async {
    if (_sink != null) {
      // 文件在某个元素中间就断了
      await abort();
      return false;
    }
    return _sawArray;
  }

  Future<void> abort() async {
    final sink = _sink;
    _sink = null;
    if (sink != null) {
      await sink.close();
    }
  }

  static const int _flushThreshold = 1 << 16;

  static bool _isWhitespace(int byte) {
    return byte == 0x20 || byte == 0x09 || byte == 0x0a || byte == 0x0d;
  }
}

class _Char {
  static const int leftBrace = 0x7b; // {
  static const int rightBrace = 0x7d; // }
  static const int leftBracket = 0x5b; // [
  static const int rightBracket = 0x5d; // ]
  static const int quote = 0x22; // "
  static const int backslash = 0x5c; // \
  static const int colon = 0x3a; // :
  static const int comma = 0x2c; // ,
}
