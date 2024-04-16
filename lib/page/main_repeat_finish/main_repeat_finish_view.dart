import 'package:flutter/material.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';

class MainRepeatFinishPage extends StatelessWidget {
  const MainRepeatFinishPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(I18nKey.btnReview.tr),
        ),
        body: Text("hello"));
  }
}
