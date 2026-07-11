import 'package:audioplayers/audioplayers.dart';

class RingtoneHelper {
  RingtoneHelper._();

  static final AudioPlayer _player = AudioPlayer();

  static bool _isPlaying = false;

  static Future<void> play() async {
    if (_isPlaying) return;

    _isPlaying = true;

    await _player.setReleaseMode(ReleaseMode.loop);

    await _player.play(AssetSource('audio/hsh_call.mp3'));
  }

  static Future<void> stop() async {
    if (!_isPlaying) return;

    _isPlaying = false;

    await _player.stop();
  }

  static Future<void> dispose() async {
    await _player.dispose();
  }
}
