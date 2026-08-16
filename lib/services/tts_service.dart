import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    await _tts.stop();
    await _tts.setSpeechRate(0.48);
    await _tts.speak(text);
  }

  Future<void> stop() => _tts.stop();
}
