import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:repeat_flutter/common/path.dart';
import 'package:repeat_flutter/common/time.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/assistive_touch_action.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/kv.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/base/constant.dart';
import 'package:repeat_flutter/logic/book_help.dart';
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

/// 执行方式：
/// - overwrite: 每次都请求助手服务，把结果覆盖到作用位置。
/// - playOrOverwrite: 作用位置已经有文本时不请求服务，直接播放已有内容（音视频优先，否则 TTS）；
///   作用位置为空时退回 overwrite 的流程。
enum ExpandBehavior {
  overwrite,
  playOrOverwrite,
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
  /// 作用位置/指令模版里"第 1 条提示"从这个下标开始（3=提示1、4=提示2……）。
  /// 下标会存进 AssistiveTouchAction 的 targetIndex/sourceIndex，只能往后加，不能调顺序。
  static const int tipStart = 3;

  /// 界面上两个选项框的顺序：问题、答案、提示1..提示8，一共 10 项。
  /// 里面装的是存库的下标，不是选项框自己的位置——两者不是一回事，必须过这层映射。
  static const List<int> selectableTargetIndexes = [2, 0, ..._tipIndexes];
  static const List<int> selectableSourceIndexes = [0, 1, ..._tipIndexes];
  static const List<int> _tipIndexes = [3, 4, 5, 6, 7, 8, 9, 10];

  /// 作用位置的全部选项，下标就是存库的值。
  /// 下标 1 是老的"提示"（跟着界面上选中的那条走），已经不给选了，但位置要留着——
  /// 老预设里存的就是 1，挪走会让它们指到别的字段上。读到 1 一律当第 1 条提示。
  List<String> get targetOptions => [
        QaType.answer.i18n.tr,
        tipLabel(0),
        QaType.question.i18n.tr,
        for (var i = 0; i < VerseField.maxTip; i++) tipLabel(i),
      ];

  /// 指令模版的全部选项，下标就是存库的值。下标 2 是老的"提示"，同上，留位不给选。
  List<String> get sourceOptions => [
        QaType.question.i18n.tr,
        QaType.answer.i18n.tr,
        tipLabel(0),
        for (var i = 0; i < VerseField.maxTip; i++) tipLabel(i),
      ];

  /// 老预设存的"提示"（作用位置是 1、指令模版是 2）归到"提示1"，这样选项框里能选中它。
  static int normalizeTargetIndex(int index) => index == 1 ? tipStart : index;

  static int normalizeSourceIndex(int index) => index == 2 ? tipStart : index;

  /// 第 i 条提示显示的名字：book 里定义了就用定义的（跟提示 tab 栏一致），没定义用序号。
  String tipLabel(int index) {
    return VerseField.tipNameOf(_bookMap(), index) ?? '${QaType.tip.i18n.tr}${index + 1}';
  }

  var sourceIndex = 1.obs;
  // 指令框里显示的文本来自哪个文本模版(copyLogic.copyTemplates 的下标)，
  // 保存为辅助控制预设时记录这个下标而不是渲染好的固定文本，这样以后对不同小节执行时能重新取当时的模版文本。
  var templateIndex = 0.obs;

  String toFieldRef(int targetIndex) {
    if (targetIndex == 0) {
      return QaType.answer.acronym;
    } else if (targetIndex == 1) {
      // 老预设里的"提示"，现在一律当第 1 条。
      return VerseField.ref(QaType.tip.acronym, 0);
    } else if (targetIndex == 2) {
      return QaType.question.acronym;
    }
    // 直接指定第几条提示。预设是存下标的，换到提示更少的书上也照它写，
    // 不往回退成第 1 条——不然内容会悄悄盖到别的提示上。
    return _tipFieldRef(targetIndex);
  }

  String toSourceFieldRef(int index) {
    if (index == 0) {
      return QaType.question.acronym;
    } else if (index == 1) {
      return QaType.answer.acronym;
    } else if (index == 2) {
      // 老预设里的"提示"，现在一律当第 1 条。
      return VerseField.ref(QaType.tip.acronym, 0);
    }
    return _tipFieldRef(index);
  }

  String _tipFieldRef(int index) {
    final tipIndex = (index - tipStart).clamp(0, VerseField.maxTip - 1);
    return VerseField.ref(QaType.tip.acronym, tipIndex);
  }

  String getSourceText() {
    return VerseField.getText(verseMap, toSourceFieldRef(sourceIndex.value)) ?? '';
  }

  var targetIndex = 0.obs;
  var enableAudio = true.obs;
  var behavior = ExpandBehavior.overwrite.obs;
  var behaviorOptions = [
    I18nKey.behaviorOverwrite.tr,
    I18nKey.behaviorPlayOrOverwrite.tr,
  ];

  /// 播放作用位置已有内容的实现由持有 RepeatLogic 的一方注入（AssistiveTouchLogic.playTarget）。
  Future<void> Function(String fieldRef)? onPlayTarget;
  int bookId = 0;
  int verseId = 0;
  Map<String, dynamic> verseMap = {};
  int? editingActionId;
  int actionSort = 0;
  Timer? _timer;

