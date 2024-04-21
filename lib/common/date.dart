class Date {
  final int _value;

  Date(this._value);

  int get value => _value;

  static Date from(DateTime date) {
    String year = date.year.toString();
    String month = _formatNumber(date.month);
    String day = _formatNumber(date.day);

    return Date(int.parse(year + month + day));
  }

  static String _formatNumber(int number) {
    return number < 10 ? '0$number' : '$number';
  }
}
