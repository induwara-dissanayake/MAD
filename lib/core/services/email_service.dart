import 'package:flutter_riverpod/flutter_riverpod.dart';

final emailServiceProvider = Provider<EmailService>((ref) {
  return EmailService();
});

class EmailService {
  /// Send approval email to citizen (mock - prints to console)
  /// In production, this would use Firebase Cloud Functions or an email service
  Future<void> sendApprovalEmail({
    required String citizenEmail,
    required String documentType,
    String? remarks,
  }) async {
    final emailContent = '''
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📧 MOCK EMAIL: REQUEST APPROVED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
To: $citizenEmail
Subject: Your $documentType Request Has Been Approved

Dear Citizen,

Your request for the following certificate has been approved:
Document Type: $documentType
Status: APPROVED

${remarks != null ? 'Remarks from GN Officer:\\n$remarks' : ''}

Please visit the Village Connect app or contact your local GN office to collect the document.

Best Regards,
Village Connect System
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''';
    print(emailContent);
  }

  /// Send rejection email to citizen (mock - prints to console)
  Future<void> sendRejectionEmail({
    required String citizenEmail,
    required String documentType,
    required String rejectionReason,
  }) async {
    final emailContent = '''
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📧 MOCK EMAIL: REQUEST REJECTED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
To: $citizenEmail
Subject: Your $documentType Request Has Been Rejected

Dear Citizen,

Unfortunately, your request for the following certificate has been rejected:
Document Type: $documentType
Status: REJECTED
Reason: $rejectionReason

If you believe this decision is incorrect, please contact your local GN office to discuss further steps.

Best Regards,
Village Connect System
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''';
    print(emailContent);
  }

  /// Send info request email to citizen (mock - prints to console)
  Future<void> sendInfoRequestEmail({
    required String citizenEmail,
    required String documentType,
    required String infoNeeded,
  }) async {
    final emailContent = '''
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📧 MOCK EMAIL: ADDITIONAL INFORMATION REQUESTED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
To: $citizenEmail
Subject: Additional Information Required for Your $documentType Request

Dear Citizen,

Your request for the following certificate requires additional information:
Document Type: $documentType
Status: INFORMATION REQUESTED

Required Information:
$infoNeeded

Please provide the requested information through the Village Connect app or contact your local GN office.

Best Regards,
Village Connect System
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''';
    print(emailContent);
  }
}
