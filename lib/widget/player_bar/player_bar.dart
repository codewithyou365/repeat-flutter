import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PlayerBar extends StatefulWidget {
  final String playerId;
  final int? index;
  final List<MediaSegment> lines;
  final String path;
  final VoidCallback? onPrevious;
  final VoidCallback? onReplay;
  final VoidCallback? onNext;

  const PlayerBar(
    this.playerId,
    this.index,
    this.lines,
    this.path, {
    Key? key,
    this.onPrevious,
    this.onReplay,
    this.onNext,
  }) : super(key: key);

  @override
  PlayerBarState createState() => PlayerBarState();
}

const double factor = 0.06;

class PlayerBarState extends State<PlayerBar> with SingleTickerProviderStateMixin {
  int startTime = 0;
  double _offset = 0.0;
  double _previousOffset = 0.0;
  bool playing = true;
  int mediaStart = 0;
  int mediaEnd = 0;

  // TODO support video
  AudioPlayer? player;
  late AnimationController _controller;

  PlayerBarState();

  @override
  void initState() {
    super.initState();
    player = AudioPlayer(playerId: widget.playerId);
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

  stopMove() {
    _controller.stop();
    player!.pause();
    setState(() {
      playing = false;
    });
  }

  moveByIndex() {
    if (widget.path.isNotEmpty && widget.lines.isNotEmpty && widget.index != null) {
      mediaStart = widget.lines[0].start.toInt() - widget.lines[widget.index!].start.toInt();
      mediaEnd = widget.lines[0].start.toInt() - widget.lines[widget.index!].end.toInt();
      move(offset: mediaStart);
    }
  }

  move({int? offset, int? inc}) {
    if (widget.path.isEmpty || widget.lines.isEmpty || widget.index == null) {
      return;
    }
    var currOffset = 0;
    if (offset != null) {
      currOffset = offset;
    } else if (inc != null) {
      currOffset = _offset ~/ factor - inc;
      if (currOffset > mediaStart) {
        currOffset = mediaStart;
      } else if (currOffset < mediaEnd) {
        currOffset = mediaEnd + 200;
      }
    } else {
      currOffset = _offset ~/ factor;
    }
    var duration = -1.0;

    for (int i = 0; i < widget.lines.length && duration < 0; i++) {
      duration = widget.lines[i].end - widget.lines[0].start + currOffset;
    }
    if (duration < 0) {
      duration = 200;
      currOffset = (duration + widget.lines[0].start - widget.lines[widget.lines.length - 1].end).toInt();
    }

    _controller.reset();
    _controller.animateTo(100, duration: Duration(milliseconds: duration.toInt())).then((value) => {stopMove()});
    player!.play(DeviceFileSource(widget.path));
    playing = true;
    startTime = DateTime.now().millisecondsSinceEpoch + currOffset;
    player!.seek(Duration(milliseconds: widget.lines[0].start.toInt() - currOffset));
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    player!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onHorizontalDragStart: (details) {
            _previousOffset = details.localPosition.dx;
            stopMove();
          },
          onHorizontalDragEnd: (details) {
            move();
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
            size: Size(360.w, 50.w),
            painter: PlayerBarPainter(_offset, widget.lines),
          ),
        ),
        SizedBox(
          height: 50.w,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.replay_5),
                iconSize: 20.w,
                onPressed: () {
                  move(inc: -5000);
                },
              ),
              IconButton(
                icon: const Icon(Icons.replay),
                iconSize: 20.w,
                onPressed: () {
                  if (widget.onReplay != null) {
                    widget.onReplay!();
                  }
                  moveByIndex();
                },
              ),
              IconButton(
                icon: const Icon(Icons.forward_5),
                iconSize: 20.w,
                onPressed: () {
                  move(inc: 5000);
                },
              ),
              const Spacer(),
              if (widget.onPrevious != null)
                IconButton(
                  icon: const Icon(Icons.skip_previous),
                  iconSize: 20.w,
                  onPressed: () {
                    if (widget.onPrevious != null) {
                      widget.onPrevious!();
                    }
                    moveByIndex();
                  },
                ),
              IconButton(
                icon: playing ? const Icon(Icons.pause) : const Icon(Icons.play_arrow),
                iconSize: 20.w,
                onPressed: () {
                  if (playing) {
                    stopMove();
                  } else {
                    move();
                  }
                },
              ),
              if (widget.onNext != null)
                IconButton(
                  icon: const Icon(Icons.skip_next),
                  iconSize: 20.w,
                  onPressed: () {
                    if (widget.onNext != null) {
                      widget.onNext!();
                    }
                    moveByIndex();
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class MediaSegment {
  final double start;
  final double end;

  final double blockStart;
  final double blockEnd;

  MediaSegment(this.start, this.end, this.blockStart, this.blockEnd);

  static MediaSegment from(String startTime, String endTime) {
    double startSeconds = parseTimeToSeconds(startTime);
    double endSeconds = parseTimeToSeconds(endTime);
    return MediaSegment(startSeconds, endSeconds, startSeconds * factor, endSeconds * factor);
  }

  static double parseTimeToSeconds(String time) {
    List<String> p1 = time.split(':');
    List<String> p2 = p1[2].split(',');

    double hours = double.parse(p1[0]);
    double minutes = double.parse(p1[1]);
    double seconds = double.parse(p2[0]);
    double milliseconds = double.parse(p2[1]);
    var ret = (hours * 60 * 60 * 1000) + (minutes * 60 * 1000) + seconds * 1000 + milliseconds;
    return ret;
  }
}

class PlayerBarPainter extends CustomPainter {
  final List<MediaSegment> lines;
  final double offset;
  late final Paint centerLine;
  late final Paint contentLine;
  late final Paint gapLine;

  PlayerBarPainter(this.offset, this.lines) {
    centerLine = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    contentLine = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20.0.w;
    gapLine = Paint()
      ..color = Colors.blue
      ..strokeWidth = 1.0;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double lineWidth = 10.w;
    final double gapWidth = 10.w;
    final double totalWidth = lineWidth + gapWidth;

    final double centerY = size.height / 2;
    final double centerX = size.width / 2;
    canvas.drawLine(
      Offset(centerX, 0),
      Offset(centerX, size.height),
      centerLine,
    );
    var startOffset = 0.0;
    if (lines.isNotEmpty) {
      startOffset = -lines[0].blockStart;
    }
    double offsetStartX = 0;
    // TODO need to improve the performance, and to draw the playtime
    for (int i = 0; i < 999; i++, offsetStartX += totalWidth) {
      if (i.isOdd) {
        continue;
      }
      double startX = offsetStartX + offset;
      double endX = offsetStartX + offset + lineWidth;
      if (endX < 0) {
        continue;
      }
      if (startX > size.width) {
        break;
      }
      if (startX < 0) {
        startX = 0;
      }
      if (endX > size.width) {
        endX = size.width;
      }
      canvas.drawLine(
        Offset(startX, 0.w),
        Offset(endX, 0.w),
        gapLine,
      );
      canvas.drawLine(
        Offset(startX, size.height),
        Offset(endX, size.height),
        gapLine,
      );
    }

    // TODO need to improve the performance
    for (final line in lines) {
      double startX = line.blockStart + offset + centerX + startOffset;
      double endX = line.blockEnd + offset + centerX + startOffset;
      if (endX < 0) {
        continue;
      }
      if (startX > size.width) {
        break;
      }
      if (startX < 0) {
        startX = 0;
      }
      if (endX > size.width) {
        endX = size.width;
      }

      canvas.drawLine(
        Offset(startX, centerY),
        Offset(endX, centerY),
        contentLine,
      );
    }
  }

  @override
  bool shouldRepaint(covariant PlayerBarPainter oldDelegate) {
    return !listEquals(lines, oldDelegate.lines) || offset != oldDelegate.offset;
  }
}
