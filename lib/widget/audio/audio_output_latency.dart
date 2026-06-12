// AudioDeviceType is marked experimental in audio_session, but it is the
// only cross-platform way to identify the active Bluetooth output route.
// ignore_for_file: experimental_member_use

import 'dart:async';
import 'dart:io';

import 'package:audio_session/audio_session.dart';

/// Tracks the current audio output route and estimates how early an auto
/// pause must be issued (the stop lead): a pause takes a while to be heard on
/// a slow sink (command propagation, plus the sink draining what it already
/// buffered past the player's reported position), so pausing exactly at the
/// verse end overshoots into the next verse by that amount.
class AudioOutputLatency {
  /// Empirical stop lead for Bluetooth, used when the user hasn't tuned one
  /// and the platform can't report one. The player's reported position
  /// already includes most of the link latency, so this only covers pause
  /// propagation plus the sink's residual buffer.
  static const int defaultBluetoothMs = 100;

  int latencyMs = 0;
  int? _userStopLeadMs;
  int _autoMs = defaultBluetoothMs;
  bool _bluetoothActive = false;
  StreamSubscription<AudioDevicesChangedEvent>? _sub;

  /// The stop lead to show and tune, applied whenever Bluetooth is active.
  /// Increase it if the verse end bleeds into the next verse, decrease it if
  /// the verse end gets cut off.
  int get stopLeadMs => _userStopLeadMs ?? _autoMs;

  /// User-tuned stop lead; null falls back to the platform-reported or
  /// default value. The caller persists it.
  set userStopLeadMs(int? ms) {
    _userStopLeadMs = ms;
    _apply();
  }

  Future<void> init() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return;
    }
    try {
      final session = await AudioSession.instance;
      _sub ??= session.devicesChangedEventStream.listen((_) {
        _refresh(session);
      });
      await _refresh(session);
    } catch (_) {
      latencyMs = 0;
    }
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }

  void _apply() {
    latencyMs = _bluetoothActive ? stopLeadMs : 0;
  }

  Future<void> _refresh(AudioSession session) async {
    try {
      _bluetoothActive = await _hasBluetoothOutput(session);
      if (_bluetoothActive && Platform.isIOS) {
        final reported = (await AVAudioSession().outputLatency).inMilliseconds;
        if (reported > 0) {
          _autoMs = reported;
        }
      }
    } catch (_) {
      _bluetoothActive = false;
    }
    _apply();
  }

  Future<bool> _hasBluetoothOutput(AudioSession session) async {
    if (Platform.isAndroid) {
      // Query the raw Android device list: audio_session can't decode the LE
      // Audio device types (TYPE_BLE_* = 26/27/30) and reports them as
      // unknown, so the cross-platform AudioDeviceType check misses them.
      // Only Bluetooth sinks carry a MAC address (reported on API 28+).
      // Note: AndroidAudioManager() is the same singleton AudioSession uses
      // internally; do not call its setAudioDevices*Listener methods, or the
      // session's devicesChangedEventStream stops receiving events.
      final devices = await AndroidAudioManager().getDevices(AndroidGetAudioDevicesFlags.outputs);
      return devices.any((d) =>
          d.type == AndroidAudioDeviceType.bluetoothA2dp ||
          d.type == AndroidAudioDeviceType.bluetoothSco ||
          (d.type == AndroidAudioDeviceType.unknown && (d.address?.contains(':') ?? false)));
    }
    final devices = await session.getDevices(includeInputs: false);
    return devices.any((d) =>
        d.type == AudioDeviceType.bluetoothA2dp ||
        d.type == AudioDeviceType.bluetoothLe ||
        d.type == AudioDeviceType.bluetoothSco);
  }
}
