class DateHelp {

  static int from(DateTime date) {
    String year = date.year.toString();
    String month = _formatNumber(date.month);
    String day = _formatNumber(date.day);

    return int.parse(year + month + day);
  }

  static String _formatNumber(int number) {
    return number < 10 ? '0$number' : '$number';
  }
}
