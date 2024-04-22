class Num {
  static List<int> toInts(String a) {
    List<String> strings = a.split(",");
    List<int> ints = [];
    for (String s in strings) {
      ints.add(int.parse(s.trim()));
    }
    return ints;
  }
}
