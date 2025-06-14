import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/db/dao/chapter_key_dao.dart';
import 'package:repeat_flutter/db/dao/schedule_dao.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/widget/row/row_widget.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';
import 'package:video_player/video_player.dart';
import 'dart:convert';
import 'constant.dart';
import 'helper.dart';

class VideoBoard {
  final double x;
  final double y;
  final double w;
  final double h;

  const VideoBoard({
    this.x = 0.0,
    this.y = 0.8,
    this.w = 1.0,
    this.h = 0.2,
  });

  factory VideoBoard.fromJson(Map<String, dynamic> json) {
    return VideoBoard(
      x: (json['x'] as num? ?? 0.0).toDouble(),
      y: (json['y'] as num? ?? 0.8).toDouble(),
      w: (json['w'] as num? ?? 1.0).toDouble(),
      h: (json['h'] as num? ?? 0.2).toDouble(),
    );
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'w': w,
      'h': h,
    };
  }

  // 复制并修改属性
  VideoBoard copyWith({
    double? x,
    double? y,
    double? w,
    double? h,
  }) {
    return VideoBoard(
      x: x ?? this.x,
      y: y ?? this.y,
      w: w ?? this.w,
      h: h ?? this.h,
    );
  }
}

class VideoBoardHelper {
  Map<int, List<VideoBoard>> chapterVideoBoardCache = {};
  Map<int, List<VideoBoard>> verseVideoBoardCache = {};
  final Helper helper;
  static const String jsonName = "videoBoard";

  VideoBoardHelper({
    required this.helper,
  }) {
    boards.value = getCurrVideoBoard();
    ScheduleDao.setVerseShowContent.add((int id) {
      verseVideoBoardCache.remove(id);
    });
    ChapterKeyDao.setChapterShowContent.add((int id) {
      chapterVideoBoardCache.remove(id);
    });
  }

  List<VideoBoard>? getCurrChapterVideoBoard() {
    if (helper.logic.currVerse == null) {
      return null;
    }

    final chapterKeyId = helper.logic.currVerse!.chapterKeyId;
    List<VideoBoard>? ret = chapterVideoBoardCache[chapterKeyId];
    if (ret != null) {
      return ret;
    }

    final chapterMap = helper.getCurrChapterMap();
    if (chapterMap == null) {
      return null;
    }

    final List<dynamic>? list = chapterMap[jsonName] as List<dynamic>?;
    if (list != null) {
      ret = list.map((e) => VideoBoard.fromJson(Map<String, dynamic>.from(e))).toList();
    } else {
      ret = [];
    }

    chapterVideoBoardCache[chapterKeyId] = ret;
    return ret;
  }

  List<VideoBoard>? getCurrVerseVideoBoard() {
    if (helper.logic.currVerse == null) {
      return null;
    }

    final verseKeyId = helper.logic.currVerse!.verseKeyId;
    List<VideoBoard>? ret = verseVideoBoardCache[verseKeyId];
    if (ret != null) {
      return ret;
    }

    final verseMap = helper.getCurrVerseMap();
    if (verseMap == null) {
      return null;
    }

    final List<dynamic>? list = verseMap[jsonName] as List<dynamic>?;
    if (list != null) {
      ret = list.map((e) => VideoBoard.fromJson(Map<String, dynamic>.from(e))).toList();
    } else {
      ret = [];
    }

    verseVideoBoardCache[verseKeyId] = ret;
    return ret;
  }

  List<VideoBoard> getCurrVideoBoard() {
    List<VideoBoard> configs = [];
    List<VideoBoard>? verseList = getCurrVerseVideoBoard();
    if (verseList != null && verseList.isNotEmpty) {
      configs = verseList;
    } else {
      List<VideoBoard>? chapterList = getCurrChapterVideoBoard();
      if (chapterList != null && chapterList.isNotEmpty) {
        configs = chapterList;
      }
    }
    return configs;
  }

