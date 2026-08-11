import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/common/await_util.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/model/book_content.dart';
import 'package:repeat_flutter/logic/widget/assistive_touch/at_action.dart';
import 'package:repeat_flutter/page/repeat/logic/constant.dart';
import 'package:repeat_flutter/widget/overlay/overlay.dart';
import 'package:repeat_flutter/widget/row/row_widget.dart';
import 'package:repeat_flutter/widget/sheet/sheet.dart';

import 'helper.dart';

class TtsHelper {
  final FlutterTts tts = FlutterTts();
  final TtsPage ttsPage = TtsPage();
  List<String> availableEngines = [];
  String currEngine = '';
  static String cacheConfig = '';

  // Track playback state since the getter is missing in the plugin
  bool _isSpeaking = false;

  TtsHelper() {
    _initHandlers();
  }

  void _initHandlers() {
    tts.setStartHandler(() => _isSpeaking = true);
    tts.setCompletionHandler(() => _isSpeaking = false);
    tts.setCancelHandler(() => _isSpeaking = false);
    tts.setErrorHandler((msg) {
      _isSpeaking = false;
      debugPrint("TTS Error: $msg");
    });
  }

  /// 按字段类型存在 CrKv 里的那套配置（提示/问题/答案/笔记各一份，见 [TtsKeys]）。
  /// 悬浮球的 tts 动作不走这里——它每个动作自己带一份（见 [AtTtsConfig]）。
  Future<TtsSettings> _loadFromKeys(TtsKeys keys) async {
    final queryKeys = <CrK>[
      if (Platform.isAndroid) keys.engine,
      if (Platform.isAndroid) keys.languageIndex,
      if (Platform.isAndroid) keys.voiceIndex,
      keys.rateIndex,
      keys.pitchIndex,
    ];
    final records = await Db().db.crKvDao.findByClassroomAndKeys(Classroom.curr, queryKeys);
    final configByKey = <CrK, String>{};
    for (final record in records) {
      configByKey[record.k] = record.value;
    }
    return TtsSettings(
      engine: configByKey[keys.engine],
      languageIndex: int.tryParse(configByKey[keys.languageIndex] ?? ''),
      voiceIndex: int.tryParse(configByKey[keys.voiceIndex] ?? ''),
      rateIndex: int.tryParse(configByKey[keys.rateIndex] ?? ''),
      pitchIndex: int.tryParse(configByKey[keys.pitchIndex] ?? ''),
    );
  }

  Future<void> _saveToKeys(TtsKeys keys, TtsSettings s) async {
    Future<void> put(CrK k, Object? v) async {
      if (v == null) {
        return;
      }
      await Db().db.crKvDao.insertOrReplace(CrKv(Classroom.curr, k, '$v'));
    }

    if (Platform.isAndroid) {
      await put(keys.engine, s.engine);
      await put(keys.languageIndex, s.languageIndex);
      await put(keys.voiceIndex, s.voiceIndex);
    }
    await put(keys.rateIndex, s.rateIndex);
    await put(keys.pitchIndex, s.pitchIndex);
  }

  Future<bool> tryInit(TtsKeys keys) async {
    if (_isSpeaking) {
      return false;
    }
    await AwaitUtil.tryDo(() async => await _apply(await _loadFromKeys(keys)));
    return true;
  }

  /// 悬浮球 tts 动作用：配置直接给，不查 CrKv。
  Future<bool> tryInitWith(TtsSettings settings) async {
    if (_isSpeaking) {
      return false;
    }
    await AwaitUtil.tryDo(() async => await _apply(settings));
    return true;
  }

  /// 把一份配置灌进播放器。跟上次灌的完全一样就直接返回——切引擎/查音色都很慢，
  /// 每次朗读都重来一遍会明显卡顿。
  Future<void> _apply(TtsSettings settings) async {
    bool firstInit = cacheConfig.isEmpty;

    final currConfig = settings.cacheKey;
    if (cacheConfig == currConfig) return;
    cacheConfig = currConfig;

    if (Platform.isAndroid) {
      var engines = await tts.getEngines;
      availableEngines = List<String>.from(engines);
      currEngine = settings.engine ?? (availableEngines.isNotEmpty ? availableEngines[0] : 'com.google.android.tts');

      await tts.setEngine(currEngine);
      await ttsPage.initForAndroid(
        tts,
        currEngine,
        settings.languageIndex,
        settings.voiceIndex,
        settings.rateIndex,
        settings.pitchIndex,
      );
    } else {
      await ttsPage.init(tts, settings.rateIndex, settings.pitchIndex);
    }

    if (firstInit) {
      await tts.awaitSpeakCompletion(true);
    }
  }

  /// 返回是否点了"确定"关闭的（而不是划走/点外面取消）——调用方要"确定了才生效"
  /// 的场景得靠这个区分，不能一概当作已确认。
  Future<bool> open(TtsKeys keys) async {
    final settings = await _loadFromKeys(keys);
    return await openWith(settings, (s) => _saveToKeys(keys, s));
  }

