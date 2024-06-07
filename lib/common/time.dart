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
