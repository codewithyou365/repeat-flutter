import 'package:floor/floor.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/nav.dart';
import 'package:repeat_flutter/widget/row/row_widget.dart';

import 'content_logic.dart';
import 'logic/helper.dart';

class ContentPage extends StatelessWidget {
  const ContentPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<ContentLogic>();
    final state = logic.state;
    final Size screenSize = MediaQuery.of(context).size;
    final double topPadding = MediaQuery.of(context).padding.top;
    final double leftPadding = MediaQuery.of(context).padding.left;
    final double screenWidth = screenSize.width;
    double screenHeight = screenSize.height;
    var landscape = false;
    if (screenWidth > screenHeight) {
      landscape = true;
    }
    double topBarHeight = 50;
    double bodyHeight = screenHeight - topPadding - topBarHeight - RowWidget.dividerHeight;
    return Scaffold(
      body: Column(
        children: [
          SizedBox(height: topPadding),
          topBar(logic: logic, width: screenWidth, height: topBarHeight),
          RowWidget.buildDividerWithoutColor(),
          GetBuilder<ContentLogic>(
              id: ContentLogic.id,
              builder: (context) {
                var list = logic.viewList[state.tabIndex.value];
                if (list == null) {
                  return const SizedBox.shrink();
                } else {
                  return list.show(
                    focus: false,
                    height: bodyHeight,
                    width: screenWidth,
                  );
                }
              })
        ],
      ),
    );
  }

  Widget topBar({required ContentLogic logic, required double width, required double height}) {
    final taps = [I18nKey.labelRoot.tr, I18nKey.labelLesson.tr, I18nKey.labelSegment.tr];
    final startSearch = logic.state.startSearch;
    final tabIndex = logic.state.tabIndex;
    const padding = 10.0;
    final icon = height;
    final searchBarWidth = width - icon - padding * 2;
    final tabWidth = (searchBarWidth - icon) / taps.length;
    return SizedBox(
      height: height,
      child: Row(
        children: [
          const SizedBox(width: padding),
          SizedBox(
            width: icon,
            height: icon,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new),
              onPressed: () {
                Nav.back();
              },
            ),
          ),
          SizedBox(
            width: searchBarWidth,
            height: height,
            child: Stack(
              children: [
                Row(
                  children: [
                    ...List.generate(taps.length, (i) {
                      return Expanded(
                        child: TextButton(
                          onPressed: () {
                            tabIndex.value = i;
                            logic.update([ContentLogic.id]);
                          },
                          child: Text(taps[i]),
                        ),
                      );
                    }),
                    SizedBox(
                      width: icon,
                      height: icon,
                      child: IconButton(
                        onPressed: () {
                          startSearch.value = true;
                          var list = logic.viewList[tabIndex.value];
                          list?.searchFocusNode.requestFocus();
                        },
                        icon: const Icon(Icons.search),
                      ),
                    ),
                  ],
                ),
                Obx(
                  () => AnimatedPositioned(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    left: tabIndex.value * tabWidth,
                    top: 0,
                    width: tabWidth,
                    height: startSearch.value ? 0 : 3,
                    child: Container(color: Colors.blue),
                  ),
                ),
                Obx(
                  () {
                    var textField = Helper.getTextField();
                    var list = logic.viewList[tabIndex.value];
                    if (list != null) {
                      textField = Helper.getTextField(
                        controller: list.searchController,
                        focusNode: list.searchFocusNode,
                        onSubmitted: (value) {
                          list.trySearch();
                        },
                      );
                    }
                    return AnimatedPositioned(
                      duration: const Duration(milliseconds: 100),
                      top: 0,
                      bottom: 0,
                      left: startSearch.value ? 0 : searchBarWidth,
                      width: startSearch.value ? searchBarWidth : 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(Get.context!).secondaryHeaderColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: textField,
                      ),
                    );
                  },
                ),
                Obx(
                  () => AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: startSearch.value ? 1.0 : 0.0,
                    child: Row(
                      children: [
                        const Spacer(),
                        startSearch.value
                            ? SizedBox(
                                width: icon,
                                height: icon,
                                child: IconButton(
                                  onPressed: () {
                                    startSearch.value = false;
                                    for (var list in logic.viewList) {
                                      if (list != null) {
                                        list.searchFocusNode.unfocus();
                                      }
                                    }
                                  },
                                  icon: const Icon(Icons.close),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: padding),
        ],
      ),
    );
  }
}
