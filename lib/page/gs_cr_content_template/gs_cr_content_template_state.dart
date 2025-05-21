import 'package:repeat_flutter/logic/base/constant.dart';

class GsCrContentTemplateState {
  final List<String> items = <String>[];
  int contentId = 0;
  int contentSerial = 0;
  static const String prefixTemplate = '{"v":"';
  static const String suffixTemplate = '",\n'
      ' "l": [\n'
      '    {\n'
      '      "s": [\n'
      '        {"a":"1"}\n'
      '      ]\n'
      '    }\n'
      '  ]\n'
      '}';
}
