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
    DateTime? appointmentStartAt,
    DateTime? appointmentEndAt,
  }) async {
    final appointmentText =
        (appointmentStartAt != null && appointmentEndAt != null)
        ? 'Appointment: ${_formatAppointmentWindow(appointmentStartAt, appointmentEndAt)}\nPlease bring your original documents when visiting the GN office.\n'
        : '';

    final emailContent =
        '''
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📧 MOCK EMAIL: REQUEST APPROVED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
To: $citizenEmail
Subject: Your $documentType Request Has Been Approved

Dear Citizen,

Your request for the following certificate has been approved:
Document Type: $documentType
Status: APPROVED

${appointmentText.isNotEmpty ? '$appointmentText\n' : ''}
${remarks != null ? 'Remarks from GN Officer:\\n$remarks' : ''}

Please visit the Village Connect app or contact your local GN office to collect the document.

Best Regards,
Village Connect System
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''';
    print(emailContent);
  }

  String _formatAppointmentWindow(DateTime start, DateTime end) {
    final sameDay =
        start.year == end.year &&
        start.month == end.month &&
        start.day == end.day;

    final date = '${start.day}/${start.month}/${start.year}';
    final startTime = _formatTime(start);
    final endTime = _formatTime(end);

    if (sameDay) {
      return '$date, $startTime - $endTime';
    }

    final endDate = '${end.day}/${end.month}/${end.year}';
    return '$date $startTime - $endDate $endTime';
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  /// Send rejection email to citizen (mock - prints to console)
  Future<void> sendRejectionEmail({
    required String citizenEmail,
    required String documentType,
    required String rejectionReason,
  }) async {
    final emailContent =
        '''
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
    final emailContent =
        '''
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
