import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/common/await_util.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
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

  Future<Map<CrK, String>> _loadConfig(TtsKeys keys, {required bool isAndroid}) async {
    final queryKeys = <CrK>[
      if (isAndroid) keys.engine,
      if (isAndroid) keys.languageIndex,
      if (isAndroid) keys.voiceIndex,
      keys.rateIndex,
      keys.pitchIndex,
    ];
    final records = await Db().db.crKvDao.findByClassroomAndKeys(Classroom.curr, queryKeys);
    final configByKey = <CrK, String>{};
    for (final record in records) {
      configByKey[record.k] = record.value;
    }
    return configByKey;
  }

  Future<bool> tryInit(TtsKeys keys) async {
    if (_isSpeaking) {
      return false;
    }
    await AwaitUtil.tryDo(() async => await _tryInit(keys));
    return true;
  }

  Future<void> _tryInit(TtsKeys keys) async {
    bool firstInit = cacheConfig.isEmpty;

    if (Platform.isAndroid) {
      final configs = await _loadConfig(keys, isAndroid: true);
      final savedEngine = configs[keys.engine];
      final ttsLanguageIndex = int.tryParse(configs[keys.languageIndex] ?? '');
      final ttsVoiceIndex = int.tryParse(configs[keys.voiceIndex] ?? '');
      final ttsRateIndex = int.tryParse(configs[keys.rateIndex] ?? '');
      final ttsPitchIndex = int.tryParse(configs[keys.pitchIndex] ?? '');

      final currConfig = "$savedEngine-$ttsLanguageIndex-$ttsVoiceIndex-$ttsRateIndex-$ttsPitchIndex";
      if (cacheConfig == currConfig) return;

      cacheConfig = currConfig;
      var engines = await tts.getEngines;
      availableEngines = List<String>.from(engines);
      currEngine = savedEngine ?? (availableEngines.isNotEmpty ? availableEngines[0] : 'com.google.android.tts');

      await tts.setEngine(currEngine);
      await ttsPage.initForAndroid(
        tts,
        currEngine,
        ttsLanguageIndex,
        ttsVoiceIndex,
        ttsRateIndex,
        ttsPitchIndex,
      );
    } else {
      final configs = await _loadConfig(keys, isAndroid: false);
      final ttsRateIndex = int.tryParse(configs[keys.rateIndex] ?? '');
      final ttsPitchIndex = int.tryParse(configs[keys.pitchIndex] ?? '');

      final currConfig = "$ttsRateIndex-$ttsPitchIndex";
      if (cacheConfig == currConfig) return;

      cacheConfig = currConfig;
      await ttsPage.init(tts, ttsRateIndex, ttsPitchIndex);
    }

    if (firstInit) {
      await tts.awaitSpeakCompletion(true);
    }
  }

  void open(TtsKeys keys) async {
    if (await AwaitUtil.tryDo(() async => await _tryInit(keys))) {
      ttsPage.open(keys, tts, availableEngines, currEngine);
    }
  }

  Future<void> speak(Helper helper) async {
    final currVerseMap = helper.getCurrVerseMap();
    if (currVerseMap == null) return;

    var tip = currVerseMap['t'];
    if (tip is! String || tip.isEmpty) return;

    try {
      if (await tryInit(TtsKeys.tip)) {
        await tts.speak(tip);
      }
    } catch (e) {
      _isSpeaking = false;
      debugPrint("TTS Playback Error: $e");
    }
  }

  Future<void> speakText(TtsKeys keys, String text) async {
    if (text.isEmpty) return;
    try {
      if (await tryInit(keys)) {
        await tts.speak(text);
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

  Future<void> open(
    TtsKeys keys,
    FlutterTts tts,
    List<String> availableEngines,
    String currEngine,
  ) async {
    int engineIndex = availableEngines.indexOf(currEngine);
    if (engineIndex == -1) engineIndex = 0;
    return Sheet.showBottomSheet<void>(
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
                String engineName = availableEngines[index];
                await Db().db.crKvDao.insertOrReplace(CrKv(Classroom.curr, keys.engine, engineName));

                await showOverlay<void>(() async {
                  await tts.setEngine(engineName);
                  // Small delay helps some Android engines stabilize before querying voices
                  await Future.delayed(const Duration(milliseconds: 300));
                  await _updateLanguagesAndVoices(tts, engineName, null, null);

                  if (languages.isNotEmpty) {
                    await tts.setLanguage(languages[langIdx.value]);
                    await Db().db.crKvDao.insertOrReplace(CrKv(Classroom.curr, keys.languageIndex, '${langIdx.value}'));
                  }
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
                  await Db().db.crKvDao.insertOrReplace(CrKv(Classroom.curr, keys.languageIndex, '$index'));
                  await tts.setLanguage(languages[index]);
                  await _filterVoicesByLanguage(languages[index], null);
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
                    await Db().db.crKvDao.insertOrReplace(CrKv(Classroom.curr, keys.voiceIndex, '$index'));
                    await tts.setVoice(_filteredVoices[index]);
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
                await Db().db.crKvDao.insertOrReplace(CrKv(Classroom.curr, keys.rateIndex, '$index'));
                await tts.setSpeechRate(double.parse(rateOptions[index]));
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
                await Db().db.crKvDao.insertOrReplace(CrKv(Classroom.curr, keys.pitchIndex, '$index'));
                await tts.setPitch(double.parse(pitchOptions[index]));
              },
            ),
          ),
        ],
      ),
    );
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