  /// 配置存在别处（悬浮球 tts 动作存在 classroom.content 里）时用：
  /// 面板上每改一项就回调一次 [save]，由调用方决定怎么落库。
  Future<bool> openWith(TtsSettings settings, Future<void> Function(TtsSettings) save) async {
    if (await AwaitUtil.tryDo(() async => await _apply(settings))) {
      return await ttsPage.open(tts, availableEngines, currEngine, save);
    }
    return false;
  }

  Future<void> speak(Helper helper) async {
    final currVerseMap = helper.getCurrVerseMap();
    if (currVerseMap == null) return;

    // 一节可以挂好几条提示，朗读的是界面上当前选中的那一条。
    var tip = VerseField.getText(currVerseMap, helper.currTipRef());
    if (tip == null) return;

    try {
      if (await tryInit(TtsKeys.tip)) {
        await tts.speak(tip);
      }
    } catch (e) {
      _isSpeaking = false;
      debugPrint("TTS Playback Error: $e");
    }
  }

  Future<void> speakText(TtsKeys keys, String text, {double? rate}) async {
    if (text.isEmpty) return;
    await _speak(text, () => tryInit(keys), rate);
  }

  /// 悬浮球 tts 动作用：语速/音色等直接来自这个动作自己的配置。
  Future<void> speakTextWith(TtsSettings settings, String text) async {
    if (text.isEmpty) return;
    await _speak(text, () => tryInitWith(settings), null);
  }

  Future<void> _speak(String text, Future<bool> Function() init, double? rate) async {
    try {
      if (await init()) {
        if (rate != null) {
          // 临时覆盖语速，只影响这一次朗读；用完立刻让缓存失效，
          // 这样其它功能下次朗读时会从持久化配置重新加载自己的语速，不会被这次覆盖污染
          await tts.setSpeechRate(rate);
        }
        await tts.speak(text);
        if (rate != null) {
          cacheConfig = '';
        }
      }
    } catch (e) {
      _isSpeaking = false;
      debugPrint("TTS Playback Error: $e");
    }
  }

  void stop() {
    cacheConfig = '';
    _isSpeaking = false;
    tts.stop();
  }
}

class TtsPage {
  final RxList<String> languages = <String>[].obs;
  final RxList<String> voiceNames = <String>[].obs;
  final RxInt langIdx = 0.obs;
  final RxInt voiceIdx = 0.obs;

  // Converted to RxInt for consistent UI updating
  final RxInt rateIdx = 1.obs;
  final RxInt pitchIdx = 2.obs;

  List<Map<String, String>> _allVoices = [];
  List<Map<String, String>> _filteredVoices = [];

  final List<String> pitchOptions = ['0.5', '0.8', '1.0', '1.2', '1.5', '2.0'];
  final List<String> rateOptions = ['0.25', '0.5', '0.75', '1.0'];

  Future<void> initForAndroid(
    FlutterTts tts,
    String engine,
    int? langIdx,
    int? voiceIdx,
    int? rateIdx,
    int? pitchIdx,
  ) async {
    await _updateLanguagesAndVoices(tts, engine, langIdx, voiceIdx);

    if (languages.isNotEmpty && this.langIdx.value < languages.length) {
      await tts.setLanguage(languages[this.langIdx.value]);
    }
    if (_filteredVoices.isNotEmpty && this.voiceIdx.value < _filteredVoices.length) {
      await tts.setVoice(_filteredVoices[this.voiceIdx.value]);
    }
    await init(tts, rateIdx, pitchIdx);
  }

  Future<void> init(FlutterTts tts, int? rateIdx, int? pitchIdx) async {
    if (rateIdx == null || rateIdx >= rateOptions.length) {
      this.rateIdx.value = 1;
    } else {
      this.rateIdx.value = rateIdx;
    }
    await tts.setSpeechRate(double.parse(rateOptions[this.rateIdx.value]));

    if (pitchIdx == null || pitchIdx >= pitchOptions.length) {
      this.pitchIdx.value = 2;
    } else {
      this.pitchIdx.value = pitchIdx;
    }
    await tts.setPitch(double.parse(pitchOptions[this.pitchIdx.value]));
  }

  /// 面板上现在这一套设置。改了哪一项都用它整份回存，调用方不用逐项拼。
  TtsSettings _current(String engine) => TtsSettings(
        engine: Platform.isAndroid ? engine : null,
        languageIndex: Platform.isAndroid ? langIdx.value : null,
        voiceIndex: Platform.isAndroid ? voiceIdx.value : null,
        rateIndex: rateIdx.value,
        pitchIndex: pitchIdx.value,
      );

