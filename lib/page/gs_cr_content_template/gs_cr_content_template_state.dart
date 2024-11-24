class GsCrContentTemplateState {
  final List<String> items = <String>[];
  static const String defaultUrl = 'http://127.0.0.1:40321/';
  static const String prefixTemplate = '{\n'
      '  "rootPath": "{path.0}",\n'
      '  "key": "{path.0}",\n'
      '  "lesson": [\n'
      '    {\n'
      '      "url": "{path.1}.{file.extension}",\n'
      '      "path": "{path.1}.{file.extension}",\n'
      '      "hash": "{file.hash}",\n'
      '      "key": "{path.1}",\n'
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
  static const String aTemplate = ''
      '        {\n'
      '          "aStart": "00:00:05,000",\n'
      '          "aEnd": "00:00:10,000"\n'
      '        }';
  static const String qaTemplate = ''
      '        {\n'
      '          "qStart": "00:00:05,000",\n'
      '          "qEnd": "00:00:10,000",\n'
      '          "aStart": "00:00:15,000",\n'
      '          "aEnd": "00:00:20,000"\n'
      '        }';
}
