import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'gs_cr_repeat_finish_logic.dart';

class GsCrRepeatFinishPage extends StatelessWidget {
  const GsCrRepeatFinishPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = Get.find<GsCrRepeatFinishLogic>().state;
    return Scaffold(
      appBar: AppBar(
        title: Text(I18nKey.btnReview.tr),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            // TODO need to extract the `until` function into Nav.dart
            // TODO need to listen to system back event
            Get.until((route) => Get.currentRoute == '/gs/cr'); // Close the special view and go back to home
          },
        ),
      ),
      body: GetBuilder<GsCrRepeatFinishLogic>(
        id: GsCrRepeatFinishLogic.id,
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
