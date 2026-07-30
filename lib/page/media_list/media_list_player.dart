import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

import 'media_item.dart';

/// Playback mode, cycled by a single button in this order:
/// shuffle -> repeatOne -> repeatAll -> sequential -> shuffle ...
///
/// [repeatAll] loops the whole list: stepping past either end wraps around to
/// the other end instead of stopping.
enum PlayMode { shuffle, repeatOne, repeatAll, sequential }

/// Continuous, Spotify-like player over a list of [MediaItem]s. Audio and video
/// auto-advance on completion; images stay for [imageSeconds] seconds and then
/// advance. Missing or unsupported items are skipped.
class MediaPlayerScreen extends StatefulWidget {
  static const int imageSeconds = 3;

  final List<MediaItem> items;
  final int startIndex;

  const MediaPlayerScreen({
    Key? key,
    required this.items,
    required this.startIndex,
  }) : super(key: key);

  @override
  State<MediaPlayerScreen> createState() => _MediaPlayerScreenState();
}

class _MediaPlayerScreenState extends State<MediaPlayerScreen> {
  int _index = 0;
  bool _isPlaying = false;

  AudioPlayer? _audio;
  StreamSubscription<PlayerState>? _audioStateSub;
  StreamSubscription<Duration>? _audioPosSub;
  StreamSubscription<Duration?>? _audioDurSub;

  VideoPlayerController? _video;
  Timer? _imageTimer;

  Duration _pos = Duration.zero;
  Duration _dur = Duration.zero;
  bool _advancing = false;

  PlayMode _mode = PlayMode.sequential;
  bool _controlsVisible = true;
  final Random _rng = Random();

  MediaItem? get _current => (_index >= 0 && _index < widget.items.length) ? widget.items[_index] : null;

