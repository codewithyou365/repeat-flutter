import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/nav.dart';

import 'content_logic.dart';

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
    return GetBuilder<ContentLogic>(
        id: ContentLogic.id,
        builder: (context) {
          return Scaffold(
            body: Column(
              children: [
                SizedBox(height: topPadding),
                topBar(logic: logic, width: screenWidth, height: topBarHeight),
                const Spacer(),
                Container(color: Colors.red),
              ],
            ),
          );
        });
  }

  Widget topBar({required ContentLogic logic, required double width, required double height}) {
    final taps = [I18nKey.labelRoot.tr, I18nKey.labelLesson.tr, I18nKey.labelSegment.tr];
    final startSearch = logic.state.startSearch;
    final tabIndex = logic.state.tabIndex;
    const padding = 10.0;
    final icon = height;
    final searchBarWidth = width - icon * 2 - padding * 2;
    final tabWidth = searchBarWidth / taps.length;
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
                  children: List.generate(taps.length, (i) {
                    return Expanded(
                      child: TextButton(
                        onPressed: () => tabIndex.value = i,
                        child: Text(taps[i]),
                      ),
                    );
                  }),
                ),
                Obx(
                  () => AnimatedPositioned(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    left: tabIndex.value * tabWidth,
                    top: 0,
                    width: tabWidth,
                    height: 3,
                    child: Container(color: Colors.blue),
                  ),
                ),
                Obx(
                  () => AnimatedPositioned(
                    duration: const Duration(milliseconds: 100),
                    top: 0,
                    bottom: 0,
                    left: startSearch.value ? 0 : searchBarWidth,
                    width: startSearch.value ? searchBarWidth : 0,
                    child: Container(
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: icon,
            height: icon,
            child: IconButton(
              onPressed: () {
                startSearch.value = !startSearch.value;
              },
              icon: const Icon(Icons.search),
            ),
          ),
          const SizedBox(width: padding),
        ],
      ),
    );
  }
}
