import 'package:get/get.dart';
import 'package:repeat_flutter/db/entity/content.dart';

class Address {
  String title;
  String address;

  Address(this.title, this.address);
}

class GsCrContentShareState {
  final List<Address> addresses = <Address>[];
  Content content = Content.empty();
  var lanAddressSuffix = "";
  RxBool shareNote = false.obs;
}
