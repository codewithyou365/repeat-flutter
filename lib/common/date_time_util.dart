class DateTimeUtil {
  static String format(DateTime time) {
    return '${time.year.toString().padLeft(4, '0')}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }

  static DateTime parse(String time) {
    return DateTime.parse(time.replaceFirst(' ', 'T'));
  }
}
