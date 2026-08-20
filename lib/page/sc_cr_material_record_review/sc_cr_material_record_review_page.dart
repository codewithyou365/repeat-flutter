import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/logic/ai/infer_isolate.dart';
import 'package:repeat_flutter/logic/ai/record_session.dart';

import 'sc_cr_material_record_review_logic.dart';

class ScCrMaterialRecordReviewPage extends StatelessWidget {
  const ScCrMaterialRecordReviewPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<ScCrMaterialRecordReviewLogic>();
    final state = logic.state;

    return Scaffold(
      appBar: AppBar(
        title: Text(I18nKey.aiReviewTitle.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.psychology),
            tooltip: I18nKey.aiModel.tr,
            onPressed: logic.switchModel,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: I18nKey.aiReviewDiscard.tr,
            onPressed: logic.discard,
          ),
        ],
      ),
      body: Obx(() {
        if (state.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          children: [
            _buildHeader(context, logic),
            const Divider(height: 1),
            Expanded(child: _buildList(context, logic)),
          ],
        );
      }),
      bottomNavigationBar: Obx(() => SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
              child: FilledButton.icon(
                onPressed: state.busy.value || state.segments.isEmpty ? null : logic.commit,
                icon: const Icon(Icons.playlist_add_check),
                label: Text(I18nKey.aiReviewCommit.tr),
              ),
            ),
          )),
    );
  }

  Widget _buildHeader(BuildContext context, ScCrMaterialRecordReviewLogic logic) {
    final state = logic.state;
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 8.w, 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.error.value.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: 6.h),
              child: Text(state.error.value,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${I18nKey.aiRecordSegments.trArgs(['${state.segments.length}'])}'
                  '${state.pendingCount > 0 ? ' · ${I18nKey.aiRecordPending.trArgs(['${state.pendingCount}'])}' : ''}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              if (state.pendingCount > 0)
                TextButton(
                  onPressed: state.busy.value ? null : logic.processAll,
                  child: Text(I18nKey.aiReviewProcessAll.tr),
                ),
            ],
          ),
          if (state.busy.value) const LinearProgressIndicator(),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, ScCrMaterialRecordReviewLogic logic) {
    final state = logic.state;
    if (state.segments.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Text(I18nKey.aiReviewEmpty.tr,
              textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
        ),
      );
    }
    // 段的顺序就是将来 verse 的顺序，所以要能拖
    return ReorderableListView.builder(
      itemCount: state.segments.length,
      onReorderItem: logic.reorder,
      buildDefaultDragHandles: false,
      itemBuilder: (context, i) {
        final seg = state.segments[i];
        return _buildTile(context, logic, seg, i);
      },
    );
  }

  Widget _buildTile(
    BuildContext context,
    ScCrMaterialRecordReviewLogic logic,
    RecordSegment seg,
    int position,
  ) {
    final working = logic.state.workingIndex.value == seg.index;
    return Card(
      key: ValueKey(seg.index),
      margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      child: Padding(
        padding: EdgeInsets.fromLTRB(8.w, 6.h, 4.w, 6.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ReorderableDragStartListener(
              index: position,
              child: Padding(
                padding: EdgeInsets.only(top: 6.h, right: 4.w),
                child: const Icon(Icons.drag_handle, size: 18),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () => logic.editText(seg, source: true),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.h),
                      child: Text(seg.src.isEmpty ? '—' : seg.src),
                    ),
                  ),
                  InkWell(
                    onTap: () => logic.editText(seg, source: false),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.h),
                      child: Text(
                        seg.dst.isEmpty ? '—' : seg.dst,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ),
                  ),
                  if (seg.state != RecordSegmentState.done)
                    Text(
                      seg.state == RecordSegmentState.failed
                          ? I18nKey.aiReviewProcess.tr
                          : I18nKey.aiRecordPending.trArgs(['1']),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                    ),
                ],
              ),
            ),
            if (working)
              Padding(
                padding: EdgeInsets.only(top: 8.h, right: 8.w),
                child: SizedBox(
                    width: 16.w, height: 16.w, child: const CircularProgressIndicator(strokeWidth: 2)),
              )
            else ...[
              IconButton(
                icon: const Icon(Icons.play_arrow),
                tooltip: I18nKey.aiReviewDst.tr,
                onPressed: () => logic.play(seg),
              ),
              PopupMenuButton<String>(
                enabled: !logic.state.busy.value,
                itemBuilder: (_) => [
                  PopupMenuItem<String>(
                    onTap: () => logic.rerun(seg, InferJobKind.asr),
                    child: Text(I18nKey.aiReviewReAsr.tr),
                  ),
                  PopupMenuItem<String>(
                    onTap: () => logic.rerun(seg, InferJobKind.mt),
                    child: Text(I18nKey.aiReviewReMt.tr),
                  ),
                  PopupMenuItem<String>(
                    onTap: () => logic.rerun(seg, InferJobKind.tts),
                    child: Text(I18nKey.aiReviewReTts.tr),
                  ),
                  PopupMenuItem<String>(
                    onTap: () => logic.remove(seg),
                    child: Text(I18nKey.aiReviewDelete.tr),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
