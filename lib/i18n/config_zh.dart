library i18n;

import 'config.dart';
import 'i18n_key.dart';

class ConfigZh extends Config {
  ConfigZh({Map<String, String>? defaultData}) : super(defaultData) {
    put(I18nKey.appName, "重复");
    put(I18nKey.settings, "设置");
    put(I18nKey.content, "内容");
    put(I18nKey.contentShare, "内容分享");
    put(I18nKey.mediaImportTemplate, "媒体导入模版");
    put(I18nKey.statistic, "统计");
    put(I18nKey.statisticLearn, "统计-学习");
    put(I18nKey.statisticReview, "统计-回顾");
    put(I18nKey.statisticDetail, "统计-详情");
    put(I18nKey.language, "语言");
    put(I18nKey.theme, "主题");
    put(I18nKey.data, "数据");
    put(I18nKey.themeDark, "暗色主题");
    put(I18nKey.themeLight, "亮色主题");
    put(I18nKey.labelDeveloping, "开发中");
    put(I18nKey.labelTitle, "标题");
    put(I18nKey.labelSelectClassroom, "选择课堂");
    put(I18nKey.labelDeleteClassroom, "请确定删除这个课堂 : %s");
    put(I18nKey.labelDeleteClassroomAll, "同时删除学习记录");
    put(I18nKey.labelClassroomName, "课堂名称");
    put(I18nKey.labelClassroomNameEmpty, "课堂名字应不能为空");
    put(I18nKey.labelClassroomNameError, "课堂名字应为 3 个字母或更少，并且由大写字母数字字符组成。");
    put(I18nKey.labelClassroomNameDuplicated, "课堂名字重复。");
    put(I18nKey.labelContentName, "内容名称");
    put(I18nKey.labelContentNameEmpty, "内容名字应不能为空");
    put(I18nKey.labelContentNameError, "内容名字应为 3 个字母或更少，并且由大写字母数字字符组成。");
    put(I18nKey.labelContentNameDuplicated, "内容名字重复。");
    put(I18nKey.labelDelete, "删除 ！");
    put(I18nKey.labelRemoteUrl, "远程地址");
    put(I18nKey.labelOriginalAddress, "原始地址");
    put(I18nKey.labelLanAddress, "局域网地址");
    put(I18nKey.labelDownloadFirstBeforeSharing, "请先下载再进行分享");
    put(I18nKey.labelDownloadFirstBeforeSaving, "请先下载再进行保存");
    put(I18nKey.labelAddContent, "新增内容");
    put(I18nKey.labelDeleteContent, "请确定删除内容： %s");
    put(I18nKey.labelDownloadContent, "下载内容");
    put(I18nKey.labelScheduleContent, "添加学习任务 %s 个单位");
    put(I18nKey.labelNoLearningContent, "没有学习内容");
    put(I18nKey.labelResetLearningContent, "在 %s 后，将重置学习内容");
    put(I18nKey.labelTips, "提示");
    put(I18nKey.labelReviewThisCount, "回顾该内容次数");
    put(I18nKey.labelLearnCount, "学习次数");
    put(I18nKey.labelReviewCount, "回顾次数");
    put(I18nKey.labelFullCustomCount, "自定义次数");
    put(I18nKey.labelNoContent, "暂无内容");
    put(I18nKey.labelJsonErrorSaveFailed, "JSON格式错误，保存失败");
    put(I18nKey.labelImportFailed, "导入失败");
    put(I18nKey.labelImportSuccess, "导入成功");
    put(I18nKey.labelImportMojo, "导入新数据将清除所有现有数据");
    put(I18nKey.labelImportMojoTips, "输入红色文字以继续");
    put(I18nKey.labelImportCanceled, "导入取消");
    put(I18nKey.labelImporting, "导入中...");
    put(I18nKey.labelExporting, "导出中...");
    put(I18nKey.labelExecuting, "执行中...");
    put(I18nKey.labelDeleting, "删除中...");
    put(I18nKey.labelSaving, "保存中...");
    put(I18nKey.labelSelectDirectoryToSave, "选择一个目录进行保存 %s");
    put(I18nKey.labelFileSaved, "文件已保存");
    put(I18nKey.labelSaveSuccess, "保存成功 : %s");
    put(I18nKey.labelDirectoryPermissionDenied, "请重新选择其他目录，没有权限保存到该目录: %s");
    put(I18nKey.labelSaved, "保存成功");
    put(I18nKey.labelSaveCancel, "保存已取消");
    put(I18nKey.labelStoragePermissionDenied, "存储权限被拒绝，请在设置中打开存储权限");
    put(I18nKey.labelLearned, "已学习: %s");
    put(I18nKey.labelTotal, "总数: %s");
    put(I18nKey.labelProgress, "进度");
    put(I18nKey.labelMonth, "月份");
    put(I18nKey.labelAdjustLearnProgress, "调整学习进度");
    put(I18nKey.labelAdjustLearnProgressDesc, "当前进度为 %s，请调整您的学习进度");
    put(I18nKey.labelPleaseInputUnSignNumber, "请输入大于或等于 0 的数字");
    put(I18nKey.labelReset, "重置");
    put(I18nKey.labelResetAllDesc, "将重置今日所有的任务，是否继续？");
    put(I18nKey.labelResetLearnDesc, "将重置学习的任务，是否继续？");
    put(I18nKey.labelResetReviewDesc, "将重置回顾的任务，是否继续？");
    put(I18nKey.labelResetFullCustomDesc, "将删除自定义任务，是否继续？");
    put(I18nKey.labelConfigSettingsForEl, "学习设置");
    put(I18nKey.labelConfigSettingsForElDesc, "以艾宾浩斯遗忘曲线进行安排学习。");
    put(I18nKey.labelConfigSettingsForRel, "回顾设置");
    put(I18nKey.labelConfigSettingsForRelDesc, "对之前的学习，进行回顾安排的配置。");
    put(I18nKey.labelElConfig0000, "安排%s级，数量不限 (每组不限)");
    put(I18nKey.labelElConfig0001, "安排%s级，数量不限 (每组%s个)");
    put(I18nKey.labelElConfig0010, "安排%s级，数量%s (每组不限)");
    put(I18nKey.labelElConfig0011, "安排%s级，数量%s (每组%s个)");
    put(I18nKey.labelElConfig0100, "安排%s级到%s级，数量不限 (每组不限)");
    put(I18nKey.labelElConfig0101, "安排%s级到%s级，数量不限 (每组%s个)");
    put(I18nKey.labelElConfig0110, "安排%s级到%s级，数量%s (每组不限)");
    put(I18nKey.labelElConfig0111, "安排%s级到%s级，数量%s (每组%s个)");
    put(I18nKey.labelElConfig1000, "随机安排%s级，数量不限 (每组不限)");
    put(I18nKey.labelElConfig1001, "随机安排%s级，数量不限 (每组%s个)");
    put(I18nKey.labelElConfig1010, "随机安排%s级，数量%s (每组不限)");
    put(I18nKey.labelElConfig1011, "随机安排%s级，数量%s (每组%s个)");
    put(I18nKey.labelElConfig1100, "随机安排%s级到%s级，数量不限 (每组不限)");
    put(I18nKey.labelElConfig1101, "随机安排%s级到%s级，数量不限 (每组%s个)");
    put(I18nKey.labelElConfig1110, "随机安排%s级到%s级，数量%s (每组不限)");
    put(I18nKey.labelElConfig1111, "随机安排%s级到%s级，数量%s (每组%s个)");
    put(I18nKey.labelRelConfig0, "第%s次回顾%s天以前的内容，从%s开始 (每组不限)");
    put(I18nKey.labelRelConfig1, "第%s次回顾%s天以前的内容，从%s开始 (每组%s个)");
    put(I18nKey.labelFullCustomConfig, "从内容@0的@1节@2段开始 规划@3个段 (每组不限)");
    put(I18nKey.labelElRandom, "是否随机");
    put(I18nKey.labelElToLevel, "结束等级");
    put(I18nKey.labelElLevel, "开始等级");
    put(I18nKey.labelElLearnCount, "学习数量");
    put(I18nKey.labelRelBefore, "多少天前");
    put(I18nKey.labelRelFrom, "开始时间");
    put(I18nKey.labelLearnCountPerGroup, "每组数量");
    put(I18nKey.labelFinish, "完成");
    put(I18nKey.labelALL, "全部");
    put(I18nKey.labelSavingConfirm, "是否确定保存？");
    put(I18nKey.labelConfigChange, "配置已改变是否保存？");
    put(I18nKey.labelTextChange, "文本已改变是否保存？");
    put(I18nKey.labelResetConfig, "配置将被重置。确定吗？");
    put(I18nKey.labelDetailConfig, "配置详情");
    put(I18nKey.labelDetail, "详情");
    put(I18nKey.labelCopyConfig, "复制配置");
    put(I18nKey.labelDeleteConfig, "删除配置");
    put(I18nKey.labelCopyText, "复制文本");
    put(I18nKey.labelResetPassword, "重置密码");
    put(I18nKey.labelResetConfigDesc, "执行重置配置后，将使用系统默认的配置？");
    put(I18nKey.labelOnTapError, "请长按按键进行确认");
    put(I18nKey.labelSetMaskTips, "向左滑动增加挡板高度");
    put(I18nKey.labelQrCodeContentCopiedToClipboard, "二维码内容已拷贝到剪切板中");
    put(I18nKey.labelCopiedToClipboard, "已拷贝到剪切板中");
    put(I18nKey.labelShouldLinkToTheContentBeAdded, "是否添加改内容链接");
    put(I18nKey.labelTooMuchData, "数据过多! %s");
    put(I18nKey.labelDataDuplication, "数据重复!");
    put(I18nKey.labelDataAnomaly, "数据异常! %s");
    put(I18nKey.labelDataAnomalyWithArg, "数据异常! %s");
    put(I18nKey.labelRemoteImport, "远程导入");
    put(I18nKey.labelLocalZipImport, "本地ZIP导入");
    put(I18nKey.labelLocalMediaImport, "本地媒体导入");
    put(I18nKey.labelLocalImportCancel, "本地导入取消");
    put(I18nKey.labelSegmentRemoved, "对应的学习片段已移除，建议先备份你的数据，再点击确定进行删除相关数据。");
    put(I18nKey.labelDocNotBeDownloaded, "还未下载文件:%s");
    put(I18nKey.labelDocCantBeFound, "无法找到文件:%s");
    put(I18nKey.labelInputPathError, "路径错误");
    put(I18nKey.labelScheduleCount, "规划数量");
    put(I18nKey.labelFrom, "开始于");
    put(I18nKey.labelLesson, "节");
    put(I18nKey.labelSegment, "段");
    put(I18nKey.labelSegmentName, "段落");
    put(I18nKey.labelIgnorePunctuation, "忽略标点符号");
    put(I18nKey.labelMatchType, "匹配类型");
    put(I18nKey.labelSkipCharacter, "输入该字符便跳过");
    put(I18nKey.labelEnableEditSegment, "启用编辑段落");
    put(I18nKey.labelGameId, "游戏ID");
    put(I18nKey.labelOnlineUserNumber, "在线人数");
    put(I18nKey.labelAllowRegisterNumber, "允许注册人数");
    put(I18nKey.labelQuestion, "问题");
    put(I18nKey.labelAnswer, "答案");
    put(I18nKey.labelQuestionAndAnswer, "问与答");
    put(I18nKey.labelCopyMode, "复制模式");
    put(I18nKey.labelWord, "单词");
    put(I18nKey.labelSingle, "单字");
    put(I18nKey.labelAll, "全部");
    put(I18nKey.labelSetLevel, "等级");
    put(I18nKey.labelSetNextLearnDate, "下次学习时间");
    put(I18nKey.labelSummary, "概要");
    put(I18nKey.labelTodayLearning, "今日学习");
    put(I18nKey.labelTotalLearning, "总计学习");
    put(I18nKey.labelTodayTime, "今日时长");
    put(I18nKey.labelTotalTime, "总计时长");
    put(I18nKey.labelMin, "分钟");
    put(I18nKey.labelSeg, "段");
    put(I18nKey.labelNote, "笔记");
    put(I18nKey.labelShare, "分享");
    put(I18nKey.labelCalendar, "日历");
    put(I18nKey.labelCopyTemplateCount, "复制模版数量");
    put(I18nKey.labelSegmentNeedToContainAnswer, "段落需要包含答案字段");
    put(I18nKey.labelSegmentKeyDuplicated, "段落KEY重复： %s");
    put(I18nKey.labelKey, "键");
    put(I18nKey.labelContent, "内容");
    put(I18nKey.labelPosition, "位置");
    put(I18nKey.labelSortBy, "排序方式");
    put(I18nKey.labelSortProgressAsc, "进度 (升序)");
    put(I18nKey.labelSortProgressDesc, "进度 (降序)");
    put(I18nKey.labelSortPositionAsc, "位置 (升序)");
    put(I18nKey.labelSortPositionDesc, "位置 (降序)");
    put(I18nKey.labelSortNextLearnDateAsc, "下次学习时间 (升序)");
    put(I18nKey.labelSortNextLearnDateDesc, "下次学习时间 (降序)");
    put(I18nKey.labelFindUnnecessarySegments, "查找多余段落");
    put(I18nKey.labelSearch, "搜索...");
    put(I18nKey.btnStart, "开始");
    put(I18nKey.btnAddSchedule, "添加规划");
    put(I18nKey.btnConfigSettings, "配置设置");
    put(I18nKey.btnSet, "设置");
    put(I18nKey.btnUse, "使用");
    put(I18nKey.btnSetHead, "设置头部");
    put(I18nKey.btnSetTail, "设置尾部");
    put(I18nKey.btnExtendTail, "延长尾部");
    put(I18nKey.btnResetTail, "重置尾部");
    put(I18nKey.btnOther, "其他");
    put(I18nKey.btnCut, "切割并保留前后");
    put(I18nKey.btnDeleteCurr, "删除当前段");
    put(I18nKey.btnCancel, "取消");
    put(I18nKey.btnOk, "确定");
    put(I18nKey.btnDelete, "删除");
    put(I18nKey.btnShare, "分享");
    put(I18nKey.btnScan, "扫描");
    put(I18nKey.btnEditTrack, "编辑音轨");
    put(I18nKey.btnEditNote, "编辑笔记");
    put(I18nKey.btnGameMode, "游戏模式");
    put(I18nKey.btnConcentration, "专注");
    put(I18nKey.btnAdd, "新增");
    put(I18nKey.btnReset, "重置");
    put(I18nKey.btnCopy, "复制");
    put(I18nKey.btnDownload, "下载");
    put(I18nKey.btnLearn, "学习");
    put(I18nKey.btnBrowse, "浏览");
    put(I18nKey.btnExamine, "考查");
    put(I18nKey.btnReview, "回顾");
    put(I18nKey.btnFullCustom, "自定义");
    put(I18nKey.btnRepeat, "重复");
    put(I18nKey.btnSchedule, "安排");
    put(I18nKey.btnShow, "展示");
    put(I18nKey.btnTips, "提示");
    put(I18nKey.btnUnknown, "不知道");
    put(I18nKey.btnKnow, "知道");
    put(I18nKey.btnError, "错误");
    put(I18nKey.btnNext, "下一个");
    put(I18nKey.btnPrevious, "上一个");
    put(I18nKey.btnFinish, "完成");
    put(I18nKey.btnExport, "导出");
    put(I18nKey.btnImport, "导入");
    put(I18nKey.btnSave, "保存");
    put(I18nKey.btnClose, "关闭");
    put(I18nKey.btnCheck, "检查");
    put(I18nKey.btnEditSegment, "编辑段落");
  }
}
