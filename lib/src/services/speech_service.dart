import 'package:flutter_tts/flutter_tts.dart';

class SpeechService {
  SpeechService() {
    _tts.setLanguage('en-US');
    _tts.setSpeechRate(0.46);
    _tts.setPitch(1.0);
  }

  final FlutterTts _tts = FlutterTts();

  Future<void> speak(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return;
    }
    await _tts.stop();
    await _tts.speak(trimmed);
  }

  Future<void> stop() async {
    await _tts.stop();
  }
}
