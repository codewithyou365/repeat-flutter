import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'player_bar.dart';
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

  Future<void> mediaInit(String path, String playerId) async {
    video = isVideo(path);
    key = playerId;
    if (video) {
      if (playerIdToMediaCache.containsKey(key)) {
        var cache = playerIdToMediaCache[key]!;
        if (cache.path != path) {
          await cache.videoPlayer!.dispose();
          var videoPlayer = VideoPlayerController.file(File(path));
          playerIdToMediaCache[key] = MediaCache(path, videoPlayer: videoPlayer);
          await videoPlayer.initialize();
        }
      } else {
        var videoPlayer = VideoPlayerController.file(File(path));
        playerIdToMediaCache[key] = MediaCache(path, videoPlayer: videoPlayer);
        await videoPlayer.initialize();
      }
    } else {
      if (playerIdToMediaCache.containsKey(key)) {
        var cache = playerIdToMediaCache[key]!;
        var audioPlayer = cache.audioPlayer;
        if (cache.path != path) {
          cache.path = path;
          await audioPlayer!.setSource(DeviceFileSource(path));
        }
      } else {
        var audioPlayer = AudioPlayer(playerId: playerId);
        await audioPlayer.setSource(DeviceFileSource(path));
        playerIdToMediaCache[key] = MediaCache(path, audioPlayer: audioPlayer);
      }
    }
  }

  mediaStop() async {
    if (video) {
      await playerIdToMediaCache[key]?.videoPlayer!.pause();
    } else {
      await playerIdToMediaCache[key]?.audioPlayer!.pause();
    }
  }

  Future<void> mediaPlayAndSeek(Duration position) async {
    if (video) {
      await playerIdToMediaCache[key]?.videoPlayer!.seekTo(position);
      await playerIdToMediaCache[key]?.videoPlayer!.play();
    } else {
      await playerIdToMediaCache[key]?.audioPlayer!.seek(position);
      await playerIdToMediaCache[key]?.audioPlayer!.resume();
    }
  }

  mediaDispose() {
    if (video) {
      playerIdToMediaCache[key]?.videoPlayer!.dispose();
    } else {
      playerIdToMediaCache[key]?.audioPlayer!.dispose();
    }
    playerIdToMediaCache.remove(key);
  }

  static Widget mediaView(PlayerBar playerBar, {Key? key}) {
    return VideoMask(() {
      var cache = playerIdToMediaCache[playerBar.playerId];
      if (cache == null) {
        return null;
      }
      if (isVideo(playerBar.path)) {
        return cache.videoPlayer;
      }
      return null;
    }, playerBar.initMaskRatio, playerBar.setMaskRatio, key: key);
  }

  static bool isVideo(String path) {
    return path.endsWith("mp4");
  }

  Future<Duration?> getMediaCurrentPosition() async {
    Duration? ret;
    if (video) {
      ret = await playerIdToMediaCache[key]?.videoPlayer!.position;
    } else {
      ret = await playerIdToMediaCache[key]?.audioPlayer!.getCurrentPosition();
    }
    return ret;
  }

  Future<Duration?> getMediaDuration() async {
    Duration? ret;
    if (video) {
      ret = playerIdToMediaCache[key]?.videoPlayer!.value.duration;
    } else {
      ret = await playerIdToMediaCache[key]?.audioPlayer!.getDuration();
    }
    return ret;
  }
}
