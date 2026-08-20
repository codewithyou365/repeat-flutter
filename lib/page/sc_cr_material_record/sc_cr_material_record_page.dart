import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/ai/record_session.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';

import 'sc_cr_material_record_logic.dart';
import 'sc_cr_material_record_state.dart';

class ScCrMaterialRecordPage extends StatelessWidget {
  const ScCrMaterialRecordPage({Key? key}) : super(key: key);

  static String _mmss(int ms) {
    final s = ms ~/ 1000;
    return '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<ScCrMaterialRecordLogic>();
    final state = logic.state;

    return Obx(() {
      // 黑屏模式下整页盖成纯黑，不显示任何东西。息屏录音的重点就是"别看屏幕"，
      // 留个进度条反而诱着人去看。反馈全靠震动。
      if (state.blacked.value) {
        return _buildBlackMask(context, logic);
      }
      return Scaffold(
        appBar: AppBar(
          title: Text(I18nKey.aiChapterFromRecord.tr),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _confirmExit(logic),
          ),
        ),
        body: Column(
          children: [
            _buildControls(context, logic),
            const Divider(height: 1),
            Expanded(child: _buildSegmentList(context, state)),
          ],
        ),
      );
    });
  }

  Widget _buildBlackMask(BuildContext context, ScCrMaterialRecordLogic logic) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        // 双击才退出黑屏：单击太容易误触，用户揣兜里说话时一碰就亮屏。
        onDoubleTap: logic.exitBlackScreen,
        behavior: HitTestBehavior.opaque,
        child: const SizedBox.expand(),
      ),
    );
  }

  Widget _buildControls(BuildContext context, ScCrMaterialRecordLogic logic) {
    final state = logic.state;
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.error.value.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Text(state.error.value,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          if (!state.recording.value) ...[
            Text(I18nKey.aiRecordScreenMode.tr, style: Theme.of(context).textTheme.titleSmall),
            SizedBox(height: 6.h),
            if (logic.trueScreenOffSupported)
              SegmentedButton<RecordScreenMode>(
                segments: [
                  ButtonSegment(
                    value: RecordScreenMode.black,
                    icon: const Icon(Icons.dark_mode),
                    label: Text(I18nKey.aiRecordScreenBlack.tr),
                  ),
                  ButtonSegment(
                    value: RecordScreenMode.off,
                    icon: const Icon(Icons.phonelink_lock),
                    label: Text(I18nKey.aiRecordScreenOff.tr),
                  ),
                ],
                selected: {state.screenMode.value},
                onSelectionChanged: (v) => logic.toggleScreenMode(v.first),
              ),
            Padding(
              padding: EdgeInsets.only(top: 4.h),
              child: Text(
                state.screenMode.value == RecordScreenMode.black
                    ? I18nKey.aiRecordScreenBlackDesc.tr
                    : I18nKey.aiRecordScreenOffDesc.tr,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            SwitchListTile(
              dense: true,
              value: state.autoPlay.value,
              onChanged: (v) => state.autoPlay.value = v,
              title: Text(I18nKey.aiRecordAutoPlay.tr),
            ),
            SizedBox(height: 12.h),
          ],
          Row(
            children: [
              Expanded(
                child: state.recording.value
                    ? FilledButton.icon(
                        onPressed: logic.stop,
                        icon: const Icon(Icons.stop),
                        label: Text('${I18nKey.aiRecordStop.tr}  ${_mmss(state.elapsedMs.value)}'),
                      )
                    : FilledButton.icon(
                        onPressed: state.starting.value ? null : logic.start,
                        icon: const Icon(Icons.mic),
                        label: Text(I18nKey.aiRecordStart.tr),
                      ),
              ),
              if (state.recording.value && state.screenMode.value == RecordScreenMode.black) ...[
                SizedBox(width: 8.w),
                IconButton(
                  tooltip: I18nKey.aiRecordScreenBlack.tr,
                  icon: const Icon(Icons.dark_mode),
                  onPressed: logic.enterBlackScreen,
                ),
              ],
            ],
          ),
          if (state.recording.value)
            Padding(
              padding: EdgeInsets.only(top: 8.h),
              child: Text(
                '${I18nKey.aiRecordSegments.trArgs(['${state.segments.length}'])}'
                ' · ${I18nKey.aiRecordPending.trArgs(['${state.pendingCount}'])}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSegmentList(BuildContext context, ScCrMaterialRecordState state) {
    if (state.segments.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Text(
            I18nKey.aiChapterFromRecordDesc.tr,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      );
    }
    // 新的在最上面：录着的时候用户关心的是刚说的那句对不对
    return ListView.builder(
      reverse: true,
      itemCount: state.segments.length,
      itemBuilder: (context, i) {
        final seg = state.segments[state.segments.length - 1 - i];
        return ListTile(
          dense: true,
          leading: Text('${seg.index}', style: Theme.of(context).textTheme.bodySmall),
          title: Text(seg.src.isEmpty ? '…' : seg.src),
          subtitle: seg.dst.isEmpty ? null : Text(seg.dst),
          trailing: seg.state == RecordSegmentState.pending
              ? SizedBox(
                  width: 16.w,
                  height: 16.w,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
              : seg.state == RecordSegmentState.failed
                  ? Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error)
                  : const Icon(Icons.check),
        );
      },
    );
  }

  void _confirmExit(ScCrMaterialRecordLogic logic) {
    final state = logic.state;
    if (!state.recording.value && state.segments.isEmpty) {
      Get.back();
      return;
    }
    MsgBox.yesOrNo(
      title: I18nKey.aiChapterFromRecord.tr,
      desc: I18nKey.aiRecordDiscardConfirm.tr,
      yes: () async {
        Get.back();
        await state.session?.discard();
        Get.back();
      },
      no: () => Get.back(),
    );
  }
}
