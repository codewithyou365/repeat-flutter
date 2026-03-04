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
  var logs = <String>[].obs;
  var targetOptions = [
    QaType.answer.i18n.tr,
    QaType.tip.i18n.tr,
    QaType.question.i18n.tr,
  ];
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
        logs.clear();
        logs.add("正在发起请求...");

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
          logs.add("启动失败: ${response.statusCode}");
          status.value = ExpandStatus.finish;
        }
      } catch (e) {
        logs.add("网络错误: $e");
        status.value = ExpandStatus.finish;
      }
    }, I18nKey.labelExecuting.tr);
  }

  void reset() {
    _timer?.cancel();
    status.value = ExpandStatus.init;
    isInit.value = true;
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
              logs.add("正在下载音频文件...");
              String downloadUrl = "$serviceUrl/download?path=$audioUrl";
              String savePath = "audio/$audioUrl";

              DownloadDoc.start(
                downloadUrl,
                savePath,
                progressCallback: (startTime, count, total, finish) {
                  if (finish) logs.add("音频下载完成");
                },
              ).then((downloadResult) async {
                if (downloadResult == DownloadDocResult.success) {
                  var rootPath = await DocPath.getContentPath();
                  String fullPath = rootPath.joinPath(savePath);
                  final dc = await DocHelp.moveToDocDir(fullPath, bookId);
                  await _onTaskComplete(result, dc: dc);
                } else {
                  logs.add("音频下载失败: $downloadResult");
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
        logs.add("轮询异常: $e");
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
    String key = "";
    if (targetIndex.value == 0) {
      key = QaType.answer.acronym;
    } else if (targetIndex.value == 1) {
      key = QaType.tip.acronym;
    } else if (targetIndex.value == 2) {
      key = QaType.question.acronym;
    }
    if (key.isNotEmpty && text.isNotEmpty) {
      String current = verseMap[key] ?? "";
      verseMap[key] = current.isEmpty ? text : "$current\n$text";
      logs.add("已附加内容到: ${targetOptions[targetIndex.value]}");
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
        logs.add("音频模型已保存，时长: ${Time.convertMsToString(ms)}");
      } catch (e) {
        verseMap['${key}Start'] = "00:00:00,000";
        verseMap['${key}End'] = "00:00:05,000";
        logs.add("读取时长失败，已设为默认值: $e");
      }
    } else {
      verseMap['s'] = RepeatViewEnum.text.name;
    }
    String jsonStr = jsonEncode(verseMap);
    await Db().db.verseDao.updateVerseContent(verseId, jsonStr);
  }
}
