class GsCrContentTemplateState {
  final List<String> items = <String>[];
  int bookId = 0;
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
