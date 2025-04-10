import 'package:repeat_flutter/db/entity/content.dart';

class Address {
  String title;
  String address;

  Address(this.title, this.address);
}

class GsCrContentShareState {
  final List<Address> addresses = <Address>[];
  Content content = Content(
    classroomId: 0,
    serial: 0,
    name: '',
    desc: '',
    docId: 0,
    url: '',
    sort: 0,
    hide: false,
    warning: WarningType.none,
    createTime: 0,
    updateTime: 0,
  );
  var lanAddressSuffix = "";
  var manifestJson = "";
}
