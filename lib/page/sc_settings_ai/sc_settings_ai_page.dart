import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/ai/ai_catalog.dart';
import 'package:repeat_flutter/logic/ai/ai_download_source.dart';

import 'sc_settings_ai_logic.dart';
import 'sc_settings_ai_state.dart';

class ScSettingsAiPage extends StatelessWidget {
  const ScSettingsAiPage({Key? key}) : super(key: key);

  static String sourceName(AiDownloadSource s) {
    switch (s) {
      case AiDownloadSource.official:
        return I18nKey.aiSourceOfficial.tr;
      case AiDownloadSource.cn:
        return I18nKey.aiSourceCn.tr;
      case AiDownloadSource.custom:
        return I18nKey.aiSourceCustom.tr;
    }
  }

  /// 模型动辄几百 MB，统一按 MB 显示；不到 1MB 的（tokens.txt 那种）用 KB。
  static String humanSize(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024).toStringAsFixed(0)} KB';
  }

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<ScSettingsAiLogic>();
    final state = logic.state;

    return Scaffold(
      appBar: AppBar(
        title: Text(I18nKey.aiModel.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.link),
            tooltip: I18nKey.aiCatalogUrl.tr,
            onPressed: logic.editCatalogUrl,
          ),
        ],
      ),
      body: Obx(() {
        if (state.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView(
          children: [
            _buildHeader(context, logic),
            ..._buildRemote(context, logic),
            ..._buildPresets(context, logic),
            for (final role in AiRole.values) ..._buildRoleSection(context, logic, role),
            SizedBox(height: 24.h),
          ],
        );
      }),
    );
  }

  Widget _buildHeader(BuildContext context, ScSettingsAiLogic logic) {
    final state = logic.state;
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 4.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(I18nKey.aiModelDesc.tr, style: Theme.of(context).textTheme.bodySmall),
          SizedBox(height: 6.h),
          Text(I18nKey.aiDiskUsage.trArgs([humanSize(state.diskUsage.value)]),
              style: Theme.of(context).textTheme.bodySmall),
          SizedBox(height: 4.h),
          // 下载源放在最显眼的地方：国内用户第一件要做的事就是把它切成镜像，
          // 否则整套流程会卡在第一步下不动。
          InkWell(
            onTap: logic.pickDownloadSource,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 6.h),
              child: Row(
                children: [
                  const Icon(Icons.cloud_sync, size: 16),
                  SizedBox(width: 6.w),
                  Text('${I18nKey.aiDownloadSource.tr}: ${sourceName(state.downloadSource.value)}',
                      style: Theme.of(context).textTheme.bodySmall),
                  const Icon(Icons.arrow_drop_down, size: 18),
                ],
              ),
            ),
          ),
          if (state.downloadSource.value == AiDownloadSource.cn)
            Text(I18nKey.aiSourceCnDesc.tr, style: Theme.of(context).textTheme.bodySmall),
          if (state.installingId.value.isNotEmpty || state.uploadingId.value.isNotEmpty) ...[
            SizedBox(height: 10.h),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _progressText(state),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                // 上传没有取消：dio 的分片已经在路上了，半途停下留在服务端的是
                // 一个不完整的模型目录，还不如让它传完（.ok 是校验通过才写的）。
                if (state.installingId.value.isNotEmpty)
                  TextButton(onPressed: logic.cancel, child: Text(I18nKey.btnCancel.tr)),
              ],
            ),
            LinearProgressIndicator(value: state.fileProgress.value),
          ],
        ],
      ),
    );
  }

  /// 顶部那行进度文案。下载和上传共用一条进度条，只是动词不同。
  static String _progressText(ScSettingsAiState state) {
    final uploading = state.uploadingId.value.isNotEmpty;
    final body = uploading
        ? I18nKey.aiRemoteUploading.trArgs(['${state.fileIndex.value}', '${state.fileTotal.value}'])
        : I18nKey.aiInstalling.trArgs(['${state.fileIndex.value}', '${state.fileTotal.value}']);
    if (state.presetName.value.isEmpty) {
      return body;
    }
    return '${state.presetName.value} ${state.presetIndex.value}/${state.presetTotal.value} · $body';
  }

  /// 远程推理区块。放在预设之前：它是"嫌慢"这个问题最有效的解，
  /// 用户不该先翻过一屏模型列表才看到它。
  List<Widget> _buildRemote(BuildContext context, ScSettingsAiLogic logic) {
    final state = logic.state;
    final theme = Theme.of(context);
    final on = state.remoteEnabled.value;
    return [
      const Divider(height: 1),
      SwitchListTile(
        title: Text(I18nKey.aiRemote.tr),
        subtitle: Text(I18nKey.aiRemoteDesc.tr, style: theme.textTheme.bodySmall),
        value: on,
        // 上传/下载期间也允许切：这个开关只决定"下一次推理走哪条路"，
        // 跟正在传的模型没关系。灰掉反而让整块看着像是没启用。
        onChanged: (v) => logic.toggleRemote(v),
      ),
      if (on) ...[
        ListTile(
          dense: true,
          leading: const Icon(Icons.dns_outlined),
          title: Text(I18nKey.aiRemoteUrl.tr, style: theme.textTheme.bodyMedium),
          subtitle: Text(
            state.remoteUrl.value.isEmpty ? I18nKey.aiRemoteUrlHint.tr : state.remoteUrl.value,
            style: theme.textTheme.bodySmall,
          ),
          trailing: const Icon(Icons.edit, size: 18),
          onTap: logic.editRemoteUrl,
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 用 Wrap 不用 Row：英文文案（"Upload models to server"）比中文长得多，
              // 两个按钮并排放不下会直接 overflow，窄屏上让它换行。
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: [
                  OutlinedButton.icon(
                    onPressed: state.remoteTesting.value ? null : logic.testRemote,
                    icon: const Icon(Icons.network_check, size: 18),
                    label: Text(I18nKey.aiRemoteTest.tr),
                  ),
                  OutlinedButton.icon(
                    onPressed: logic.busy ? null : () => logic.uploadModels(),
                    icon: const Icon(Icons.upload, size: 18),
                    label: Text(I18nKey.aiRemoteUpload.tr),
                  ),
                ],
              ),
              if (state.remoteStatus.value.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 6.h),
                  child: Text(
                    state.remoteStatus.value,
                    style: state.remoteError.value
                        ? theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)
                        : theme.textTheme.bodySmall,
                  ),
                ),
              // 机内一个模型都没有时说清后果：远程挂了这一段就是失败，
              // 不会像"有本地模型"那样悄悄接上。
              if (state.installed.values.every((e) => !e))
                Padding(
                  padding: EdgeInsets.only(top: 6.h),
                  child: Text(I18nKey.aiRemoteNoLocalFallback.tr, style: theme.textTheme.bodySmall),
                ),
            ],
          ),
        ),
      ],
      const Divider(height: 1),
    ];
  }

  /// 预设名和说明按 id 走 i18n：catalog.json 里的 name 是硬编码中文，英文界面不能照搬。
  /// 远端 catalog 可以带自定义预设，认不出的 id 就回退到 JSON 里的 name，说明留空。
  static String _presetName(AiPreset preset) {
    switch (preset.id) {
      case 'lite':
        return I18nKey.aiPresetLite.tr;
      case 'quality':
        return I18nKey.aiPresetQuality.tr;
      case 'zh':
        return I18nKey.aiPresetZh.tr;
      default:
        return preset.name;
    }
  }

  static String _presetDesc(AiPreset preset) {
    switch (preset.id) {
      case 'lite':
        return I18nKey.aiPresetLiteDesc.tr;
      case 'quality':
        return I18nKey.aiPresetQualityDesc.tr;
      case 'zh':
        return I18nKey.aiPresetZhDesc.tr;
      default:
        return '';
    }
  }

  List<Widget> _buildPresets(BuildContext context, ScSettingsAiLogic logic) {
    final state = logic.state;
    if (state.catalog.presets.isEmpty) {
      return const [];
    }
    return [
      _sectionTitle(context, I18nKey.aiPreset.tr),
      for (final preset in state.catalog.presets)
        _buildPresetTile(context, logic, preset),
    ];
  }

  Widget _buildPresetTile(BuildContext context, ScSettingsAiLogic logic, AiPreset preset) {
    final state = logic.state;
    // 认不出的 id 直接丢掉，跟 installPreset 里的 nonNulls 保持一致，
    // 免得清单里列了个装不上的模型。
    final entries = preset.modelIds.map((id) => state.catalog.byId(id)).nonNulls.toList();
    final total = entries.fold<int>(0, (a, b) => a + b.size);
    final done = entries.where((e) => state.installed[e.id] == true).length;
    final allDone = entries.isNotEmpty && done == entries.length;
    final desc = _presetDesc(preset);

    return ListTile(
      dense: true,
      leading: Icon(
        allDone ? Icons.check_circle : Icons.download_for_offline,
        color: allDone ? Theme.of(context).colorScheme.primary : null,
      ),
      title: Text('${_presetName(preset)} · ${humanSize(total)}'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (desc.isNotEmpty)
            Text(desc, style: Theme.of(context).textTheme.bodySmall),
          Text(entries.map((e) => e.name).join(' · '),
              style: Theme.of(context).textTheme.bodySmall),
          Text(
            allDone
                ? I18nKey.aiPresetAllInstalled.tr
                : I18nKey.aiPresetInstalledCount.trArgs(['$done', '${entries.length}']),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: allDone ? Theme.of(context).colorScheme.primary : null,
                ),
          ),
        ],
      ),
      isThreeLine: true,
      // 全装好了就点不动，省得用户以为还得再点一遍整套
      onTap: logic.busy || allDone ? null : () => logic.installPreset(preset),
    );
  }

  List<Widget> _buildRoleSection(BuildContext context, ScSettingsAiLogic logic, AiRole role) {
    final state = logic.state;
    final models = state.catalog.byRole(role);
    if (models.isEmpty) {
      return const [];
    }
    final selectedId = state.selected[role] ?? '';
    return [
      _sectionTitle(context, role.label),
      for (final m in models) _buildModelTile(context, logic, role, m, selectedId == m.id),
    ];
  }

  Widget _buildModelTile(
    BuildContext context,
    ScSettingsAiLogic logic,
    AiRole role,
    AiModelEntry m,
    bool inUse,
  ) {
    final state = logic.state;
    final installed = state.installed[m.id] == true;
    final installing = state.installingId.value == m.id;

    final subtitle = <String>[
      humanSize(m.size),
      if (m.langs.isNotEmpty && m.langs.first != '*') m.langs.join('/'),
      if (m.license.isNotEmpty) m.license,
    ].join(' · ');

    return ListTile(
      leading: Icon(
        inUse
            ? Icons.check_circle
            : installed
                ? Icons.check_circle_outline
                : Icons.cloud_download_outlined,
        color: inUse ? Theme.of(context).colorScheme.primary : null,
      ),
      title: Text(m.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          if (m.note.isNotEmpty)
            Text(m.note, style: Theme.of(context).textTheme.bodySmall),
          Text(
            installing
                ? I18nKey.aiInstalling
                    .trArgs(['${state.fileIndex.value}', '${state.fileTotal.value}'])
                : inUse
                    ? I18nKey.aiInUse.tr
                    : installed
                        ? I18nKey.aiInstalled.tr
                        : I18nKey.aiNotInstalled.tr,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: inUse ? Theme.of(context).colorScheme.primary : null,
                ),
          ),
        ],
      ),
      isThreeLine: true,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!installed)
            TextButton(
              onPressed: logic.busy ? null : () => logic.install(m),
              child: Text(I18nKey.aiInstall.tr),
            ),
          PopupMenuButton<String>(
            enabled: !logic.busy,
            itemBuilder: (_) => [
              if (installed && !inUse)
                PopupMenuItem<String>(
                  onTap: () => logic.use(role, m),
                  child: Text(I18nKey.aiUse.trArgs([role.label])),
                ),
              // 下不动的时候这两项就是唯一的出路，所以装没装都留着
              PopupMenuItem<String>(
                onTap: () => logic.showUrls(m),
                child: Text(I18nKey.aiShowUrls.tr),
              ),
              PopupMenuItem<String>(
                onTap: () => logic.importLocal(m),
                child: Text(I18nKey.aiImportLocal.tr),
              ),
              // 装好了才给传：半个模型传上去只会让服务端也坏掉
              if (installed && logic.state.remoteEnabled.value)
                PopupMenuItem<String>(
                  onTap: () => logic.uploadModels(m),
                  child: Text(I18nKey.aiRemoteUploadOne.tr),
                ),
              if (installed)
                PopupMenuItem<String>(
                  onTap: () => logic.remove(m),
                  child: Text(I18nKey.aiDeleteModel.tr),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 4.h),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}
