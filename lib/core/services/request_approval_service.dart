import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'notification_service.dart';
import 'email_service.dart';
import '../../features/documents/repositories/document_repository.dart';

final requestApprovalServiceProvider = Provider<RequestApprovalService>((ref) {
  return RequestApprovalService(
    ref.watch(documentRepositoryProvider),
    ref.watch(notificationServiceProvider),
    ref.watch(emailServiceProvider),
  );
});

class RequestApprovalService {
  final DocumentRepository _documentRepository;
  final NotificationService _notificationService;
  final EmailService _emailService;

  RequestApprovalService(
    this._documentRepository,
    this._notificationService,
    this._emailService,
  );

  /// Approve a request and send notifications
  Future<void> approveRequest({
    required String requestId,
    required String approverUid,
    required DateTime appointmentStartAt,
    required DateTime appointmentEndAt,
    String? remarks,
    String? citizenEmail,
  }) async {
    try {
      // Update request status to approved
      await _documentRepository.approveRequest(
        requestId: requestId,
        approvedBy: approverUid,
        appointmentStartAt: appointmentStartAt,
        appointmentEndAt: appointmentEndAt,
        remarks: remarks,
      );

      // Get request details to extract citizen info
      final request = await _documentRepository.getRequestById(requestId).first;
      if (request != null) {
        await _documentRepository.saveCertificateRequestOutcome(
          request: request,
          status: 'Approved',
          reviewedBy: approverUid,
          remarks: remarks,
          appointmentStartAt: appointmentStartAt,
          appointmentEndAt: appointmentEndAt,
        );

        // Send in-app notification to citizen
        await _notificationService.sendNotification(
          userId: request.userId,
          type: 'approval',
          title: 'Request Approved!',
          message:
              'Your ${request.documentType} request has been approved. Please visit the GN office between ${_formatAppointmentWindow(appointmentStartAt, appointmentEndAt)} with original documents.',
          requestId: requestId,
        );

        // Send mock email to citizen
        if (citizenEmail != null) {
          await _emailService.sendApprovalEmail(
            citizenEmail: citizenEmail,
            documentType: request.documentType,
            remarks: remarks,
            appointmentStartAt: appointmentStartAt,
            appointmentEndAt: appointmentEndAt,
          );
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Reject a request and send notifications
  Future<void> rejectRequest({
    required String requestId,
    required String rejectionReason,
    required String approverUid,
    String? citizenEmail,
  }) async {
    if (rejectionReason.trim().isEmpty) {
      throw ArgumentError('Rejection reason cannot be empty');
    }

    try {
      // Update request status to rejected
      await _documentRepository.rejectRequest(
        requestId: requestId,
        rejectionReason: rejectionReason,
      );

      // Get request details
      final request = await _documentRepository.getRequestById(requestId).first;
      if (request != null) {
        await _documentRepository.saveCertificateRequestOutcome(
          request: request,
          status: 'Rejected',
          reviewedBy: approverUid,
          rejectionReason: rejectionReason,
        );

        // Send in-app notification to citizen
        await _notificationService.sendNotification(
          userId: request.userId,
          type: 'rejection',
          title: 'Request Rejected',
          message:
              'Your ${request.documentType} request has been rejected. Reason: $rejectionReason',
          requestId: requestId,
        );

        // Send mock email to citizen
        if (citizenEmail != null) {
          await _emailService.sendRejectionEmail(
            citizenEmail: citizenEmail,
            documentType: request.documentType,
            rejectionReason: rejectionReason,
          );
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Request more information for a request
  Future<void> requestMoreInfo({
    required String requestId,
    required String infoNeeded,
    required String approverUid,
    String? citizenEmail,
  }) async {
    if (infoNeeded.trim().isEmpty) {
      throw ArgumentError('Information details cannot be empty');
    }

    try {
      // Update request status to info_requested
      await _documentRepository.requestMoreInfo(
        requestId: requestId,
        infoNeeded: infoNeeded,
      );

      // Get request details
      final request = await _documentRepository.getRequestById(requestId).first;
      if (request != null) {
        await _documentRepository.saveCertificateRequestOutcome(
          request: request,
          status: 'More Info Required',
          reviewedBy: approverUid,
          remarks: infoNeeded,
        );

        // Send in-app notification to citizen
        await _notificationService.sendNotification(
          userId: request.userId,
          type: 'info_request',
          title: 'Additional Information Needed',
          message:
              'Please provide additional information for your ${request.documentType} request.',
          requestId: requestId,
        );

        // Send mock email to citizen
        if (citizenEmail != null) {
          await _emailService.sendInfoRequestEmail(
            citizenEmail: citizenEmail,
            documentType: request.documentType,
            infoNeeded: infoNeeded,
          );
        }
      }
    } catch (e) {
      rethrow;
    }
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
}
