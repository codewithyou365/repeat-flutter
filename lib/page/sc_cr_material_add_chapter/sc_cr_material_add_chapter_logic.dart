import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/db/entity/book.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/chapter_import_help.dart';
import 'package:repeat_flutter/nav.dart';
import 'package:repeat_flutter/widget/overlay/overlay.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

import 'sc_cr_material_add_chapter_state.dart';

class ScCrMaterialAddChapterLogic extends GetxController {
  final ScCrMaterialAddChapterState state = ScCrMaterialAddChapterState();

  @override
  void onInit() {
    super.onInit();
    state.book = Get.arguments[0] as Book;
  }

  @override
  void onClose() {
    state.mediaController.dispose();
    state.srtController.dispose();
    super.onClose();
  }

  Future<void> pickMedia() => _pick(state.mediaController, state.mediaSource, ['mp3', 'mp4']);

  Future<void> pickSrt() => _pick(state.srtController, state.srtSource, ['srt']);

  Future<void> _pick(TextEditingController controller, RxString source, List<String> extensions) async {
    var result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: extensions,
    );
    var path = result?.files.single.path;
    if (path == null) {
      Snackbar.show(I18nKey.labelLocalImportCancel.tr);
      return;
    }
    _set(controller, source, path);
  }

  Future<void> scanMedia() => _scan(state.mediaController, state.mediaSource);

  Future<void> scanSrt() => _scan(state.srtController, state.srtSource);

  Future<void> _scan(TextEditingController controller, RxString source) async {
    // No type argument here: the scan GetPage is untyped, so Get would fail to
    // cast GetPageRoute<dynamic> to Route<String?>.
    var value = await Nav.scan.push();
    if (value is! String || value.isEmpty) {
      return;
    }
    _set(controller, source, value);
  }

  void _set(TextEditingController controller, RxString source, String value) {
    controller.text = value;
    source.value = value;
  }

  void downloadProgress(int startTime, int count, int total, bool finish) {
    if (finish) {
      state.indexCount.value++;
      state.contentProgress.value = 1;
    } else {
      if (total == -1) {
        int elapse = DateTime.now().millisecondsSinceEpoch - startTime;
        int predict = 5 * 60 * 1000;
        double progress = elapse / predict;
        if (progress > 0.9) {
          state.contentProgress.value = 0.9;
        } else {
          state.contentProgress.value = progress;
        }
      } else {
        state.contentProgress.value = count / total;
      }
    }
  }

  void submit() async {
    var mediaSource = state.mediaSource.value.trim();
    var srtSource = state.srtSource.value.trim();
    if (mediaSource.isEmpty || srtSource.isEmpty) {
      Snackbar.show(I18nKey.labelInputPathError.tr);
      return;
    }
    state.importing.value = true;
    // The srt and the media are the two downloadable items.
    state.indexCount.value = 0;
    state.indexTotal.value = 2;
    state.contentProgress.value = 0;
    bool success = await showOverlay<bool>(() async {
      return await ChapterImportHelp.import(
        bookId: state.book.id!,
        mediaSource: mediaSource,
        srtSource: srtSource,
        progressCallback: downloadProgress,
      );
    }, I18nKey.labelImporting.tr);
    state.importing.value = false;
    if (success) {
      Nav.back();
      Snackbar.show(I18nKey.labelAddSuccess.tr);
    }
    // On failure the page stays, so the user can fix the input and retry.
  }
}
