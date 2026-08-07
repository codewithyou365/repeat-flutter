import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:mustache_template/mustache_template.dart';
import 'package:repeat_flutter/common/path.dart';
import 'package:repeat_flutter/common/time.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/assistive_touch_action.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
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

/// 执行方式：
/// - overwrite: 每次都请求助手服务，把结果覆盖到作用位置。
/// - playOrOverwrite: 覆盖写入时会把当次的指令一起存到作用位置末尾（见
///   [VerseField.embedInstruction]）；下次执行时，存的指令跟这次要发的指令一样才直接播放
///   已有内容（音视频优先，否则 TTS），不一样（含没存过指令，比如老数据/手填内容）就退回
///   overwrite 的流程重新生成。
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
  /// 作用位置里"第 1 条提示"从这个下标开始（3=提示1、4=提示2……）。
  /// 下标会存进 AssistiveTouchAction 的 targetIndex，只能往后加，不能调顺序。
  static const int tipStart = 3;

  /// 作用位置选项框的顺序：问题、答案、提示1..提示8，一共 10 项。
  /// 里面装的是存库的下标，不是选项框自己的位置——两者不是一回事，必须过这层映射。
  static const List<int> selectableTargetIndexes = [2, 0, 3, 4, 5, 6, 7, 8, 9, 10];

  /// 作用位置的全部选项，下标就是存库的值。
  /// 下标 1 是老的"提示"（跟着界面上选中的那条走），已经不给选了，但位置要留着——
  /// 老预设里存的就是 1，挪走会让它们指到别的字段上。读到 1 一律当第 1 条提示。
  List<String> get targetOptions => [
        QaType.answer.i18n.tr,
        tipLabel(0),
        QaType.question.i18n.tr,
        for (var i = 0; i < VerseField.maxTip; i++) tipLabel(i),
      ];

  /// 老预设存的"提示"（作用位置是 1）归到"提示1"，这样选项框里能选中它。
  static int normalizeTargetIndex(int index) => index == 1 ? tipStart : index;

  /// 第 i 条提示显示的名字：book 里定义了就用定义的（跟提示 tab 栏一致），没定义用序号。
  String tipLabel(int index) {
    return VerseField.tipNameOf(_bookMap(), index) ?? '${QaType.tip.i18n.tr}${index + 1}';
  }

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

  String _tipFieldRef(int index) {
    final tipIndex = (index - tipStart).clamp(0, VerseField.maxTip - 1);
    return VerseField.ref(QaType.tip.acronym, tipIndex);
  }

  /// 指令模版里可以写 {{input1}}..{{input10}}，最多 10 个参数。
  static const int maxInput = 10;

  /// 编号为 [number] 的参数在模版里的占位符名字（1 基，跟界面上显示的编号一致）。
  static String inputKeyOf(int number) => 'input$number';

  /// 本节字段在模版里的占位符名字。
  static const String questionKey = 'question';
  static const String answerKey = 'answer';

  /// 第 i 条提示的占位符名字（1 基）。
  static String tipKey(int index) => 'tip${index + 1}';

  /// 模版里 {{question}}/{{answer}}/{{tip1}}.. 的取值，都从当前小节取，没有的给空串。
  Map<String, String> verseValues() => {
        questionKey: VerseField.getText(verseMap, QaType.question.acronym) ?? '',
        answerKey: VerseField.getText(verseMap, QaType.answer.acronym) ?? '',
        for (var i = 0; i < VerseField.maxTip; i++) tipKey(i): VerseField.getText(verseMap, VerseField.ref(QaType.tip.acronym, i)) ?? '',
      };

  static final RegExp _inputPlaceholder = RegExp(r'\{\{\s*input(\d+)\s*\}\}');

  /// 这个模版实际用到的参数编号（1 基，去重升序）。不再单独存库，每次从模版里扫。
  /// 只认写出来的那几个：模版里只有 {{input1}} 和 {{input6}} 就返回 [1, 6]，
  /// 弹框也只有这两个，中间没用到的编号不凑数。
  static List<int> inputNumbersOf(String template) {
    final numbers = <int>{};
    for (final m in _inputPlaceholder.allMatches(template)) {
      final n = int.tryParse(m.group(1) ?? '') ?? 0;
      if (n >= 1 && n <= maxInput) {
        numbers.add(n);
      }
    }
    return numbers.toList()..sort();
  }

  /// 渲染指令：模版原文 + 当前小节的字段值 + 这次填的参数。
  /// 模版写坏了（mustache 解析不了）就原样返回，跟 TextTemplate 的容错一致。
  String render(String template, {Map<String, String>? inputs}) {
    try {
      return Template(template, htmlEscapeValues: false).renderString({
        ...verseValues(),
        ...?inputs,
      });
    } catch (_) {
      return template;
    }
  }

  /// 用户依次填好的参数值 -> 渲染模版用的 map。
  /// [numbers] 是 [inputNumbersOf] 给出的编号表，[values] 按它的顺序一一对应；
  /// 少了的补空串、多了的丢掉（游戏脚本可以只传前几个）。
  static Map<String, String> inputsOf(List<int> numbers, List<String>? values) => {
        for (var i = 0; i < numbers.length; i++) inputKeyOf(numbers[i]): (values != null && i < values.length) ? values[i] : '',
      };

  /// 动作名称：直接在表单里改，不再另外弹框问。
  var actionName = ''.obs;

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

  Future<void> saveAsAction() async {
    final action = AssistiveTouchAction(
      id: editingActionId,
      classroomId: Classroom.curr,
      name: actionName.value.trim(),
      template: textController.text,
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
      final existingInstruction = VerseField.getInstruction(verseMap, target);
      if (existingInstruction != null && existingInstruction == msg) {
        await onPlayTarget?.call(target);
        return;
      }
    }
    await startTask(msg, closeOnSuccess: closeOnSuccess);
  }

  /// 助手服务 /start 的请求体：params 原样进脚本的 ctx.params，
  /// packId/taskId 不传就跑默认包的 main。
  Map<String, dynamic> _startBody(String msg) => {
        "params": {
          "input": msg,
          "withSpeak": enableAudio.value,
        },
      };

  /// 把这次要发的请求拼成一条 curl，方便拿去单独对助手服务测（跟 [startTask] 发的是同一个请求）。
  /// body 用单引号包起来，里面的单引号按 shell 的老办法拆成 '\'' 。
  String toCurl(String msg) {
    final body = jsonEncode(_startBody(msg)).replaceAll("'", "'\\''");
    return "curl -X POST '${serviceUrl.value}/start' \\\n"
        "  -H 'Content-Type: application/json; charset=utf-8' \\\n"
        "  --data-raw '$body'";
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

        final response = await http.post(
          Uri.parse("$serviceUrl/start"),
          headers: {"Content-Type": "application/json; charset=utf-8"},
          body: utf8.encode(jsonEncode(_startBody(msg))),
        );

        if (response.statusCode == 200) {
          _startPolling(msg);
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

  void _startPolling(String msg) {
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
                  await _onTaskComplete(result, msg, dc: dc);
                } else {
                  logs.add("Audio download failed: $downloadResult");
                  await _onTaskComplete(result, msg);
                }
                status.value = ExpandStatus.finish;
                _taskCompleter?.complete();
              });
            } else {
              await _onTaskComplete(result, msg);
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

  /// 扩展助手只拿得到 verse 那一层，book 的内容由 [ExpandSheet.open] 打开时查一次
  /// 塞进来（提示的名字定义在 book 上）。[tipLabel] 是同步的，这里不能临时查库。
  Map<String, dynamic>? bookMap;

  Map<String, dynamic>? _bookMap() => bookMap;

  Future<void> loadBookMap() async {
    bookMap = null;
    var content = await Db().db.bookDao.getContentById(bookId);
    if (content == null) {
      return;
    }
    try {
      final ret = jsonDecode(content);
      bookMap = ret is Map<String, dynamic> ? ret : null;
    } catch (_) {
      bookMap = null;
    }
  }

  Future<void> _onTaskComplete(Map<String, dynamic> result, String instruction, {DownloadContent? dc}) async {
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
      VerseField.setText(targetMap, key, VerseField.embedInstruction(text, instruction));
      logs.add("Content overwritten to: ${targetOptions[targetIndex.value]}");
    }

    if (enableAudio.value && dc != null) {
      // 生成的音频只挂到这个字段块上（'a' 里的 'mediaHash' + 'showType'），不动整节的 's'：
      // 否则一节里问题是章节视频、答案是新音频时，会把视频整个遮蔽掉，'s' 也会把 q 一起改了。
      // 文件对象登记到这一节自己的 'd' 里（见 VerseField.setMedia），字段块只存 hash。
      VerseField.setMedia(verse: targetMap, acronym: key, d: dc);
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