  Completer<void>? _taskCompleter;

  Future<void> loadSettings() async {
    serviceUrl.value = await Db().db.kvDao.getStr(K.expandServiceUrl) ?? "http://127.0.0.1:8080";
  }

  Future<void> saveServiceUrl() async {
    await Db().db.kvDao.insertOrReplace(Kv(K.expandServiceUrl, serviceUrl.value));
  }

  Future<void> saveAsAction(String name) async {
    final action = AssistiveTouchAction(
      id: editingActionId,
      classroomId: Classroom.curr,
      name: name,
      sourceIndex: sourceIndex.value,
      templateIndex: templateIndex.value,
      targetIndex: targetIndex.value,
      enableAudio: enableAudio.value,
      behavior: behavior.value.index,
      sort: actionSort,
    );
    if (editingActionId == null) {
      await Db().db.assistiveTouchActionDao.insert(action);
    } else {
      await Db().db.assistiveTouchActionDao.update(action);
    }
  }

  /// 统一入口：先按 behavior 判断是播放已有内容还是请求助手服务。
  Future<void> execute(String msg, {bool closeOnSuccess = true}) async {
    final target = toFieldRef(targetIndex.value);
    if (behavior.value == ExpandBehavior.playOrOverwrite) {
      final existing = VerseField.getText(verseMap, target);
      if (existing != null) {
        await onPlayTarget?.call(target);
        return;
      }
    }
    await startTask(msg, closeOnSuccess: closeOnSuccess);
  }

  Future<void> startTask(String msg, {bool closeOnSuccess = true}) async {
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
          if (hasContent && closeOnSuccess) {
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
    disabledAudioWidget.value = false;
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

  /// 扩展助手只拿得到 verse 那一层，book 的内容从缓存里取（用来就近登记媒体）。
  Map<String, dynamic>? _bookMap() {
    final book = BookHelp.getCache(bookId);
    if (book == null) {
      return null;
    }
    try {
      final ret = jsonDecode(book.bookContent);
      return ret is Map<String, dynamic> ? ret : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _onTaskComplete(Map<String, dynamic> result, {DownloadContent? dc}) async {
    String text = result['text'] ?? "";
    if (text.isEmpty) {
      hasContent = false;
      return;
    } else {
      hasContent = true;
    }
    final Map<String, dynamic> targetMap = verseMap;

    String key = toFieldRef(targetIndex.value);
    if (key.isNotEmpty && text.isNotEmpty) {
      VerseField.setText(targetMap, key, text);
      logs.add("Content overwritten to: ${targetOptions[targetIndex.value]}");
    }

    if (enableAudio.value && dc != null) {
      // 生成的音频只挂到这个字段块上（'a' 里的 'mediaHash' + 'showType'），不动整节的 's'：
      // 否则一节里问题是章节视频、答案是新音频时，会把视频整个遮蔽掉，'s' 也会把 q 一起改了。
      // 文件对象登记到 'd' 里（就近，见 VerseField.setMedia），字段块只存 hash。
      final bookMap = _bookMap();
      final bookChanged = VerseField.setMedia(verse: targetMap, book: bookMap, acronym: key, d: dc);
      if (bookChanged && bookMap != null) {
        await Db().db.bookDao.updateBookContent(bookId, jsonEncode(bookMap));
      }
      VerseField.setStr(targetMap, key, VerseField.showType, RepeatViewEnum.audio.name);

      try {
        var rootPath = await DocPath.getContentPath();
        String fullPath = rootPath.joinPath(DocPath.getRelativePath(bookId).joinPath(dc.folder).joinPath(dc.name));

        final player = AudioPlayer();
        final duration = await player.setFilePath(fullPath);
        await player.dispose();

        int ms = duration?.inMilliseconds ?? 0;

        VerseField.setStr(targetMap, key, VerseField.start, "00:00:00,000");
        VerseField.setStr(targetMap, key, VerseField.end, Time.convertMsToString(ms));
        logs.add("Audio saved. Duration: ${Time.convertMsToString(ms)}");
      } catch (e) {
        VerseField.setStr(targetMap, key, VerseField.start, "00:00:00,000");
        VerseField.setStr(targetMap, key, VerseField.end, "00:00:05,000");
        logs.add("Failed to read duration, using default: $e");
      }
    } else {
      // 这次只出文本：只有该字段之前挂过生成的音频时，才把音频和它的时间区间一起清掉，
      // 免得还播着跟新文本对不上的旧音频。区间本来就属于整节媒体（比如从字幕导入的）时不能动。
      // 只清这一节自己写下的 mediaHash：继承自 chapter/book 的媒体不该被一节的改动带走。
      if (VerseField.getStr(targetMap, key, VerseField.mediaHash) != null) {
        VerseField.remove(targetMap, key, [
          VerseField.mediaHash,
          VerseField.showType,
          VerseField.start,
          VerseField.end,
        ]);
      }
    }
    String jsonStr = jsonEncode(targetMap);
    await Db().db.verseDao.updateVerseContent(verseId, jsonStr);
  }
}
