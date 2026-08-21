import 'package:flutter_test/flutter_test.dart';
import 'package:repeat_flutter/logic/srt_parse.dart';

void main() {
  test('listen mode (l): parses qStart/qEnd/q and pads/splits gaps', () {
    const srt = '''
l
1
00:00:10,000 --> 00:00:12,000
Hello world

2
00:00:13,000 --> 00:00:15,000
Second line
''';
    final segments = SrtParse.parse(srt);
    expect(segments.length, 2);

    expect(segments[0].q, 'Hello world');
    expect(segments[0].qStart, '00:00:09,500');
    expect(segments[0].qEnd, '00:00:12,450');

    expect(segments[1].q, 'Second line');
    expect(segments[1].qStart, '00:00:12,550');
    expect(segments[1].qEnd, '00:00:15,500');
  });

  test('listen full mode (lf): pads head, makes ranges gapless forward-only', () {
    const srt = '''
lf
1
00:00:20,000 --> 00:00:22,000
First

2
00:00:23,000 --> 00:00:25,000
Second
''';
    final segments = SrtParse.parse(srt);
    expect(segments.length, 2);

    expect(segments[0].q, 'First');
    expect(segments[0].qStart, '00:00:19,500');
    expect(segments[0].qEnd, '00:00:22,000');

    expect(segments[1].q, 'Second');
    expect(segments[1].qStart, '00:00:22,500');
    expect(segments[1].qEnd, '00:00:25,500');
  });

  test('listen mode: multi-line question text is joined until blank line', () {
    const srt = '''
l
1
00:00:01,000 --> 00:00:02,000
line one
line two
''';
    final segments = SrtParse.parse(srt);
    expect(segments.length, 1);
    expect(segments[0].q, 'line one line two');
  });

  test('timeRangeToMillis / millisToTimeRange round-trip', () {
    expect(SrtParse.timeRangeToMillis('01:02:03,456'), 3723456);
    expect(SrtParse.millisToTimeRange(3723456), '01:02:03,456');
  });
}
