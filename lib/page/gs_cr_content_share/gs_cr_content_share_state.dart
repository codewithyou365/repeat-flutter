import 'package:repeat_flutter/db/entity/content.dart';

class Address {
  String title;
  String address;

  Address(this.title, this.address);
}

class GsCrContentShareState {
  final List<Address> addresses = <Address>[];
  Content content = Content(0, 0, '', '', 0, '', 0, false, false, 0, 0);
  var lanAddressSuffix = "";
  var manifestJson = "";
}
