import 'package:file_picker/file_picker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/kv.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/ai/ai_catalog.dart';
import 'package:repeat_flutter/logic/ai/ai_download_source.dart';
import 'package:repeat_flutter/logic/ai/ai_model_help.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';
import 'package:repeat_flutter/widget/overlay/overlay.dart';
import 'package:repeat_flutter/widget/select/select.dart';
import 'package:repeat_flutter/widget/sheet/sheet.dart';
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
      state.downloadSource.value = await AiDownloadSourceHelp.current();
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

  /// 换下载源。国内直连 HuggingFace/GitHub 基本下不动，换镜像是最省事的一条路。
  void pickDownloadSource() async {
    final index = await Select.showSheet(
      title: I18nKey.aiDownloadSource.tr,
      keys: [
        I18nKey.aiSourceOfficial.tr,
        I18nKey.aiSourceCn.tr,
        I18nKey.aiSourceCustom.tr,
      ],
      leadings: const [
        Icon(Icons.public),
        Icon(Icons.speed),
        Icon(Icons.edit),
      ],
    );
    if (index == null) {
      return;
    }
    final source = AiDownloadSource.values[index];
    await AiDownloadSourceHelp.set(source);
    state.downloadSource.value = source;
    if (source == AiDownloadSource.custom) {
      _editCustomSource();
    }
  }

  void _editCustomSource() async {
    final hf = (await AiDownloadSourceHelp.customHfHost()).obs;
    MsgBox.strInputWithYesOrNo(
      hf,
      I18nKey.aiCustomHfHost.tr,
      AiDownloadSourceHelp.cnHfHost,
      yes: () async {
        Get.back();
        await Db().db.kvDao.insertOrReplace(Kv(K.aiCustomHfHost, hf.value.trim()));
        final gh = (await AiDownloadSourceHelp.customGhPrefix()).obs;
        MsgBox.strInputWithYesOrNo(
          gh,
          I18nKey.aiCustomGhPrefix.tr,
          AiDownloadSourceHelp.cnGhPrefix,
          yes: () async {
            Get.back();
            await Db().db.kvDao.insertOrReplace(Kv(K.aiCustomGhPrefix, gh.value.trim()));
          },
          no: () => Get.back(),
        );
      },
      no: () => Get.back(),
    );
  }

  /// 把这个模型的下载地址列出来，让用户自己去下。
  ///
  /// 地址已经按当前下载源改写过——展示的和应用自己会去下的是同一个地址，
  /// 免得用户照着官方地址下完，回头发现跟应用期望的对不上。
  void showUrls(AiModelEntry entry) async {
    final urls = await AiModelHelp.downloadUrls(entry);
    final missing = await AiModelHelp.missingFiles(entry);
    if (Get.context == null) {
      return;
    }
    Sheet.withHeaderAndBody(
      Get.context!,
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(entry.name, style: Theme.of(Get.context!).textTheme.titleMedium),
            SizedBox(height: 4.h),
            Text(I18nKey.aiImportHint.tr, style: Theme.of(Get.context!).textTheme.bodySmall),
            if (missing.isNotEmpty)
              Text(I18nKey.aiImportMissing.trArgs(['${missing.length}']),
                  style: Theme.of(Get.context!).textTheme.bodySmall),
            Row(
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.copy_all),
                  label: Text(I18nKey.aiCopyAll.tr),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: urls.join('\n')));
                    Snackbar.show(I18nKey.aiCopied.tr);
                  },
                ),
                TextButton.icon(
                  icon: const Icon(Icons.drive_folder_upload),
                  label: Text(I18nKey.aiImportLocal.tr),
                  onPressed: () {
                    Get.back();
                    importLocal(entry);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      ListView.separated(
        itemCount: urls.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, i) => ListTile(
          dense: true,
          title: Text(urls[i], style: Theme.of(context).textTheme.bodySmall),
          trailing: const Icon(Icons.copy, size: 16),
          onTap: () {
            Clipboard.setData(ClipboardData(text: urls[i]));
            Snackbar.show(I18nKey.aiCopied.tr);
          },
        ),
      ),
      rate: 0.8,
    );
  }

  /// 从本地已下好的文件导入。可以分几次导，凑齐了才算装好。
  void importLocal(AiModelEntry entry) async {
    if (busy) {
      return;
    }
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    final paths = result?.files.map((e) => e.path).whereType<String>().toList() ?? [];
    if (paths.isEmpty) {
      Snackbar.show(I18nKey.labelLocalImportCancel.tr);
      return;
    }
    state.installingId.value = entry.id;
    try {
      final r = await showOverlay(
        () => AiModelHelp.importFromPaths(entry, paths),
        I18nKey.aiImportLocal.tr,
      );
      state.installed[entry.id] = r == AiInstallResult.success;
      state.diskUsage.value = await AiModelHelp.totalSizeOnDisk();
      if (r == AiInstallResult.success) {
        for (final role in entry.roles) {
          if ((state.selected[role] ?? '').isEmpty) {
            await AiModelHelp.select(role, entry.id);
            state.selected[role] = entry.id;
          }
        }
        Snackbar.show(I18nKey.aiImportSuccess.trArgs([entry.name]));
      } else {
        // 没凑齐不是失败，是"还差几个"——把还缺多少说清楚，别让用户以为白干了
        final missing = await AiModelHelp.missingFiles(entry);
        Snackbar.show(missing.length == entry.files.length
            ? I18nKey.aiImportNothing.tr
            : I18nKey.aiImportMissing.trArgs(['${missing.length}']));
      }
    } finally {
      state.installingId.value = '';
    }
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
