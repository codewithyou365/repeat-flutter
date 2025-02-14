import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppBarWidget {
  static List<Widget> buildAppBarAction(List<PopupMenuEntry<String>> items) {
    return <Widget>[
      Padding(
        padding: EdgeInsets.all(8.0.w),
        child: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          itemBuilder: (BuildContext context) => items,
        ),
      ),
    ];
  }
}
