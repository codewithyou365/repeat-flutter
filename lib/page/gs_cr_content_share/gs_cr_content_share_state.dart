class Address {
  String title;
  String address;

  Address(this.title, this.address);
}

class GsCrContentShareState {
  final List<Address> addresses = <Address>[];
  var rawUrl = "";
  var lanAddressSuffix = "";
  var manifestJson = "";
}
