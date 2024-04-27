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

    String year = date.year.toString();
    String month = date.month.toString().padLeft(2, '0');
    String day = date.day.toString().padLeft(2, '0');

    return Date(int.parse(year + month + day));
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
