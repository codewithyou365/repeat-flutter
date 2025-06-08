class GsCrContentTemplateState {
  final List<String> items = <String>[];
  int contentId = 0;
  int bookSerial = 0;
  static const String prefixTemplate = '{"s":"';
  static const String suffixTemplate = '",\n'
      ' "c": [\n'
      '    {\n'
      '      "v": [\n'
      '        {"a":"1"}\n'
      '      ]\n'
      '    }\n'
      '  ]\n'
      '}';
}
