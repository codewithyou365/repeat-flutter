import 'package:repeat_flutter/logic/base/constant.dart';

class GsCrContentTemplateState {
  final List<String> items = <String>[];
  int contentId = 0;
  int contentSerial = 0;
  static const String defaultUrl = Download.defaultUrl;
  static const String prefixTemplate = '{\n'
      '  "lesson": [\n'
      '    {\n'
      '      "mediaExtension": "{file.extension}",\n'
      '      "hash": "{file.hash}",\n'
      '      "defaultQuestion": "",\n'
      '      "defaultTip": "",\n'
      '      "title": " ",\n'
      '      "titleStart": "00:00:01,000",\n'
      '      "titleEnd": "00:00:05,000",\n'
      '      "segment": [\n';

  static const String suffixTemplate = '      ]\n'
      '    }\n'
      '  ]\n'
      '}';

  static const String qTemplate = '        {\n'
      '          "qStart": "00:00:05,000",\n'
      '          "qEnd": "00:00:10,000"\n'
      '        }';
  static const String qaTemplate = ''
      '        {\n'
      '          "qStart": "00:00:05,000",\n'
      '          "qEnd": "00:00:10,000",\n'
      '          "aStart": "00:00:15,000",\n'
      '          "aEnd": "00:00:20,000"\n'
      '        }';
}
