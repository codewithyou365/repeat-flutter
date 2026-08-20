import 'package:repeat_flutter/common/path.dart';

/// 把 catalog 里 `cfg` 的相对路径换成绝对路径。
///
/// 清单里所有路径都是相对模型目录写的（比如 `"model": "model.int8.onnx"`），
/// 这样清单跟设备上的实际安装位置无关；sherpa 那边要的是绝对路径，所以加载前过一遍这里。
///
/// 之所以用白名单而不是"看着像路径就换"：cfg 里同样是字符串的还有 `task`、`language`、
/// `provider`、`decodingMethod` 这些，它们绝不能被当成路径拼上目录前缀。
class AiModelPaths {
  /// sherpa 各 config 里值是"文件/目录路径"的字段名。
  ///
  /// 是照着 sherpa_onnx 1.13.6 的 config 类逐个字段过出来的。将来 sherpa 加了新模型类型、
  /// 而清单又用到了它的新路径字段，要在这里补一条，否则那个字段会被原样当相对路径传下去。
  static const Set<String> pathKeys = {
    'acousticModel', 'bpeVocab', 'cachedDecoder', 'convFrontend', 'ctTransformer',
    'dataDir', 'decoder', 'dictDir', 'durationPredictor', 'embedding', 'encoder',
    'encoderAdaptor', 'hotwordsFile', 'joiner', 'lexicon', 'llm', 'lmFlow', 'lmMain',
    'mergedDecoder', 'model', 'preprocessor', 'ruleFars', 'ruleFsts', 'telespeechCtc',
    'textConditioner', 'textEncoder', 'tokenScoresJson', 'tokenizer', 'tokens',
    'ttsJson', 'uncachedDecoder', 'unicodeIndexer', 'vectorEstimator', 'vocabJson',
    'vocoder', 'voices',
  };

  /// 返回一份新的 map，原 cfg 不动（cfg 来自缓存的 catalog，就地改会污染下一次加载）。
  static Map<String, dynamic> resolve(Map<String, dynamic> cfg, String modelDir) {
    final out = <String, dynamic>{};
    cfg.forEach((k, v) {
      if (v is Map<String, dynamic>) {
        out[k] = resolve(v, modelDir);
      } else if (v is String && pathKeys.contains(k) && v.isNotEmpty) {
        out[k] = _resolveValue(v, modelDir);
      } else {
        out[k] = v;
      }
    });
    return out;
  }

  /// ruleFsts / lexicon 这些字段 sherpa 允许写成逗号分隔的多个路径，得逐段解析。
  static String _resolveValue(String value, String modelDir) {
    return value.split(',').map((e) {
      final p = e.trim();
      if (p.isEmpty) return p;
      // 已经是绝对路径就不动，方便调试时手工指到 adb push 上去的目录
      if (p.startsWith('/')) return p;
      return modelDir.joinPath(p);
    }).join(',');
  }
}
