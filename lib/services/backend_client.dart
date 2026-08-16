import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/chat_models.dart';

class BackendEvent {
  final String type;
  final String? text;
  final String? message;
  const BackendEvent(this.type, {this.text, this.message});
}

class BackendClient {
  final String baseUrl;
  BackendClient({String? baseUrl})
      : baseUrl = (baseUrl ?? const String.fromEnvironment('BASE44_FUNCTION_URL')).trim();

  bool get configured => baseUrl.isNotEmpty;

  Stream<BackendEvent> streamChat({
    required String message,
    required List<ChatMessage> conversation,
    required String selectedModel,
    required List<ChatAttachment> attachments,
    required String language,
    required String requestId,
  }) async* {
    if (!configured) {
      yield const BackendEvent(
        'error',
        message: 'Backend AI belum dikonfigurasi. Set BASE44_FUNCTION_URL terlebih dahulu.',
      );
      return;
    }

    final request = http.Request('POST', Uri.parse(baseUrl));
    request.headers.addAll({
      'Content-Type': 'application/json',
      'Accept': 'text/event-stream, application/x-ndjson, application/json',
      'X-Xynova-Request-Id': requestId,
    });
    request.body = jsonEncode({
      'message': message,
      'conversation': conversation.map((e) => e.toJson()).toList(),
      'selectedModel': selectedModel,
      'attachments': attachments.map((e) => e.toJson()).toList(),
      'language': language,
    });

    try {
      final response = await request.send();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final body = await response.stream.bytesToString();
        yield BackendEvent('error', message: _friendlyError(response.statusCode, body));
        return;
      }

      var buffer = '';
      await for (final bytes in response.stream) {
        buffer += utf8.decode(bytes, allowMalformed: true);
        final lines = buffer.split('\n');
        buffer = lines.removeLast();

        for (final raw in lines) {
          final line = raw.trim();
          if (line.isEmpty) continue;
          final payload = line.startsWith('data:') ? line.substring(5).trim() : line;
          if (payload == '[DONE]') {
            yield const BackendEvent('done');
            continue;
          }
          try {
            final json = jsonDecode(payload);
            if (json is Map) {
              final type = json['type'] as String? ?? 'token';
              yield BackendEvent(
                type,
                text: json['text'] as String?,
                message: json['message'] as String?,
              );
            }
          } catch (_) {
            // Ignore malformed individual stream lines; do not crash the chat.
          }
        }
      }
      if (buffer.trim().isNotEmpty) {
        final line = buffer.trim();
        final payload = line.startsWith('data:') ? line.substring(5).trim() : line;
        try {
          final json = jsonDecode(payload);
          if (json is Map) {
            yield BackendEvent(
              json['type'] as String? ?? 'token',
              text: json['text'] as String?,
              message: json['message'] as String?,
            );
          }
        } catch (_) {}
      }
    } on TimeoutException {
      yield const BackendEvent('error', message: 'Request terlalu lama. Silakan coba lagi.');
    } catch (_) {
      yield const BackendEvent('error', message: 'Koneksi ke Xynova gagal. Silakan coba lagi.');
    }
  }

  String _friendlyError(int status, String body) {
    if (status == 401 || status == 403) return 'AI provider authentication failed.';
    if (status == 404) return 'Model ini sedang tidak tersedia.';
    if (status == 408) return 'Request terlalu lama. Silakan coba lagi.';
    if (status == 429) return 'Provider sedang sibuk. Silakan coba lagi.';
    if (status >= 500) return 'Maaf, Xynova sedang mengalami gangguan. Silakan coba lagi.';
    return body.isNotEmpty ? 'Request gagal. Silakan coba lagi.' : 'Request gagal.';
  }

  Uint8List decodeBase64(String value) => base64Decode(value);
}
