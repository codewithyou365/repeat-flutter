import 'package:logger/logger.dart';

var logger = Logger(
  printer: PrettyPrinter(),
);

class Snackbar {
  static int finishCount = 0;

  static show(String content) {
    logger.d(content);
  }
}
