import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/ai/ai_catalog.dart';

import 'sc_settings_ai_logic.dart';

class ScSettingsAiPage extends StatelessWidget {
  const ScSettingsAiPage({Key? key}) : super(key: key);

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
          if (state.installingId.value.isNotEmpty) ...[
            SizedBox(height: 10.h),
            Row(
              children: [
                Expanded(
                  child: Text(
                    state.presetName.value.isNotEmpty
                        ? '${state.presetName.value} ${state.presetIndex.value}/${state.presetTotal.value} · '
                            '${I18nKey.aiInstalling.trArgs(['${state.fileIndex.value}', '${state.fileTotal.value}'])}'
                        : I18nKey.aiInstalling
                            .trArgs(['${state.fileIndex.value}', '${state.fileTotal.value}']),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                TextButton(onPressed: logic.cancel, child: Text(I18nKey.btnCancel.tr)),
              ],
            ),
            LinearProgressIndicator(value: state.fileProgress.value),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildPresets(BuildContext context, ScSettingsAiLogic logic) {
    final state = logic.state;
    if (state.catalog.presets.isEmpty) {
      return const [];
    }
    return [
      _sectionTitle(context, I18nKey.aiPreset.tr),
      for (final preset in state.catalog.presets)
        ListTile(
          dense: true,
          leading: const Icon(Icons.download_for_offline),
          title: Text(I18nKey.aiInstallPreset.trArgs([
            preset.name,
            humanSize(preset.modelIds
                .map((id) => state.catalog.byId(id)?.size ?? 0)
                .fold<int>(0, (a, b) => a + b)),
          ])),
          onTap: logic.busy ? null : () => logic.installPreset(preset),
        ),
    ];
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
      trailing: installed
          ? PopupMenuButton<String>(
              enabled: !logic.busy,
              itemBuilder: (_) => [
                if (!inUse)
                  PopupMenuItem<String>(
                    onTap: () => logic.use(role, m),
                    child: Text(I18nKey.aiUse.trArgs([role.label])),
                  ),
                PopupMenuItem<String>(
                  onTap: () => logic.remove(m),
                  child: Text(I18nKey.aiDeleteModel.tr),
                ),
              ],
            )
          : TextButton(
              onPressed: logic.busy ? null : () => logic.install(m),
              child: Text(I18nKey.aiInstall.tr),
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
