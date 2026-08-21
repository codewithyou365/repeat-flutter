import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:repeat_flutter/logic/ai/ai_catalog.dart';
import 'package:repeat_flutter/logic/ai/ai_model_paths.dart';

/// 直接读磁盘上的 assets/ai/catalog.json，不走 rootBundle：
/// rootBundle 要 Flutter 引擎起来，而这里要验的只是清单内容本身。
AiCatalog loadCatalogFromDisk() {
  final raw = File('assets/ai/catalog.json').readAsStringSync();
  // _parse 是私有的，用公开的构造路径绕一圈：把 json 喂给同一套 fromJson。
  final decoded = jsonDecode(raw) as Map<String, dynamic>;
  final models = (decoded['models'] as List)
      .map((e) => AiModelEntry.fromJson(e as Map<String, dynamic>))
      .toList();
  final presets = (decoded['presets'] as List)
      .map((e) => AiPreset.fromJson(e as Map<String, dynamic>))
      .toList();
  return AiCatalog(
    version: decoded['v'] as int,
    models: models.whereType<AiModelEntry>().toList(),
    presets: presets.whereType<AiPreset>().toList(),
  );
}

void main() {
  test('内置清单每一条都解析得出来', () {
    final raw = jsonDecode(File('assets/ai/catalog.json').readAsStringSync()) as Map<String, dynamic>;
    final catalog = loadCatalogFromDisk();
    // fromJson 返回 null 的条目会被静默丢掉，所以数量必须对得上，
    // 否则清单里写错一个字段只会表现为"这个模型在设置页里不见了"。
    expect(catalog.models.length, (raw['models'] as List).length);
    expect(catalog.presets.length, (raw['presets'] as List).length);
  });

  test('四个角色都至少有一个可选模型', () {
    final catalog = loadCatalogFromDisk();
    for (final role in AiRole.values) {
      expect(catalog.byRole(role), isNotEmpty, reason: '角色 ${role.name} 没有任何候选模型');
    }
  });

  test('每个模型的 url/体积都填了，id 不重复', () {
    final catalog = loadCatalogFromDisk();
    final ids = <String>{};
    for (final m in catalog.models) {
      expect(ids.add(m.id), isTrue, reason: 'id 重复: ${m.id}');
      expect(m.downloadUnits, isNotEmpty, reason: '${m.id} 没有任何下载项');
      for (final f in m.downloadUnits) {
        expect(f.url, startsWith('http'), reason: '${m.id}/${f.path} 的 url 不对');
        // 没有 sha1 时安装器退回按体积校验，所以 size 不能是 0，
        // 否则那个文件等于完全没有校验（见 AiModelHelp._verify）。
        expect(f.size, greaterThan(0), reason: '${m.id}/${f.path} 没填体积，会绕过校验');
      }
      expect(m.size, greaterThan(0));
    }
  });

  test('预设引用的模型都在清单里，且凑得齐四个角色', () {
    final catalog = loadCatalogFromDisk();
    expect(catalog.presets, isNotEmpty);
    for (final p in catalog.presets) {
      final roles = <AiRole>{};
      for (final id in p.modelIds) {
        final m = catalog.byId(id);
        expect(m, isNotNull, reason: '预设 ${p.id} 引用了不存在的模型 $id');
        roles.addAll(m!.roles);
      }
      // 缺角色的预设是最坑的：用户下完一整套几百 MB，进去还是被拦着说缺模型。
      expect(roles, containsAll(AiRole.values), reason: '预设 ${p.id} 凑不齐四个角色');
    }
  });

  test('cfg 里的相对路径会被解析成绝对路径，非路径字段不动', () {
    final catalog = loadCatalogFromDisk();
    final tts = catalog.byRole(AiRole.tts).first;
    final resolved = AiModelPaths.resolve(tts.cfg, '/tmp/m/${tts.id}');
    final vits = (resolved['model'] as Map<String, dynamic>)['vits'] as Map<String, dynamic>;
    expect(vits['model'], startsWith('/tmp/m/${tts.id}/'));
    expect(vits['dictDir'], startsWith('/tmp/m/${tts.id}/'));
    // ruleFsts 是逗号分隔的多个路径，每一段都要解析
    final ruleFsts = resolved['ruleFsts'] as String;
    expect(ruleFsts.split(','), everyElement(startsWith('/tmp/m/${tts.id}/')));
    // provider 是 'cpu' 这种枚举值，绝不能被拼上目录前缀
    expect((resolved['model'] as Map<String, dynamic>)['provider'], 'cpu');

    final asr = catalog.models.firstWhere((e) => e.cfg.toString().contains('whisper'));
    final model = (AiModelPaths.resolve(asr.cfg, '/tmp/m/x')['model']) as Map<String, dynamic>;
    final whisper = model['whisper'] as Map<String, dynamic>;
    expect(whisper['encoder'], startsWith('/tmp/m/x/'));
    expect(whisper['task'], 'transcribe');
  });
}