  @override
  void initState() {
    super.initState();
    // Fullscreen immersive: hide the system status/navigation bars while this
    // player is on screen. Restored in dispose().
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    WakelockPlus.enable();
    final start = _nextPlayable(widget.startIndex, 1) ?? _nextPlayable(widget.startIndex, -1);
    if (start == null) {
      _index = widget.startIndex;
    } else {
      _index = start;
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
  }

  int? _nextPlayable(int from, int dir) {
    var i = from;
    while (i >= 0 && i < widget.items.length) {
      final it = widget.items[i];
      if (it.exists && it.kind != MediaKind.unknown) {
        return i;
      }
      i += dir;
    }
    return null;
  }

  /// A random playable index, preferring one other than the current item.
  /// When the current item is the only playable one, replay it so shuffle
  /// keeps going.
  int? _randomPlayable() {
    final candidates = <int>[];
    for (var i = 0; i < widget.items.length; i++) {
      final it = widget.items[i];
      if (it.exists && it.kind != MediaKind.unknown) candidates.add(i);
    }
    if (candidates.isEmpty) return null;
    candidates.remove(_index);
    if (candidates.isEmpty) return _index;
    return candidates[_rng.nextInt(candidates.length)];
  }

  Future<void> _disposeCurrent() async {
    _imageTimer?.cancel();
    _imageTimer = null;

    // Null out the fields that build() reads BEFORE awaiting any disposal.
    // VideoPlayerController.value.isInitialized stays true after dispose(), so
    // if _video still pointed at a disposed controller during the dispose
    // await, a rebuild would hand VideoPlayer a playerId whose native player is
    // already gone -> StateError('No active player with ID ...').
    final audioStateSub = _audioStateSub;
    final audioPosSub = _audioPosSub;
    final audioDurSub = _audioDurSub;
    _audioStateSub = null;
    _audioPosSub = null;
    _audioDurSub = null;

    final audio = _audio;
    _audio = null;

    final video = _video;
    _video = null;

    await audioStateSub?.cancel();
    await audioPosSub?.cancel();
    await audioDurSub?.cancel();
    await audio?.dispose();

    video?.removeListener(_videoListener);
    await video?.dispose();
  }

  Future<void> _load() async {
    _advancing = false;
    await _disposeCurrent();
    if (!mounted) return;
    setState(() {
      _pos = Duration.zero;
      _dur = Duration.zero;
      _isPlaying = false;
    });

    final item = _current;
    if (item == null) return;

    if (!item.exists || item.kind == MediaKind.unknown) {
      _advance(1);
      return;
    }

    switch (item.kind) {
      case MediaKind.audio:
        await _loadAudio(item);
        break;
      case MediaKind.video:
        await _loadVideo(item);
        break;
      case MediaKind.image:
        _loadImage();
        break;
      case MediaKind.unknown:
        _advance(1);
        break;
    }
  }

  Future<void> _loadAudio(MediaItem item) async {
    try {
      final audio = AudioPlayer();
      _audio = audio;
      await audio.setFilePath(item.localPath);
      if (!identical(_audio, audio)) return; // superseded by another load
      _audioStateSub = audio.playerStateStream.listen((s) {
        // Drive the play/pause icon from the player itself: AudioPlayer.play()
        // returns a future that only completes when playback finishes or is
        // paused, so it can never be awaited to learn that playback started.
        if (mounted && _isPlaying != s.playing) {
          setState(() => _isPlaying = s.playing);
        }
        if (s.processingState == ProcessingState.completed) {
          _onComplete();
        }
      });
      _audioPosSub = audio.positionStream.listen((p) {
        if (mounted) setState(() => _pos = p);
      });
      _audioDurSub = audio.durationStream.listen((d) {
        if (mounted && d != null) setState(() => _dur = d);
      });
      // Not awaited on purpose: see the playerStateStream listener above.
      audio.play();
      if (mounted) setState(() => _isPlaying = true);
    } catch (e) {
      Snackbar.show("Error loading audio: $e");
      _advance(1);
    }
  }

  Future<void> _loadVideo(MediaItem item) async {
    try {
      final video = VideoPlayerController.file(File(item.localPath));
      _video = video;
      await video.initialize();
      if (!identical(_video, video)) return; // superseded
      _dur = video.value.duration;
      video.addListener(_videoListener);
      await video.play();
      if (mounted) setState(() => _isPlaying = true);
    } catch (e) {
      Snackbar.show("Error loading video: $e");
      _advance(1);
    }
  }

  void _loadImage() {
    setState(() => _isPlaying = true);
    _imageTimer = Timer(const Duration(seconds: MediaPlayerScreen.imageSeconds), _onComplete);
  }

  void _videoListener() {
    final v = _video;
    if (v == null || !v.value.isInitialized) return;
    if (mounted) {
      setState(() {
        _pos = v.value.position;
        _dur = v.value.duration;
        _isPlaying = v.value.isPlaying;
      });
    }
    if (v.value.duration > Duration.zero && v.value.position >= v.value.duration && !v.value.isPlaying) {
      _onComplete();
    }
  }

  /// Called when the current item finishes playing on its own.
  /// In repeat-one it replays the current item; otherwise it advances.
  void _onComplete() {
    if (_mode == PlayMode.repeatOne) {
      _replayCurrent();
    } else {
      _advance(1);
    }
  }

  void _replayCurrent() {
    final item = _current;
    if (item == null) return;
    switch (item.kind) {
      case MediaKind.audio:
        _audio?.seek(Duration.zero);
        _audio?.play();
        if (mounted) setState(() => _isPlaying = true);
        break;
      case MediaKind.video:
        _video?.seekTo(Duration.zero);
        _video?.play();
        if (mounted) setState(() => _isPlaying = true);
        break;
      case MediaKind.image:
        _imageTimer?.cancel();
        _imageTimer = Timer(const Duration(seconds: MediaPlayerScreen.imageSeconds), _onComplete);
        if (mounted) setState(() => _isPlaying = true);
        break;
      case MediaKind.unknown:
        break;
    }
  }

  void _advance(int dir) {
    if (_advancing) return;
    _advancing = true;
    var next = _mode == PlayMode.shuffle ? _randomPlayable() : _nextPlayable(_index + dir, dir);
    if (next == null && _mode == PlayMode.repeatAll) {
      // Wrap around: restart the scan from the opposite end of the list.
      next = dir > 0 ? _nextPlayable(0, 1) : _nextPlayable(widget.items.length - 1, -1);
    }
    if (next == null) {
      // No playable item in this direction: stay on the current item and keep
      // it visible. Do NOT dispose the player here - disposing nulls _video,
      // which would leave a video item stuck showing an endless spinner.
      _pauseCurrent();
      _advancing = false;
      return;
    }
    _index = next;
    _load();
  }

  void _pauseCurrent() {
    _imageTimer?.cancel();
    _imageTimer = null;
    _audio?.pause();
    _video?.pause();
    if (mounted) setState(() => _isPlaying = false);
  }

  Future<void> _togglePlay() async {
    final item = _current;
    if (item == null) return;
    switch (item.kind) {
      case MediaKind.audio:
        if (_audio == null) return;
        if (_isPlaying) {
          await _audio!.pause();
          if (mounted) setState(() => _isPlaying = false);
        } else {
          // Not awaited: play() only completes when playback ends/pauses.
          _audio!.play();
          if (mounted) setState(() => _isPlaying = true);
        }
        break;
      case MediaKind.video:
        if (_video == null) return;
        if (_isPlaying) {
          await _video!.pause();
          setState(() => _isPlaying = false);
        } else {
          await _video!.play();
          setState(() => _isPlaying = true);
        }
        break;
      case MediaKind.image:
        if (_isPlaying) {
          _imageTimer?.cancel();
          setState(() => _isPlaying = false);
        } else {
          _imageTimer = Timer(const Duration(seconds: MediaPlayerScreen.imageSeconds), _onComplete);
          setState(() => _isPlaying = true);
        }
        break;
      case MediaKind.unknown:
        break;
    }
  }

  @override
  void dispose() {
    // Restore the system bars for the rest of the app.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge, overlays: SystemUiOverlay.values);
    WakelockPlus.disable();
    _disposeCurrent();
    super.dispose();
  }

  Widget _buildMedia() {
    final item = _current;
    if (item == null) {
      return Center(child: Text(I18nKey.mediaEmpty.tr));
    }
    switch (item.kind) {
      case MediaKind.video:
        if (_video != null && _video!.value.isInitialized) {
          return Center(
            child: AspectRatio(
              aspectRatio: _video!.value.aspectRatio,
              child: VideoPlayer(_video!),
            ),
          );
        }
        return const Center(child: CircularProgressIndicator());
      case MediaKind.image:
        return Center(
          child: Image.file(File(item.localPath), fit: BoxFit.contain),
        );
      case MediaKind.audio:
        return const Center(child: Icon(Icons.audiotrack, size: 120, color: Colors.grey));
      case MediaKind.unknown:
        return const Center(child: Icon(Icons.help_outline, size: 120, color: Colors.grey));
    }
  }

  Widget _buildProgress() {
    final item = _current;
    if (item == null || item.kind == MediaKind.image || item.kind == MediaKind.unknown) {
      return const SizedBox(height: 0);
    }
    final total = _dur.inMilliseconds;
    final value = total > 0 ? _pos.inMilliseconds.clamp(0, total).toDouble() : 0.0;
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 2.5,
        activeTrackColor: Colors.white,
        inactiveTrackColor: Colors.white24,
        thumbColor: Colors.white,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
      ),
      child: Slider(
        min: 0,
        max: total > 0 ? total.toDouble() : 1,
        value: total > 0 ? value : 0,
        onChanged: total > 0
            ? (v) {
                final target = Duration(milliseconds: v.toInt());
                setState(() => _pos = target);
                if (item.kind == MediaKind.audio) {
                  _audio?.seek(target);
                } else if (item.kind == MediaKind.video) {
                  _video?.seekTo(target);
                }
              }
            : null,
      ),
    );
  }

  static String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return h > 0 ? '${two(h)}:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  }

  void _cycleMode() {
    setState(() {
      _mode = PlayMode.values[(_mode.index + 1) % PlayMode.values.length];
    });
  }

  IconData _modeIcon() {
    switch (_mode) {
      case PlayMode.shuffle:
        return Icons.shuffle;
      case PlayMode.repeatOne:
        return Icons.repeat_one;
      case PlayMode.repeatAll:
        return Icons.repeat;
      case PlayMode.sequential:
        return Icons.playlist_play;
    }
  }

  Color _modeColor() {
    switch (_mode) {
      case PlayMode.shuffle:
        return Colors.lightBlueAccent;
      case PlayMode.repeatOne:
        return Colors.redAccent;
      case PlayMode.repeatAll:
        return Colors.greenAccent;
      case PlayMode.sequential:
        return Colors.white;
    }
  }

  Widget _barIcon(IconData icon, {double size = 28, Color color = Colors.white, VoidCallback? onTap}) {
    return IconButton(
      iconSize: size,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      constraints: const BoxConstraints(),
      color: color,
      icon: Icon(icon),
      onPressed: onTap,
    );
  }

  Widget _buildTopBar() {
    final item = _current;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withOpacity(0.6), Colors.black.withOpacity(0.0)],
        ),
      ),
      padding: const EdgeInsets.only(bottom: 24),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: Text(
                '${item?.displayName ?? I18nKey.mediaList.tr}  (${_index + 1}/${widget.items.length})',
                style: const TextStyle(color: Colors.white, fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildControlBar() {
    final item = _current;
    final hasTime = item != null && item.kind != MediaKind.image && item.kind != MediaKind.unknown;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black.withOpacity(0.75), Colors.black.withOpacity(0.0)],
        ),
      ),
      padding: const EdgeInsets.only(top: 28),
      child: SafeArea(
        top: false,
        child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildProgress(),
          Padding(
            padding: const EdgeInsets.only(left: 4, right: 12, bottom: 6),
            child: Row(
              children: [
                _barIcon(_modeIcon(), color: _modeColor(), onTap: _cycleMode),
                _barIcon(Icons.fast_rewind, onTap: () => _advance(-1)),
                _barIcon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  size: 40,
                  onTap: _togglePlay,
                ),
                _barIcon(Icons.fast_forward, onTap: () => _advance(1)),
                const Spacer(),
                if (hasTime)
                  Text(
                    '${_fmt(_pos)} / ${_fmt(_dur)}',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }

  void _toggleControls() {
    setState(() => _controlsVisible = !_controlsVisible);
  }

  Widget _fadeBar({required Widget child}) {
    return AnimatedOpacity(
      opacity: _controlsVisible ? 1 : 0,
      duration: const Duration(milliseconds: 200),
      child: IgnorePointer(ignoring: !_controlsVisible, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _toggleControls,
              child: _buildMedia(),
            ),
          ),
          Positioned(top: 0, left: 0, right: 0, child: _fadeBar(child: _buildTopBar())),
          Positioned(left: 0, right: 0, bottom: 0, child: _fadeBar(child: _buildControlBar())),
        ],
      ),
    );
  }
}
