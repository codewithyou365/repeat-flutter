import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mustache_template/mustache_template.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/kv.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/model/book_content.dart';
import 'package:repeat_flutter/page/repeat/logic/constant.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';
import 'package:repeat_flutter/widget/overlay/overlay.dart';

enum ExpandStatus {
  init,
  pending,
  finish,
}

/// 执行方式：
/// - overwrite: 每次都请求助手服务，把结果覆盖到作用位置。
/// - playOrOverwrite: 覆盖写入时会把当次的指令一起存到作用位置末尾（见
///   [VerseField.setInstruction]）；下次执行时，存的指令跟这次要发的指令一样才直接播放
///   已有内容（音视频优先，否则 TTS），不一样（含没存过指令，比如老数据/手填内容）就退回
///   overwrite 的流程重新生成。
/// - noSave: 照常请求，但结果是临时的：不写回作用位置，只用对话框把
///   结果显示出来（见 [ExpandLogic.showTempResult]）。
///
/// 存库的是下标（AtNetParams.behavior），只能往后加，不能调顺序。
enum ExpandBehavior {
  overwrite,
  playOrOverwrite,
  noSave,
}

class ExpandLogic {
  var serviceUrl = "http://127.0.0.1:8080".obs;
  final TextEditingController textController = TextEditingController();

  var hasContent = false;
  var status = ExpandStatus.init.obs;
  var isInit = true.obs;
  var disabled = false.obs;
  var logs = <String>[].obs;

  /// 第 i 条提示显示的名字：课堂里定义了就用定义的（跟提示 tab 栏一致），没定义用序号。
  String tipLabel(int index) {
    return VerseField.tipNameOf(classroomMap, index) ?? '${QaType.tip.i18n.tr}${index + 1}';
  }

  /// 指令模版里可以写 {{input1}}..{{input10}}，最多 10 个参数。
  static const int maxInput = 10;

  /// 编号为 [number] 的参数在模版里的占位符名字（1 基，跟界面上显示的编号一致）。
  static String inputKeyOf(int number) => 'input$number';

  /// 本节字段在模版里的占位符名字。
  static const String questionKey = 'question';
  static const String answerKey = 'answer';
  static const String noteKey = 'note';

  /// "界面上当前选中的那条提示"的占位符名字。它跟小节内容无关（取决于现在开着哪个 tab），
  /// 所以不在 [verseValues] 里，由调用方按当前界面算好塞进 render 的 inputs（见朗读动作）。
  static const String currentKey = 'current';

  /// 第 i 条提示的占位符名字（1 基）。
  static String tipKey(int index) => 'tip${index + 1}';

  /// 模版里 {{question}}/{{answer}}/{{tip1}}.. 的取值，都从当前小节取，没有的给空串。
  Map<String, String> verseValues() => {
        questionKey: VerseField.getText(verseMap, QaType.question.acronym) ?? '',
        answerKey: VerseField.getText(verseMap, QaType.answer.acronym) ?? '',
        noteKey: VerseField.getText(verseMap, QaType.note.acronym) ?? '',
        currentKey: '',
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

  /// 作用位置的字段引用串（'q'/'a'/'t'/'t1'..），由动作里存的那份直接给过来。
  var targetRef = QaType.question.acronym.obs;
  var behavior = ExpandBehavior.overwrite.obs;
  var behaviorOptions = [
    I18nKey.behaviorOverwrite.tr,
    I18nKey.behaviorPlayOrOverwrite.tr,
    I18nKey.behaviorNoSave.tr,
  ];

  bool get _noSave => behavior.value == ExpandBehavior.noSave;

  /// noSave 时这次请求拿到的结果，[execute] 跑完后弹框显示。null 表示没拿到（请求失败等）。
  String? _tempResult;

  /// 播放作用位置已有内容的实现由持有 RepeatLogic 的一方注入（AssistiveTouchLogic.playTarget）。
  Future<void> Function(String fieldRef)? onPlayTarget;
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

  /// 统一入口：先按 behavior 判断是播放已有内容还是请求助手服务。
  Future<void> execute(String msg, {bool closeOnSuccess = true}) async {
    final target = targetRef.value;
    if (behavior.value == ExpandBehavior.playOrOverwrite) {
      final existingInstruction = VerseField.getInstruction(verseMap, target);
      if (existingInstruction != null && existingInstruction == msg) {
        await onPlayTarget?.call(target);
        return;
      }
    }
    _tempResult = null;
    await startTask(msg, closeOnSuccess: closeOnSuccess);
    final temp = _tempResult;
    if (_noSave && temp != null) {
      await showTempResult(temp);
    }
  }

  /// 把临时结果放进对话框：内容可能很长，限高滚动；可选中，方便复制。
  static Future<void> showTempResult(String text) {
    return MsgBox.myDialog(
      title: I18nKey.labelTips.tr,
      content: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: Get.height * 0.6),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: SelectableText(text),
        ),
      ),
      action: MsgBox.buttonsWithDivider(
        buttons: [
          MsgBox.button(text: I18nKey.btnOk.tr, onPressed: () => Get.back()),
        ],
      ),
    );
  }

  /// 助手服务 /start 的请求体：params 原样进脚本的 ctx.params，
  /// packId/taskId 不传就跑默认包的 main。
  Map<String, dynamic> _startBody(String msg) => {
        "params": {
          "input": msg,
          // 生成音频的功能已去掉，明确告诉服务不用合成。
          "withSpeak": false,
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

            if (_noSave) {
              // 临时结果：只把 result['text'] 记下来给 execute 弹框，不写库。
              // 跟覆盖写入一样，text 为空就当没拿到内容，不弹框。
              final text = result['text'];
              hasContent = text is String && text.isNotEmpty;
              _tempResult = hasContent ? text as String : null;
            } else {
              await _onTaskComplete(result, msg);
            }
            status.value = ExpandStatus.finish;
            _taskCompleter?.complete();
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

  /// 扩展助手只拿得到 verse 那一层，课堂的内容由 [ExpandSheet.open] 打开时查一次
  /// 塞进来（提示的名字定义在课堂上）。[tipLabel] 是同步的，这里不能临时查库。
  Map<String, dynamic>? classroomMap;

  Future<void> loadClassroomMap() async {
    classroomMap = null;
    final classroom = await Db().db.classroomDao.getById(Classroom.curr);
    final content = classroom?.content;
    if (content == null || content.isEmpty) {
      return;
    }
    try {
      final ret = jsonDecode(content);
      classroomMap = ret is Map<String, dynamic> ? ret : null;
    } catch (_) {
      classroomMap = null;
    }
  }

  Future<void> _onTaskComplete(Map<String, dynamic> result, String instruction) async {
    String text = result['text'] ?? "";
    if (text.isEmpty) {
      hasContent = false;
      return;
    } else {
      hasContent = true;
    }
    final Map<String, dynamic> targetMap = verseMap;

    String key = targetRef.value;
    if (key.isNotEmpty && text.isNotEmpty) {
      // 正文归正文、指令归指令：指令写在字段块的 'ins' 里，不再用分隔符挂在正文尾巴上。
      // 正文可能是一个内容数组（配了图/网页），往里面塞分隔符块会把结构搅乱。
      VerseField.setText(targetMap, key, text);
      VerseField.setInstruction(targetMap, key, instruction);
      logs.add("Content overwritten to: $key");
    }

    // 只出文本：该字段之前挂过生成的音频（老版本"生成音频"留下的）时，把音频和它的时间区间一起清掉，
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
    String jsonStr = jsonEncode(targetMap);
    await Db().db.verseDao.updateVerseContent(verseId, jsonStr);
  }
}
