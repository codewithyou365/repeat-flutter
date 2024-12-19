import 'dart:io';

class Ip {
  static Future<List<String>> getLanIps() async {
    List<String> ret = [];
    for (var interface in await NetworkInterface.list()) {
      for (var addr in interface.addresses) {
        if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
          ret.add(addr.address);
        }
      }
    }
    return ret;
  }
}
