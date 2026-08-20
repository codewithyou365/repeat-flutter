import 'package:get/get.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/kv.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/ai/ai_catalog.dart';
import 'package:repeat_flutter/logic/ai/ai_model_help.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

import 'sc_settings_ai_state.dart';

class ScSettingsAiLogic extends GetxController {
  final ScSettingsAiState state = ScSettingsAiState();

  @override
  void onInit() {
    super.onInit();
    // 上次装到一半被杀掉的残留没有任何用，进页面先清一次暂存。
    AiModelHelp.cleanTemp();
    reload();
  }

  Future<void> reload({bool refreshCatalog = false}) async {
    state.loading.value = true;
    try {
      state.catalog = await AiCatalog.load(refresh: refreshCatalog);
      state.catalogUrl.value = (await Db().db.kvDao.getStr(K.aiCatalogUrl)) ?? '';
      for (final m in state.catalog.models) {
        state.installed[m.id] = await AiModelHelp.isInstalled(m.id);
      }
      for (final role in AiRole.values) {
        state.selected[role] = (await AiModelHelp.selectedFor(role, state.catalog))?.id ?? '';
      }
      state.diskUsage.value = await AiModelHelp.totalSizeOnDisk();
    } finally {
      state.loading.value = false;
    }
  }

  bool get busy => state.installingId.value.isNotEmpty;

  Future<bool> install(AiModelEntry entry) async {
    if (busy) {
      return false;
    }
    state.cancelRequested = false;
    state.installingId.value = entry.id;
    state.fileIndex.value = 0;
    state.fileTotal.value = entry.downloadUnits.length;
    state.fileProgress.value = 0;
    try {
      final result = await AiModelHelp.install(
        entry,
        onProgress: (fileIndex, fileTotal, count, total) {
          state.fileIndex.value = fileIndex;
          state.fileTotal.value = fileTotal;
          // total 为 -1 表示服务端没给 Content-Length，这时候进度条没法算，保持不动
          state.fileProgress.value = total > 0 ? count / total : state.fileProgress.value;
        },
        isCancelled: () => state.cancelRequested,
      );
      state.installed[entry.id] = result == AiInstallResult.success;
      state.diskUsage.value = await AiModelHelp.totalSizeOnDisk();
      if (result == AiInstallResult.success) {
        // 装好后如果它担的角色还没有选中项，自动选上——省掉一次"装完还得再点一下"。
        for (final role in entry.roles) {
          if ((state.selected[role] ?? '').isEmpty) {
            await AiModelHelp.select(role, entry.id);
            state.selected[role] = entry.id;
          }
        }
        Snackbar.show(I18nKey.aiInstallSuccess.trArgs([entry.name]));
        return true;
      }
      if (result == AiInstallResult.fail) {
        Snackbar.show(I18nKey.aiInstallFail.trArgs([entry.name]));
      }
      return false;
    } finally {
      state.installingId.value = '';
      state.presetName.value = '';
    }
  }

  /// 装一整套预设。已经装好的会被 [AiModelHelp.install] 的续传逻辑直接跳过。
  Future<void> installPreset(AiPreset preset) async {
    if (busy) {
      return;
    }
    final entries = preset.modelIds.map((id) => state.catalog.byId(id)).nonNulls.toList();
    state.presetName.value = preset.name;
    state.presetTotal.value = entries.length;
    for (var i = 0; i < entries.length; i++) {
      state.presetIndex.value = i + 1;
      final ok = await install(entries[i]);
      if (!ok || state.cancelRequested) {
        // 一个装不上就停：接着装后面的只会让用户以为整套都好了。
        break;
      }
    }
    state.presetName.value = '';
    state.presetIndex.value = 0;
    state.presetTotal.value = 0;
  }

  void cancel() {
    state.cancelRequested = true;
  }

  Future<void> use(AiRole role, AiModelEntry entry) async {
    await AiModelHelp.select(role, entry.id);
    state.selected[role] = entry.id;
  }

  void remove(AiModelEntry entry) {
    if (busy) {
      return;
    }
    MsgBox.yesOrNo(
      title: I18nKey.aiDeleteModel.tr,
      desc: I18nKey.aiDeleteModelConfirm.trArgs([entry.name]),
      yes: () async {
        Get.back();
        await AiModelHelp.remove(entry.id);
        await reload();
      },
      no: () => Get.back(),
    );
  }

  void editCatalogUrl() {
    final model = state.catalogUrl.value.obs;
    MsgBox.strInputWithYesOrNo(
      model,
      I18nKey.aiCatalogUrl.tr,
      I18nKey.aiCatalogUrlDesc.tr,
      yes: () async {
        Get.back();
        final url = model.value.trim();
        await Db().db.kvDao.insertOrReplace(Kv(K.aiCatalogUrl, url));
        state.catalogUrl.value = url;
        await reload(refreshCatalog: true);
      },
      no: () => Get.back(),
    );
  }
}
