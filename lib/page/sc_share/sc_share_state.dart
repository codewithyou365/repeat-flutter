import 'package:get/get.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';

class Address {
  String title;
  String address;

  Address(this.title, this.address);
}

class ScShareState {
  final List<Address> addresses = <Address>[];
  Classroom classroom = Classroom(0, '', 0, true, '{}', 0);
  var lanAddressSuffix = "";
  RxBool shareNote = false.obs;
  RxBool webStart = false.obs;
  RxString user = "".obs;
  RxString password = "".obs;
}
