import 'package:floor/floor.dart';

import 'm9_10.dart';

/// m9_10 那一版把字段专属媒体的文件对象直接内嵌在字段块里（`'a': {'download': {...}}`），
/// 之后改成了只存 'mediaHash'、文件对象统一进 'd'。装过中间那一版的库已经是 10 了，
/// m9_10 不会再跑，这里把剩下的 'download' 收掉。
///
/// [migrateFieldBlocks] 是幂等的：没有可迁的行就什么都不做。
final m10_11 = Migration(10, 11, migrateFieldBlocks);
