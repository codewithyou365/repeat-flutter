import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PlayerBar extends StatefulWidget {
  final int? index;
  final List<Line> lines;
  final String path;

  PlayerBar(this.index, this.lines, this.path, {super.key});

  @override
  PlayerBarState createState() => PlayerBarState();
}

const double factor = 0.06;

class PlayerBarState extends State<PlayerBar> with SingleTickerProviderStateMixin {
  int startTime = 0;
  double _offset = 0.0;
  double _previousOffset = 0.0;
  final player = AudioPlayer();
  int? startIndex;
  late AnimationController _controller;

  PlayerBarState();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _controller.addListener(() {
      var offset = (startTime - DateTime.now().millisecondsSinceEpoch) * factor;
      setState(() {
        _offset = offset;
      });
    });
  }

  stopAutoMove() {
    player.stop();
  }

  autoMove({offset = 0}) {
    if (widget.path.isEmpty || widget.lines.isEmpty || widget.index == null) {
      return;
    }
    if (offset != 0) {
      _offset = offset;
    }
    var currOffset = _offset ~/ factor;
    var duration = -1.0;

    for (int i = 0; i < widget.lines.length && duration < 0; i++) {
      duration = widget.lines[i].end - widget.lines[0].start + currOffset;
    }
    if (duration < 0) {
      duration = 3000;
      currOffset = (duration + widget.lines[0].start - widget.lines[widget.lines.length - 1].end).toInt();
    }

    _controller.reset();
    _controller.animateTo(100, duration: Duration(milliseconds: duration.toInt())).then((value) => {player.pause()});
    if (player.state == PlayerState.paused) {
      player.resume();
      player.seek(Duration(milliseconds: widget.lines[0].start.toInt() - currOffset));
    } else if (player.state == PlayerState.stopped) {
      player.play(DeviceFileSource(widget.path));
      player.seek(Duration(milliseconds: widget.lines[0].start.toInt() - currOffset));
    } else if (player.state == PlayerState.playing) {
    } else {
      print("error state");
      return;
    }
    print(_offset.toInt());
    startTime = DateTime.now().millisecondsSinceEpoch + currOffset;
    player.seek(Duration(milliseconds: widget.lines[0].start.toInt() - currOffset));
  }

  @override
  void dispose() {
    _controller.dispose();
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (startIndex == null || startIndex != widget.index) {
      if (widget.path.isNotEmpty && widget.lines.isNotEmpty && widget.index != null) {
        autoMove(offset: (widget.lines[0].start.toInt() - widget.lines[widget.index!].start.toInt()) * factor);
        startIndex = widget.index;
      }
    }
    return GestureDetector(
      onHorizontalDragStart: (details) {
        _previousOffset = details.localPosition.dx;
        _controller.stop(canceled: false);
        player.pause();
      },
      onHorizontalDragEnd: (details) {
        autoMove();
      },
      onHorizontalDragUpdate: (details) {
        double currentOffset = details.localPosition.dx;
        double delta = currentOffset - _previousOffset;
        setState(() {
          _offset += delta;
          _previousOffset = currentOffset;
        });
      },
      child: CustomPaint(
        size: Size(360.w, 100.w),
        painter: PlayerBarPainter(_offset, widget.lines),
      ),
    );
  }
}

class Line {
  final double start;
  final double end;

  final double blockStart;
  final double blockEnd;

  Line(this.start, this.end, this.blockStart, this.blockEnd);

  static Line toLine(String startTime, String endTime) {
    double startSeconds = parseTimeToSeconds(startTime);
    double endSeconds = parseTimeToSeconds(endTime);
    return Line(startSeconds, endSeconds, startSeconds * factor, endSeconds * factor);
  }

  static double parseTimeToSeconds(String time) {
    List<String> p1 = time.split(':');
    List<String> p2 = p1[1].split('.');

    double minutes = double.parse(p1[0]);
    double seconds = double.parse(p2[0]);
    double milliseconds = double.parse(p2[1]);
    var ret = (minutes * 60 * 1000) + seconds * 1000 + milliseconds * 10;
    return ret;
  }
}

class PlayerBarPainter extends CustomPainter {
  final List<Line> lines;
  final double offset;
  late final Paint centerLine;
  late final Paint contentLine;

  PlayerBarPainter(this.offset, this.lines) {
    centerLine = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 30.0.w;
    contentLine = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double centerY = size.height / 2;
    final double centerX = size.width / 2;
    canvas.drawLine(
      Offset(centerX, 0),
      Offset(centerX, size.height),
      contentLine,
    );
    var startOffset = 0.0;
    if (lines.isNotEmpty) {
      startOffset = -lines[0].blockStart;
    }
    for (final line in lines) {
      final double startX = line.blockStart + offset + centerX + startOffset;
      final double endX = line.blockEnd + offset + centerX + startOffset;

      canvas.drawLine(
        Offset(startX, centerY),
        Offset(endX, centerY),
        centerLine,
      );
    }
  }

  @override
  bool shouldRepaint(covariant PlayerBarPainter oldDelegate) {
    return !listEquals(lines, oldDelegate.lines) || offset != oldDelegate.offset;
  }
}
