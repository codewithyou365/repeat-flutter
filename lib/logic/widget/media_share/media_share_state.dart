import 'package:get/get.dart';

import 'media_share_args.dart';

class Address {
  String title;
  String address;

  Address(this.title, this.address);
}

class MediaShareState {
  final RxInt addressesLength = 0.obs;
  final List<Address> addresses = <Address>[];
  late MediaShareArgs args;

  var lanAddressSuffix = "/p";
  RxBool webStart = false.obs;
  RxBool enableSsl = false.obs;
}
