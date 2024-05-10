import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/nav.dart';

import 'gs_logic.dart';

class GsPage extends StatelessWidget {
  const GsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(""),
      ),
      body: InkWell(
        onTap: () => {Nav.gsCr.push()},
        child: const Text("en"),
      ),
    );
  }
}
