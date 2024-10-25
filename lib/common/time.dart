String formatHm(int milliseconds) {
  int hours = milliseconds ~/ 3600000;
  int remainingMinutes = (milliseconds % 3600000) ~/ 60000;
  String formattedTime = '$hours H $remainingMinutes M';
  return formattedTime;
}

class Ticker {
  int lastTickTime = 0;
  final int interval;

  Ticker(this.interval);

  bool isStuck() {
    var now = DateTime.now().millisecondsSinceEpoch;
    var ret = now - lastTickTime > interval;
    if (ret) {
      lastTickTime = now;
      return false;
    } else {
      return true;
    }
  }
}

class Time {
  static double parseTimeToMilliseconds(String time) {
    List<String> p1 = time.split(':');
    List<String> p2 = p1[2].split(',');

    double hours = double.parse(p1[0]);
    double minutes = double.parse(p1[1]);
    double seconds = double.parse(p2[0]);
    double milliseconds = double.parse(p2[1]);
    var ret = (hours * 60 * 60 * 1000) + (minutes * 60 * 1000) + seconds * 1000 + milliseconds;
    return ret;
  }

  static String convertToString(Duration time) {
    int hours = time.inHours;
    int minutes = time.inMinutes % 60;
    int seconds = time.inSeconds % 60;
    int milliseconds = time.inMilliseconds % 1000;

    return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')},${milliseconds.toString().padLeft(3, '0')}";
  }

  static String extend(String time, int extendMilliseconds, Duration max) {
    Duration end = Duration(milliseconds: parseTimeToMilliseconds(time).toInt() + extendMilliseconds);
    if (end > max) {
      end = max;
    }
    return convertToString(end);
  }
}
