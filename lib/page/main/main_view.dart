import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'main_logic.dart';

class MainPage extends StatelessWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<MainLogic>();
    final state = Get.find<MainLogic>().state;

    return Scaffold(
      body: Container(
        child: Text("nihao"),
      ),
      bottomNavigationBar: Obx(() => BottomNavigationBar(
          currentIndex: state.bottomNavigationBarIndex.value,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.text_snippet),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings', // Replace with desired label
            ),
          ],
          onTap: logic.onBottomNavigationBarTap)),
    );
  }
}
