import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:video_player/video_player.dart';

typedef SetMaskRatioCallback = void Function(double height);
typedef GetVpc = VideoPlayerController? Function();

class VideoMask extends StatefulWidget {
  final GetVpc getVpc;
  final double initMaskHeight;
  final double initMaskRatio;
  final SetMaskRatioCallback? setMaskHeight;

  const VideoMask(
    this.getVpc,
    this.initMaskHeight,
    this.initMaskRatio,
    this.setMaskHeight, {
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

  void refresh() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    var videoPlayer = widget.getVpc();
    Color maskColor = Colors.black;
    if (Get.context != null) {
      maskColor = Theme.of(Get.context!).brightness == Brightness.dark ? maskColor = Colors.black : Colors.white;
    }
    if (videoPlayer != null && videoPlayer.value.isInitialized) {
      var video = videoPlayer.value;
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
                  child: VideoPlayer(videoPlayer),
                ),
                if (widget.initMaskHeight > 0)
                  SizedBox(
                    height: widget.initMaskHeight,
                    child: Container(
                      width: double.infinity,
                      color: maskColor,
                    ),
                  ),
                if (widget.initMaskRatio > 0)
                  AspectRatio(
                    aspectRatio: video.aspectRatio * maskRatio,
                    child: Container(
                      width: double.infinity,
                      color: maskColor,
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
          ],
        ),
      );
    }
    return Container();
  }
}
