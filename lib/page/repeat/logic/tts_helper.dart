import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/widget/overlay/overlay.dart';
import 'package:repeat_flutter/widget/row/row_widget.dart';
import 'package:repeat_flutter/widget/sheet/sheet.dart';

import 'helper.dart';

class TtsHelper {
  final FlutterTts tts = FlutterTts();
  final TtsPage ttsPage = TtsPage();
  List<String> availableEngines = [];
  String currEngine = '';

  Future<void> init() async {
    if (Platform.isAndroid) {
      var engines = await tts.getEngines;
      availableEngines = List<String>.from(engines);
      String? savedEngine = await Db().db.crKvDao.getStr(Classroom.curr, CrK.ttsEngine);
      currEngine = savedEngine ?? (availableEngines.isNotEmpty ? availableEngines[0] : 'com.google.android.tts');
      await tts.setEngine(currEngine);
      int? ttsLanguageIndex = await Db().db.crKvDao.getInt(Classroom.curr, CrK.ttsLanguageIndex);
      int? ttsVoiceIndex = await Db().db.crKvDao.getInt(Classroom.curr, CrK.ttsVoiceIndex);
      int? ttsRateIndex = await Db().db.crKvDao.getInt(Classroom.curr, CrK.ttsRateIndex);
      int? ttsPitchIndex = await Db().db.crKvDao.getInt(Classroom.curr, CrK.ttsPitchIndex);
      await ttsPage.initForAndroid(
        tts,
        currEngine,
        ttsLanguageIndex,
        ttsVoiceIndex,
        ttsRateIndex,
        ttsPitchIndex,
      );
    } else {
      int? ttsRateIndex = await Db().db.crKvDao.getInt(Classroom.curr, CrK.ttsRateIndex);
      int? ttsPitchIndex = await Db().db.crKvDao.getInt(Classroom.curr, CrK.ttsPitchIndex);
      await ttsPage.init(tts, ttsRateIndex, ttsPitchIndex);
    }
    await tts.awaitSpeakCompletion(true);
  }

  void open() {
    ttsPage.open(tts, availableEngines, currEngine);
  }

  void speak(Helper helper) async {
    final currVerseMap = helper.getCurrVerseMap();

    if (currVerseMap == null) return;

    var tip = currVerseMap['t'];
    if (tip is! String) return;

    try {
      await tts.speak(tip, focus: true);
    } catch (e) {
      debugPrint("TTS Playback Error: $e");
    }
  }

  void stop() => tts.stop();
}

class TtsPage {
  final RxList<String> languages = <String>[].obs;
  final RxList<String> voiceNames = <String>[].obs;
  final RxInt langIdx = 0.obs;
  final RxInt voiceIdx = 0.obs;

  List<Map<String, String>> _allVoices = [];
  List<Map<String, String>> _filteredVoices = [];