  Widget wrapVideo({
    required double width,
    required double height,
    required VideoPlayer video,
    required VoidCallback onPressed,
  }) {
    List<VideoBoard> configs = boards.value;
    if (!openedVideoBoardSettings.value && helper.step != RepeatStep.recall) {
      configs = [];
    }
    bool showSettings = false;
    if (helper.edit && !openedVideoBoardSettings.value) {
      showSettings = true;
    }

    if (configs.isEmpty && !showSettings) {
      return SizedBox(width: width, height: height, child: video);
    }

    List<Positioned> positionedBoards = configs.map((config) {
      return getBoard(configs.indexOf(config), width, height, config);
    }).toList();
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          video,
          ...positionedBoards,
          if (showSettings)
            Positioned(
              top: 10,
              right: 10,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.filter_none, size: 18),
                label: Text(I18nKey.labelVideoBoardSetting.tr, style: const TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.5),
                  foregroundColor: Colors.white,
                ),
                onPressed: onPressed,
              ),
            ),
        ],
      ),
    );
  }

  Positioned getBoard(int index, double width, double height, VideoBoard config) {
    return Positioned(
      left: config.x * width,
      top: config.y * height,
      width: config.w * width,
      height: config.h * height,
      child: Container(
        color: Colors.black,
        child: openedVideoBoardSettings.value
            ? Text("$index",
                style: const TextStyle(
                  color: Colors.white,
                ))
            : null,
      ),
    );
  }

  bool get showEdit {
    return openedVideoBoardSettings.value && helper.edit;
  }

  Rx<List<VideoBoard>> boards = Rx([]);
  var openedVideoBoardSettings = false.obs;

  final saveToVerse = false.obs;
  final selectedBoardIndex = 0.obs;
  final selectedProperty = "x".obs;
  final properties = ["x", "y", "w", "h"];

  Widget editPanel() {
    var configs = boards.value;
    if (selectedBoardIndex.value >= configs.length && configs.isNotEmpty) {
      selectedBoardIndex.value = 0;
    }
    return ListView(
      padding: const EdgeInsets.all(0),
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                openedVideoBoardSettings.value = false;
              },
            ),
            const SizedBox(height: 32),
            Expanded(
              child: configs.isEmpty
                  ? Text(I18nKey.labelNoVideoBoard.tr)
                  : Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: DropdownButton<int>(
                        value: selectedBoardIndex.value < configs.length ? selectedBoardIndex.value : 0,
                        isExpanded: true,
                        underline: const SizedBox(),
                        icon: const Icon(Icons.arrow_drop_down),
                        items: List.generate(configs.length, (index) {
                          return DropdownMenuItem<int>(
                            value: index,
                            child: Text(I18nKey.labelVideoBoard.trArgs([index.toString()])),
                          );
                        }),
                        onChanged: (int? value) {
                          if (value != null) {
                            selectedBoardIndex.value = value;
                          }
                        },
                      ),
                    ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: configs.isEmpty
                  ? null
                  : () {
                      if (configs.isNotEmpty) {
                        configs.removeAt(selectedBoardIndex.value);
                        if (selectedBoardIndex.value >= configs.length && configs.isNotEmpty) {
                          selectedBoardIndex.value = configs.length - 1;
                        }
                        boards.value = List.from(configs);
                      }
                    },
              tooltip: I18nKey.labelDeleteVideoBoard.tr,
            ),
            IconButton(
              icon: const Icon(Icons.add_circle, color: Colors.green),
              onPressed: () {
                configs.add(const VideoBoard());
                boards.value = List.from(configs);
                selectedBoardIndex.value = configs.length - 1;
              },
              tooltip: I18nKey.labelAddVideoBoard.tr,
            ),
          ],
        ),
        RowWidget.buildDivider(),
        configs.isEmpty
            ? const SizedBox.shrink()
            : Column(
                children: [
                  const SizedBox(height: 24),
                  DropdownButton<String>(
                    value: selectedProperty.value,
                    isExpanded: true,
                    underline: const SizedBox(),
                    icon: const Icon(Icons.arrow_drop_down),
                    items: properties.map((String property) {
                      String label = _getPropertyExplanation(property);
                      return DropdownMenuItem<String>(
                        value: property,
                        child: Text(label),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      if (value != null) {
                        selectedProperty.value = value;
                      }
                    },
                  ),
                  configs.isEmpty || selectedBoardIndex.value >= configs.length
                      ? const SizedBox.shrink()
                      : _buildLabeledSlider(
                          value: _getBoardPropertyValue(configs[selectedBoardIndex.value], selectedProperty.value),
                          onChanged: (double value) {
                            _updateBoardProperty(configs, selectedBoardIndex.value, selectedProperty.value, value);
                            boards.value = List.from(configs);
                          },
                        ),
                ],
              ),
        const SizedBox(height: 24),
        Row(
          children: [
            Text(I18nKey.labelSaveAt.tr),
            Radio<bool>(
              value: false,
              groupValue: saveToVerse.value,
              onChanged: (val) {
                if (val != null) saveToVerse.value = val;
              },
            ),
            Text(I18nKey.labelChapterName.tr),
            Radio<bool>(
              value: true,
              groupValue: saveToVerse.value,
              onChanged: (val) {
                if (val != null) saveToVerse.value = val;
              },
            ),
            Text(I18nKey.labelVerseName.tr),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: Text(I18nKey.btnSave.tr),
                onPressed: () {
                  _saveBoards();
                  openedVideoBoardSettings.value = false;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getPropertyExplanation(String property) {
    switch (property) {
      case "x":
        return I18nKey.labelXPosition.tr;
      case "y":
        return I18nKey.labelYPosition.tr;
      case "w":
        return I18nKey.labelWidth.tr;
      case "h":
        return I18nKey.labelHeight.tr;
      default:
        return property;
    }
  }

  double _getBoardPropertyValue(VideoBoard board, String property) {
    switch (property) {
      case "x":
        return board.x;
      case "y":
        return board.y;
      case "w":
        return board.w;
      case "h":
        return board.h;
      default:
        return 0.0;
    }
  }

  void _updateBoardProperty(List<VideoBoard> boards, int index, String property, double value) {
    if (index < boards.length) {
      VideoBoard board = boards[index];
      VideoBoard newBoard;

      switch (property) {
        case "x":
          newBoard = board.copyWith(x: value);
          break;
        case "y":
          newBoard = board.copyWith(y: value);
          break;
        case "w":
          newBoard = board.copyWith(w: value);
          break;
        case "h":
          newBoard = board.copyWith(h: value);
          break;
        default:
          return;
      }

      boards[index] = newBoard;
    }
  }

  Future<void> _saveBoards() async {
    final helper = this.helper;
    if (helper.logic.currVerse == null) return;

    try {
      final List<Map<String, dynamic>> jsonList = boards.value.map((e) => e.toJson()).toList();

      if (saveToVerse.value) {
        final verseKeyId = helper.logic.currVerse!.verseKeyId;
        final verseMap = helper.getCurrVerseMap() ?? {};
        verseMap[jsonName] = jsonList;
        final jsonStr = jsonEncode(verseMap);
        await Db().db.scheduleDao.tUpdateVerseContent(verseKeyId, jsonStr);
        verseVideoBoardCache[verseKeyId] = boards.value;
      } else {
        final chapterKeyId = helper.logic.currVerse!.chapterKeyId;
        final chapterMap = helper.getCurrChapterMap() ?? {};
        chapterMap[jsonName] = jsonList;
        final jsonStr = jsonEncode(chapterMap);
        await Db().db.chapterKeyDao.updateChapterContent(chapterKeyId, jsonStr);

        final verseKeyId = helper.logic.currVerse!.verseKeyId;
        final verseMap = helper.getCurrVerseMap() ?? {};
        verseMap.remove(jsonName);
        final verseJsonStr = jsonEncode(verseMap);
        await Db().db.scheduleDao.tUpdateVerseContent(verseKeyId, verseJsonStr);
        verseVideoBoardCache[verseKeyId] = boards.value;
        chapterVideoBoardCache[chapterKeyId] = boards.value;
      }
      Snackbar.show(I18nKey.labelSaved.tr);
    } catch (e) {
      debugPrint("保存视频挡板设置失败: $e");
    }
  }

  Widget _buildLabeledSlider({
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Slider(
      padding: const EdgeInsets.all(0),
      value: value,
      min: 0.0,
      max: 1.0,
      divisions: 100,
      activeColor: Colors.blue,
      inactiveColor: Colors.grey,
      onChanged: onChanged,
    );
  }
}
