class Date {
  static bool test = false;
  final int _value;

  Date(this._value);

  int get value => _value;

  static Date from(DateTime date) {
    if (test) {
      String hour = date.hour.toString().padLeft(2, '0');
      String minute = date.minute.toString().padLeft(2, '0');
      String second = date.second.toString().padLeft(2, '0');
      return Date(int.parse(hour + minute + second));
    }

    return fromYmd(date.year, date.month, date.day);
  }

  static Date fromYmd(int y, int m, int d) {
    String year = y.toString();
    String month = m.toString().padLeft(2, '0');
    String day = d.toString().padLeft(2, '0');

    return Date(int.parse(year + month + day));
  }

  String format() {
    String stringValue = _value.toString();
    var md = stringValue.substring(stringValue.length - 4);
    int year = int.parse(stringValue.substring(0, stringValue.length - 4));
    int month = int.parse(md.substring(0, 2));
    int day = int.parse(md.substring(2, 4));

    return '$year-$month-$day';
  }

  String formatYm() {
    String stringValue = _value.toString();
    var md = stringValue.substring(stringValue.length - 4);
    int year = int.parse(stringValue.substring(0, stringValue.length - 4));
    int month = int.parse(md.substring(0, 2));

    return '$year-$month';
  }

  DateTime toDateTime() {
    String stringValue = _value.toString();
    var md = stringValue.substring(stringValue.length - 4);
    int year = int.parse(stringValue.substring(0, stringValue.length - 4));
    int month = int.parse(md.substring(0, 2));
    int day = int.parse(md.substring(2, 4));

    return DateTime(year, month, day);
  }
}
