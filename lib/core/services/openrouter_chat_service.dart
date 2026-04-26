import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../config/openrouter_secrets.dart';
import '../constants/ai_chat_prompts.dart';

/// A single back-and-forth for the API (user / assistant), after [system] is applied.
class ChatApiMessage {
  const ChatApiMessage({required this.role, required this.content});

  final String role; // "user" | "assistant"
  final String content;
}

class OpenRouterChatService {
  OpenRouterChatService([Dio? dio])
      : _dio = dio ?? Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 90),
            headers: {
              'Content-Type': 'application/json',
            },
          ),
        );

  final Dio _dio;
  static final _log = Logger();

  static const _endpoint = 'https://openrouter.ai/api/v1/chat/completions';
  static const int maxHistoryMessages = 24;

  /// [history] is the full in-memory thread (chronological). System prompt is
  /// added here; the last message should be the latest user text.
  Future<String> completeChat({
    required List<ChatApiMessage> history,
    required String outputLanguage,
  }) async {
    if (openRouterApiKey.isEmpty) {
      return 'OpenRouter API key is missing. Set it in lib/core/config/openrouter_secrets.dart';
    }
    if (history.isEmpty) {
      return 'No message to send.';
    }

    final sliced = history.length > maxHistoryMessages
        ? history.sublist(history.length - maxHistoryMessages)
        : history;

    final system = '''
$villageConnectSystemPrompt

$villageConnectAppKnowledge

Reply language: The user selected "$outputLanguage" in the app. Reply in that language for in-app help (English, Sinhala, or Tamil as selected). If the user writes in a different language, you may follow their input language for clarity while staying on-topic.''';

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': system},
      ...sliced
          .map((m) => <String, String>{'role': m.role, 'content': m.content}),
    ];

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _endpoint,
        options: Options(
          headers: {
            'Authorization': 'Bearer $openRouterApiKey',
            'HTTP-Referer': 'https://villageconnect.app',
            'X-Title': 'Village Connect',
          },
        ),
        data: {
          'model': openRouterModel,
          'messages': messages,
        },
      );

      final data = response.data;
      if (data == null) {
        return 'The assistant had no data to show. Please try again.';
      }
      final list = data['choices'];
      if (list is! List<dynamic> || list.isEmpty) {
        return 'The assistant had no data to show. Please try again.';
      }
      final first = list[0];
      if (first is! Map<String, dynamic>) {
        return 'The assistant had no data to show. Please try again.';
      }
      final message = first['message'];
      if (message is! Map<String, dynamic>) {
        return 'The assistant could not form a reply. Please try again.';
      }
      final text = message['content'];
      if (text is! String || text.isEmpty) {
        return 'The assistant could not form a reply. Please try again.';
      }
      return text.trim();
    } on DioException catch (e, st) {
      _log.w('OpenRouter error', error: e, stackTrace: st);
      return _messageForDio(e);
    } catch (e, st) {
      _log.e('OpenRouter unexpected', error: e, stackTrace: st);
      return 'Something went wrong. Check your connection and try again.';
    }
  }

  String _messageForDio(DioException e) {
    final code = e.response?.statusCode;
    final data = e.response?.data;
    var detail = '';
    if (data is Map<String, dynamic>) {
      final err = data['error'];
      if (err is Map<String, dynamic> && err['message'] is String) {
        detail = err['message'] as String;
      } else if (err is String) {
        detail = err;
      }
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Request timed out. Check your network and try again.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Could not reach the server. Check your network and try again.';
    }
    if (code == 401) {
      return 'API key is invalid or expired. Update openrouter_secrets.dart or your OpenRouter account.';
    }
    if (code == 429) {
      return 'Too many requests. Please wait a moment and try again.';
    }
    if (code != null && code >= 500) {
      return 'The assistant service is temporarily unavailable. Please try again later.';
    }
    if (detail.isNotEmpty) {
      return 'Could not get a reply: $detail';
    }
    return 'Could not get a reply. Please try again.';
  }
}
