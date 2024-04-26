String formatHm(int milliseconds) {
  int hours = milliseconds ~/ 3600000;
  int remainingMinutes = (milliseconds % 3600000) ~/ 60000;
  String formattedTime = '$hours H $remainingMinutes M';
  return formattedTime;
}