  int rateIdx = 0;
  int pitchIdx = 0;
  final List<String> pitchOptions = ['0.5', '0.8', '1.0', '1.2', '1.5', '2.0'];
  final List<String> rateOptions = ['0.25', '0.5', '0.75', '1'];

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
      rateIdx = 1;
      this.rateIdx = rateIdx;
    }
    await tts.setSpeechRate(double.parse(rateOptions[rateIdx]));
    if (pitchIdx == null || pitchIdx >= pitchOptions.length) {
      pitchIdx = 2;
      this.pitchIdx = pitchIdx;
    }
    await tts.setPitch(double.parse(pitchOptions[pitchIdx]));
  }

  Future<void> open(
    FlutterTts tts,
    List<String> availableEngines,
    String currEngine,
  ) async {
    int engineIndex = availableEngines.indexOf(currEngine);
    if (engineIndex == -1) engineIndex = 0;

    return Sheet.withHeaderAndBody<void>(
      Get.context!,
      _buildHeader(),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 0.0),
        child: ListView(
          shrinkWrap: true,
          children: [
            if (Platform.isAndroid && availableEngines.isNotEmpty) ...[
              RowWidget.buildCupertinoPicker(
                title: I18nKey.ttsEngine.tr,
                options: availableEngines,
                value: engineIndex,
                pickWidth: 200,
                changed: (index) async {
                  engineIndex = index;
                  String engineName = availableEngines[index];
                  await Db().db.crKvDao.insertOrReplace(CrKv(Classroom.curr, CrK.ttsEngine, engineName));
                  await showOverlay<void>(() async {
                    await tts.setEngine(engineName);
                    await _updateLanguagesAndVoices(tts, engineName, null, null);
                    if (languages.isNotEmpty && langIdx.value < languages.length) {
                      await Db().db.crKvDao.insertOrReplace(CrKv(Classroom.curr, CrK.ttsLanguageIndex, '$langIdx'));
                      await tts.setLanguage(languages[langIdx.value]);
                    }
                    if (_filteredVoices.isNotEmpty && voiceIdx.value < _filteredVoices.length) {
                      await Db().db.crKvDao.insertOrReplace(CrKv(Classroom.curr, CrK.ttsVoiceIndex, '$voiceIdx'));
                      await tts.setVoice(_filteredVoices[voiceIdx.value]);
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
                    await Db().db.crKvDao.insertOrReplace(CrKv(Classroom.curr, CrK.ttsLanguageIndex, '$index'));
                    await tts.setLanguage(languages[langIdx.value]);
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
                    if (_filteredVoices.isNotEmpty && voiceIdx.value < _filteredVoices.length) {
                      await Db().db.crKvDao.insertOrReplace(CrKv(Classroom.curr, CrK.ttsVoiceIndex, '$index'));
                      await tts.setVoice(_filteredVoices[index]);
                    } else {
                      await Db().db.crKvDao.insertOrReplace(CrKv(Classroom.curr, CrK.ttsVoiceIndex, '-1'));
                    }
                  },
                ),
              ),
              RowWidget.buildDividerWithoutColor(),
            ],
            RowWidget.buildCupertinoPicker(
              title: I18nKey.ttsSpeechRate.tr,
              options: rateOptions,
              value: rateIdx,
              changed: (index) async {
                rateIdx = index;
                await Db().db.crKvDao.insertOrReplace(CrKv(Classroom.curr, CrK.ttsRateIndex, '$index'));
                await tts.setSpeechRate(double.parse(rateOptions[index]));
              },
            ),
            RowWidget.buildDividerWithoutColor(),
            RowWidget.buildCupertinoPicker(
              title: I18nKey.ttsPitch.tr,
              options: pitchOptions,
              value: pitchIdx,
              changed: (index) async {
                pitchIdx = index;
                await Db().db.crKvDao.insertOrReplace(CrKv(Classroom.curr, CrK.ttsPitchIndex, '$index'));
                await tts.setPitch(double.parse(pitchOptions[index]));
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateLanguagesAndVoices(
    FlutterTts tts,
    String engine,
    int? langIdx,
    int? voiceIdx,
  ) async {
    List<dynamic> rawLangs = await tts.getLanguages;
    languages.value = rawLangs.map((e) => e.toString()).toList();

    List<dynamic> rawVoices = await tts.getVoices;
    _allVoices = rawVoices.map((e) => Map<String, String>.from(e)).toList();
    if (langIdx != null && langIdx < languages.length) {
      this.langIdx.value = langIdx;
      await _filterVoicesByLanguage(languages[langIdx], voiceIdx);
    } else {
      int initialLang = languages.indexOf("en-US");
      this.langIdx.value = (initialLang != -1) ? initialLang : 0;

      if (languages.isNotEmpty) {
        await _filterVoicesByLanguage(languages[this.langIdx.value], null);
      }
    }
  }

  Future<void> _filterVoicesByLanguage(String langCode, int? voiceIdx) async {
    _filteredVoices = _allVoices.where((v) => v['locale'] == langCode).toList();

    if (_filteredVoices.isEmpty) {
      voiceNames.value = ["Default"];
    } else {
      voiceNames.value = _filteredVoices.map((v) => v['name'] ?? 'Unknown').toList();
    }
    if (voiceIdx != null && voiceIdx < _filteredVoices.length) {
      this.voiceIdx.value = voiceIdx;
    } else {
      this.voiceIdx.value = 0;
    }
  }

  Widget _buildHeader() {
    return Padding(
      key: GlobalKey(),
      padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 0.0),
      child: Column(
        children: [
          RowWidget.buildText(I18nKey.ttsSettings.tr, ''),
          RowWidget.buildDivider(),
        ],
      ),
    );
  }
}
