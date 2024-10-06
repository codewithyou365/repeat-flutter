import 'package:flutter/material.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:video_player/video_player.dart';

typedef SetMaskRatioCallback = void Function(double height);

class VideoMask extends StatefulWidget {
  final VideoPlayerController videoPlayer;
  final double initMaskRatio;
  final SetMaskRatioCallback? setMaskHeight;
  final VoidCallback? onFullScreen;

  const VideoMask(
    this.videoPlayer,
    this.initMaskRatio,
    this.setMaskHeight,
    this.onFullScreen, {
    Key? key,
  }) : super(key: key);

  @override
  VideoMaskState createState() => VideoMaskState();
}

class VideoMaskState extends State<VideoMask> {
  VideoMaskState();

  bool startSetting = false;
  double maskRatio = 0;
  double maskPreviousX = 0;
  double rawMaskHeight = 300;
  double lastRawMaskHeight = 0;

  @override
  void initState() {
    super.initState();
    maskRatio = widget.initMaskRatio;
    startSetting = false;
  }

  @override
  void didUpdateWidget(VideoMask oldWidget) {
    super.didUpdateWidget(oldWidget);
    maskRatio = widget.initMaskRatio;
    startSetting = false;
  }

  @override
  Widget build(BuildContext context) {
    var video = widget.videoPlayer.value;
    if (video.isInitialized) {
      return GestureDetector(
        onTap: () {
          if (widget.setMaskHeight != null && widget.initMaskRatio > 0) {
            startSetting = !startSetting;
          }
          setState(() {});
        },
        onHorizontalDragStart: (details) {
          maskPreviousX = details.localPosition.dx;
          lastRawMaskHeight = rawMaskHeight;
        },
        onHorizontalDragEnd: (details) {
          if (widget.setMaskHeight != null) {
            widget.setMaskHeight!(maskRatio);
          }
          startSetting = false;
          setState(() {});
        },
        onHorizontalDragUpdate: (details) {
          if (startSetting == false) {
            return;
          }
          var maskHeight = details.localPosition.dx - maskPreviousX + lastRawMaskHeight;
          if (maskHeight < 0) {
            maskHeight = 0;
          }
          if (maskHeight > 300) {
            maskHeight = 300;
          }
          rawMaskHeight = maskHeight;
          //0~300
          //1~21

          maskRatio = 1 + 20 * maskHeight / 300;
          setState(() {});
        },
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                AspectRatio(
                  aspectRatio: video.aspectRatio,
                  child: VideoPlayer(widget.videoPlayer),
                ),
                if (widget.initMaskRatio > 0)
                  AspectRatio(
                    aspectRatio: video.aspectRatio * maskRatio,
                    child: Container(
                      width: double.infinity,
                      color: Colors.black,
                    ),
                  ),
                if (widget.setMaskHeight != null && startSetting && widget.initMaskRatio > 0)
                  Text(
                    I18nKey.labelSetMaskTips.tr,
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).secondaryHeaderColor,
                    ),
                  ),
              ],
            ),
            if (widget.onFullScreen != null && startSetting)
              IconButton(
                icon: const Icon(Icons.fullscreen),
                onPressed: widget.onFullScreen,
              ),
          ],
        ),
      );
    }
    return Container();
  }
}
