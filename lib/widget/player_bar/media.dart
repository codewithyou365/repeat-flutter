import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'video_mask.dart';

class MediaCache {
  String path;
  AudioPlayer? audioPlayer;
  VideoPlayerController? videoPlayer;

  MediaCache(this.path, {this.audioPlayer, this.videoPlayer});
}

mixin Media {
  static Map<String, MediaCache> playerIdToMediaCache = {};

  bool video = false;
  String key = "";

  AudioPlayer? audioPlayer;
  VideoPlayerController? videoPlayer;

  Future<void> mediaInit(String path, String playerId) async {
    if (path.endsWith("mp4")) {
      video = true;
    }
    key = playerId;
    if (video) {
      if (playerIdToMediaCache.containsKey(key)) {
        var cache = playerIdToMediaCache[key]!;
        if (cache.path != path) {
          await cache.videoPlayer!.dispose();
          videoPlayer = VideoPlayerController.file(File(path));
          await videoPlayer!.initialize();
          playerIdToMediaCache[key] = MediaCache(path, videoPlayer: videoPlayer);
        } else {
          videoPlayer = cache.videoPlayer;
        }
      } else {
        videoPlayer = VideoPlayerController.file(File(path));
        await videoPlayer!.initialize();
        playerIdToMediaCache[key] = MediaCache(path, videoPlayer: videoPlayer);
      }
    } else {
      if (playerIdToMediaCache.containsKey(key)) {
        var cache = playerIdToMediaCache[key]!;
        audioPlayer = cache.audioPlayer;
        if (cache.path != path) {
          cache.path = path;
          await audioPlayer!.setSource(DeviceFileSource(path));
        }
      } else {
        audioPlayer = AudioPlayer(playerId: playerId);
        await audioPlayer!.setSource(DeviceFileSource(path));
        playerIdToMediaCache[key] = MediaCache(path, audioPlayer: audioPlayer);
      }
    }
  }

  mediaStop() async {
    if (video) {
      await videoPlayer!.pause();
    } else {
      await audioPlayer!.pause();
    }
  }

  Future<void> mediaPlayAndSeek(Duration position) async {
    if (video) {
      await videoPlayer!.seekTo(position);
      await videoPlayer!.play();
    } else {
      await audioPlayer!.seek(position);
      await audioPlayer!.resume();
    }
  }

  mediaDispose() {
    playerIdToMediaCache.remove(key);
    if (video) {
      videoPlayer!.dispose();
    } else {
      audioPlayer!.dispose();
    }
  }

  Widget? mediaView(double initMaskRatio, SetMaskRatioCallback? setMaskRatio, VoidCallback? onFullScreen) {
    if (video) {
      return VideoMask(videoPlayer!, initMaskRatio, setMaskRatio, onFullScreen);
    } else {
      return null;
    }
  }
}
