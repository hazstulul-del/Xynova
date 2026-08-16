import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceService {
  final stt.SpeechToText _speech = stt.SpeechToText();

  Future<bool> initialize() => _speech.initialize();

  bool get isListening => _speech.isListening;

  Future<void> listen({
    required void Function(String text) onResult,
    required void Function(bool listening) onState,
    String? localeId,
  }) async {
    final ok = await _speech.initialize();
    if (!ok) {
      onState(false);
      return;
    }
    await _speech.listen(
      localeId: localeId,
      onResult: (result) => onResult(result.recognizedWords),
    );
    onState(true);
  }

  Future<void> stop(void Function(bool) onState) async {
    await _speech.stop();
    onState(false);
  }
}
