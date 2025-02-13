typedef ExistById1 = Future<int?> Function(int id);
typedef ExistById2 = Future<int?> Function(int id1, int id);

class Num {
  static List<int> toInts(String a) {
    List<String> strings = a.split(",");
    List<int> ints = [];
    for (String s in strings) {
      ints.add(int.parse(s.trim()));
    }
    return ints;
  }

  static Future<int> getNextId(
    int? maxId, {
    int? id,
    ExistById1? existById1,
    ExistById2? existById2,
  }) async {
    var spareId = 1;
    if (maxId != null && maxId != 0) {
      for (spareId = 1; spareId < maxId; spareId++) {
        if (existById1 != null) {
          if (await existById1(spareId) == 0) {
            break;
          }
        } else {
          if (await existById2!(id!, spareId) == 0) {
            break;
          }
        }
      }
      if (spareId == maxId) {
        spareId++;
      }
    }
    return spareId;
  }

  static String toBase26(int value) {
    const base26Chars = 'abcdefghijklmnopqrstuvwxyz';
    const base26Length = 26;
    if (value == 0) return '0';
    String result = '';
    while (value > 0) {
      result = base26Chars[value % base26Length] + result;
      value ~/= base26Length;
    }
    return result;
  }
}
