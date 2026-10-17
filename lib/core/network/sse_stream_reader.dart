import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_endpoints.dart';
import '../storage/secure_storage_service.dart';

class SSEStreamReader {
  http.Client? _client;

  Future<void> streamChat({
    required Map<String, dynamic> body,
    required void Function(String chunk) onChunk,
    required void Function() onDone,
    required void Function(String error) onError,
  }) async {
    _client = http.Client();
    try {
      final token = await SecureStorageService.getToken();
      final uri = Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.chatStream}');

      final request = http.Request('POST', uri)
        ..headers['Content-Type'] = 'application/json'
        ..headers['Accept'] = 'text/event-stream'
        ..body = jsonEncode(body);

      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      final response = await _client!.send(request);

      if (response.statusCode != 200) {
        final errorBody = await response.stream.bytesToString();
        String errorMsg = 'Stream error: ${response.statusCode}';
        try {
          final parsed = jsonDecode(errorBody);
          if (parsed['error'] != null) {
            errorMsg = parsed['error'].toString();
          }
        } catch (_) {}
        onError(errorMsg);
        return;
      }

      // Stream decoder for lines
      String buffer = '';
      await for (final chunk in response.stream.transform(utf8.decoder)) {
        buffer += chunk;
        while (buffer.contains('\n')) {
          final index = buffer.indexOf('\n');
          final line = buffer.substring(0, index).trim();
          buffer = buffer.substring(index + 1);

          if (line.isEmpty) continue;

          if (line.startsWith('data: ')) {
            final dataStr = line.substring(6).trim();
            if (dataStr == '[DONE]') {
              onDone();
              return;
            }

            try {
              final json = jsonDecode(dataStr);
              if (json['error'] != null) {
                onError(json['error'].toString());
                return;
              }

              final content = json['content'] as String?;
              if (content != null && content.isNotEmpty) {
                onChunk(content);
              }

              if (json['done'] == true) {
                onDone();
                return;
              }
            } catch (_) {
              // Non-json raw text fallback
              if (dataStr.isNotEmpty) {
                onChunk(dataStr);
              }
            }
          }
        }
      }

      onDone();
    } catch (e) {
      onError(e.toString());
    } finally {
      _client?.close();
      _client = null;
    }
  }

  void cancel() {
    _client?.close();
    _client = null;
  }
}