  /// 返回值表示是不是点"确定"关的：划走/点外面取消时 Sheet.showBottomSheet 拿到的是 null，
  /// 这里统一转成 false，调用方不用再操心区分 null 和 false。
  Future<bool> open(
    FlutterTts tts,
    List<String> availableEngines,
    String currEngine,
    Future<void> Function(TtsSettings) save,
  ) async {
    int engineIndex = availableEngines.indexOf(currEngine);
    if (engineIndex == -1) engineIndex = 0;
    var engine = currEngine;
    final confirmed = await Sheet.showBottomSheet<bool>(
      Get.context!,
      head: _buildHeader(),
      ListView(
        shrinkWrap: true,
        children: [
          if (Platform.isAndroid && availableEngines.isNotEmpty) ...[
            RowWidget.buildCupertinoPicker(
              title: I18nKey.ttsEngine.tr,
              options: availableEngines,
              value: engineIndex,
              pickWidth: 200,
              changed: (index) async {
                engine = availableEngines[index];

                await showOverlay<void>(() async {
                  await tts.setEngine(engine);
                  // Small delay helps some Android engines stabilize before querying voices
                  await Future.delayed(const Duration(milliseconds: 300));
                  await _updateLanguagesAndVoices(tts, engine, null, null);

                  if (languages.isNotEmpty) {
                    await tts.setLanguage(languages[langIdx.value]);
                  }
                  await save(_current(engine));
                }, I18nKey.loading.tr);
              },
            ),
            RowWidget.buildDividerWithoutColor(),
            Obx(
              () => RowWidget.buildCupertinoPicker(
                title: I18nKey.ttsLanguage.tr,
                options: languages.toList(),
                value: langIdx.value,
                changed: (index) async {
                  langIdx.value = index;
                  await tts.setLanguage(languages[index]);
                  await _filterVoicesByLanguage(languages[index], null);
                  await save(_current(engine));
                },
              ),
            ),
            RowWidget.buildDividerWithoutColor(),
            Obx(
              () => RowWidget.buildCupertinoPicker(
                title: I18nKey.ttsVoice.tr,
                options: voiceNames.toList(),
                value: voiceIdx.value,
                pickWidth: 180,
                changed: (index) async {
                  voiceIdx.value = index;
                  if (_filteredVoices.isNotEmpty && index < _filteredVoices.length) {
                    await tts.setVoice(_filteredVoices[index]);
                    await save(_current(engine));
                  }
                },
              ),
            ),
            RowWidget.buildDividerWithoutColor(),
          ],
          Obx(
            () => RowWidget.buildCupertinoPicker(
              title: I18nKey.ttsSpeechRate.tr,
              options: rateOptions,
              value: rateIdx.value,
              changed: (index) async {
                rateIdx.value = index;
                await tts.setSpeechRate(double.parse(rateOptions[index]));
                await save(_current(engine));
              },
            ),
          ),
          RowWidget.buildDividerWithoutColor(),
          Obx(
            () => RowWidget.buildCupertinoPicker(
              title: I18nKey.ttsPitch.tr,
              options: pitchOptions,
              value: pitchIdx.value,
              changed: (index) async {
                pitchIdx.value = index;
                await tts.setPitch(double.parse(pitchOptions[index]));
                await save(_current(engine));
              },
            ),
          ),
          RowWidget.buildDividerWithoutColor(),
          RowWidget.buildButtons([
            Button(I18nKey.btnOk.tr, () => Get.back(result: true)),
          ]),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _updateLanguagesAndVoices(
    FlutterTts tts,
    String engine,
    int? savedLangIdx,
    int? savedVoiceIdx,
  ) async {
    List<dynamic> rawLangs = await tts.getLanguages;
    languages.assignAll(rawLangs.map((e) => e.toString()).toList());

    List<dynamic> rawVoices = await tts.getVoices;
    _allVoices = rawVoices.map((e) => Map<String, String>.from(e)).toList();

    if (savedLangIdx != null && savedLangIdx < languages.length) {
      langIdx.value = savedLangIdx;
    } else {
      int initialLang = languages.indexOf("en-US");
      langIdx.value = (initialLang != -1) ? initialLang : 0;
    }

    if (languages.isNotEmpty) {
      await _filterVoicesByLanguage(languages[langIdx.value], savedVoiceIdx);
    }
  }

  Future<void> _filterVoicesByLanguage(String langCode, int? savedVoiceIdx) async {
    _filteredVoices = _allVoices.where((v) => v['locale'] == langCode).toList();

    if (_filteredVoices.isEmpty) {
      voiceNames.assignAll(["Default"]);
      voiceIdx.value = 0;
    } else {
      voiceNames.assignAll(_filteredVoices.map((v) => v['name'] ?? 'Unknown').toList());
      if (savedVoiceIdx != null && savedVoiceIdx < _filteredVoices.length) {
        voiceIdx.value = savedVoiceIdx;
      } else {
        voiceIdx.value = 0;
      }
    }
  }

  SheetHead _buildHeader() {
    return SheetHead(
      height: RowWidget.rowHeight + RowWidget.dividerHeight,
      widgets: [
        RowWidget.buildText(I18nKey.ttsSettings.tr, ''),
        RowWidget.buildDivider(),
      ],
    );
  }
}
