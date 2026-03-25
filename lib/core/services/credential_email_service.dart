import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final credentialEmailServiceProvider = Provider<CredentialEmailService>((ref) {
  return CredentialEmailService(Dio());
});

/// Sends credential emails through EmailJS REST API.
///
/// Configure these at runtime using --dart-define:
/// - EMAILJS_SERVICE_ID
/// - EMAILJS_TEMPLATE_ID
/// - EMAILJS_PUBLIC_KEY
///
/// EmailJS can use a free SMTP provider/account and keeps SMTP credentials
/// outside the app code.
class CredentialEmailService {
  final Dio _dio;

  CredentialEmailService(this._dio);

  // Primary source: --dart-define values.
  static const _serviceIdEnv = String.fromEnvironment('EMAILJS_SERVICE_ID');
  static const _templateIdEnv = String.fromEnvironment('EMAILJS_TEMPLATE_ID');
  static const _publicKeyEnv = String.fromEnvironment('EMAILJS_PUBLIC_KEY');

  // Dev fallback (used only when dart-define is missing).
  static const _serviceIdFallback = 'service_a17lcwc';
  static const _templateIdFallback = 'template_6bpb6wn';
  static const _publicKeyFallback = 'hRzO-ovGniJOnpA12';

  String get _serviceId =>
      _serviceIdEnv.isNotEmpty ? _serviceIdEnv : _serviceIdFallback;
  String get _templateId =>
      _templateIdEnv.isNotEmpty ? _templateIdEnv : _templateIdFallback;
  String get _publicKey =>
      _publicKeyEnv.isNotEmpty ? _publicKeyEnv : _publicKeyFallback;

  bool get _isConfigured =>
      _serviceId.isNotEmpty && _templateId.isNotEmpty && _publicKey.isNotEmpty;

  Future<void> queueCredentialsEmail({
    required String toEmail,
    required String fullName,
    required String nic,
    required String password,
    required String memberTypeLabel,
  }) async {
    if (!_isConfigured) {
      throw StateError(
        'Email service not configured. Missing EMAILJS_SERVICE_ID / EMAILJS_TEMPLATE_ID / EMAILJS_PUBLIC_KEY.',
      );
    }

    final response = await _dio.post(
      'https://api.emailjs.com/api/v1.0/email/send',
      options: Options(
        headers: const {'Content-Type': 'application/json'},
        sendTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
      ),
      data: {
        'service_id': _serviceId,
        'template_id': _templateId,
        'user_id': _publicKey,
        'template_params': {
          'to_email': toEmail,
          'email': toEmail,
          'user_email': toEmail,
          'to_name': fullName,
          'name': fullName,
          'member_type': memberTypeLabel,
          'username': nic,
          'password': password,
          'app_name': 'Village Connect',
        },
      },
    );

    if (response.statusCode == null || response.statusCode! >= 300) {
      throw Exception('Email send failed with status ${response.statusCode}');
    }
  }
}
