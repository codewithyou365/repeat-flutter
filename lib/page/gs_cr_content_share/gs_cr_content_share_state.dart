import 'package:get/get.dart';

class Address {
  String title;
  String address;

  Address(this.title, this.address);
}

class GsCrContentShareState {
  final List<Address> addresses = <Address>[];
  var lanAddressSuffix = "";
  var manifestJson = "";
}
