import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:repeat_flutter/common/path.dart';
import 'package:repeat_flutter/common/time.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/kv.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/logic/doc_help.dart';
import 'package:repeat_flutter/logic/download.dart';
import 'package:repeat_flutter/logic/model/book_content.dart';
import 'package:repeat_flutter/page/repeat/logic/constant.dart';
import 'package:repeat_flutter/widget/overlay/overlay.dart';

enum ExpandStatus {
  init,
  pending,
  finish,
}

class ExpandLogic {
  var serviceUrl = "http://127.0.0.1:8080".obs;
  final TextEditingController textController = TextEditingController();

  var hasContent = false;
  var status = ExpandStatus.init.obs;
  var isInit = true.obs;
  var disabled = false.obs;
  var disabledAudioWidget = true.obs;
  var logs = <String>[].obs;
  var targetOptions = [
    QaType.answer.i18n.tr,
    QaType.tip.i18n.tr,
    QaType.question.i18n.tr,
    QaType.note.i18n.tr,
  ];

  QaType toQaType(int targetIndex) {
    if (targetIndex == 0) {
      return QaType.answer;
    } else if (targetIndex == 1) {
      return QaType.tip;
    } else if (targetIndex == 2) {
      return QaType.question;
    } else {
      return QaType.note;
    }
  }

  var targetIndex = 0.obs;
  var enableAudio = true.obs;
  int bookId = 0;
  int verseId = 0;
  Map<String, dynamic> verseMap = {};
  Timer? _timer;

  Completer<void>? _taskCompleter;

  Future<void> loadSettings() async {
    serviceUrl.value = await Db().db.kvDao.getStr(K.expandServiceUrl) ?? "http://127.0.0.1:8080";
  }

  Future<void> saveServiceUrl() async {
    await Db().db.kvDao.insertOrReplace(Kv(K.expandServiceUrl, serviceUrl.value));
  }

  Future<void> startTask(String msg) async {
    await showOverlay(() async {
      try {
        status.value = ExpandStatus.pending;
        isInit.value = false;
        disabled.value = true;
        disabledAudioWidget.value = true;
        logs.clear();
        logs.add("Initiating request...");

        _taskCompleter = Completer<void>();

        String runnerType = enableAudio.value ? "withSpeak" : "standard";

        final response = await http.post(
          Uri.parse("$serviceUrl/start?runner=$runnerType"),
          headers: {"Content-Type": "text/plain; charset=utf-8"},
          body: msg,
        );

        if (response.statusCode == 200) {
          _startPolling();
          await _taskCompleter?.future;
          if (hasContent) {
            Get.back();
          }
        } else {
          logs.add("Start failed: ${response.statusCode}");
          status.value = ExpandStatus.finish;
        }
      } catch (e) {
        logs.add("Network error: $e");
        status.value = ExpandStatus.finish;
      }
    }, I18nKey.labelExecuting.tr);
  }

  void reset() {
    _timer?.cancel();
    status.value = ExpandStatus.init;
    isInit.value = true;
    disabled.value = false;
    final qaType = toQaType(targetIndex.value);
    if (qaType == QaType.note || qaType == QaType.tip) {
      disabledAudioWidget.value = true;
    } else {
      disabledAudioWidget.value = false;
    }
    disabled.value = false;
    logs.clear();
  }

  void _startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      try {
        final response = await http.get(Uri.parse("$serviceUrl/status"));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          List<dynamic> serverLogs = data['log'] ?? [];
          logs.assignAll(serverLogs.map((e) => e.toString()).toList());

          if (!data['running']) {
            timer.cancel();
            Map<String, dynamic> result = data['result'] ?? {};
            String audioUrl = result['file'] ?? "";

            if (enableAudio.value && audioUrl.isNotEmpty) {
              logs.add("Downloading audio file...");
              String downloadUrl = "$serviceUrl/download?path=$audioUrl";
              String savePath = "audio/$audioUrl";

              DownloadDoc.start(
                downloadUrl,
                savePath,
                progressCallback: (startTime, count, total, finish) {
                  if (finish) logs.add("Audio download complete");
                },
              ).then((downloadResult) async {
                if (downloadResult == DownloadDocResult.success) {
                  var rootPath = await DocPath.getContentPath();
                  String fullPath = rootPath.joinPath(savePath);
                  final dc = await DocHelp.moveToDocDir(fullPath, bookId);
                  await _onTaskComplete(result, dc: dc);
                } else {
                  logs.add("Audio download failed: $downloadResult");
                  await _onTaskComplete(result);
                }
                status.value = ExpandStatus.finish;
                _taskCompleter?.complete();
              });
            } else {
              await _onTaskComplete(result);
              status.value = ExpandStatus.finish;
              _taskCompleter?.complete();
            }
          }
        }
      } catch (e) {
        logs.add("Polling exception: $e");
        timer.cancel();
        status.value = ExpandStatus.finish;
        if (_taskCompleter?.isCompleted == false) _taskCompleter?.complete();
      }
    });
  }

  Future<void> _onTaskComplete(Map<String, dynamic> result, {DownloadContent? dc}) async {
    String text = result['text'] ?? "";
    if (text.isEmpty) {
      hasContent = false;
      return;
    } else {
      hasContent = true;
    }
    String key = toQaType(targetIndex.value).acronym;
    if (key.isNotEmpty && text.isNotEmpty) {
      String current = verseMap[key] ?? "";
      verseMap[key] = current.isEmpty ? text : "$current\n$text";
      logs.add("Content appended to: ${targetOptions[targetIndex.value]}");
    }

    if (enableAudio.value && dc != null) {
      verseMap['s'] = RepeatViewEnum.audio.name;
      verseMap['d'] = [dc];

      try {
        var rootPath = await DocPath.getContentPath();
        String fullPath = rootPath.joinPath(DocPath.getRelativePath(bookId).joinPath(dc.folder).joinPath(dc.name));

        final player = AudioPlayer();
        final duration = await player.setFilePath(fullPath);
        await player.dispose();

        int ms = duration?.inMilliseconds ?? 0;

        verseMap['${key}Start'] = "00:00:00,000";
        verseMap['${key}End'] = Time.convertMsToString(ms);
        logs.add("Audio saved. Duration: ${Time.convertMsToString(ms)}");
      } catch (e) {
        verseMap['${key}Start'] = "00:00:00,000";
        verseMap['${key}End'] = "00:00:05,000";
        logs.add("Failed to read duration, using default: $e");
      }
    } else {
      verseMap['s'] = RepeatViewEnum.text.name;
    }
    String jsonStr = jsonEncode(verseMap);
    await Db().db.verseDao.updateVerseContent(verseId, jsonStr);
  }
}
