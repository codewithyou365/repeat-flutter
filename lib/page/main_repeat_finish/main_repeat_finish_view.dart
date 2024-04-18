import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/page/main_repeat_finish/main_repeat_finish_logic.dart';

class MainRepeatFinishPage extends StatelessWidget {
  const MainRepeatFinishPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = Get.find<MainRepeatFinishLogic>().state;
    return Scaffold(
      appBar: AppBar(
        title: Text(I18nKey.btnReview.tr),
      ),
      body: GetBuilder<MainRepeatFinishLogic>(
        id: MainRepeatFinishLogic.id,
        builder: (_) {
          return ListView.builder(
            itemCount: state.segments.length,
            itemBuilder: (BuildContext context, int index) {
              return Column(
                children: [
                  ListTile(
                    title: Text(state.segments[index].question),
                  ),
                  ListTile(
                    title: Text(state.segments[index].answer),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget buildButton(String text, VoidCallback onPressed) {
    return TextButton(
      child: Text(text),
      onPressed: onPressed,
    );
  }
}