import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/incident_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/notification_service.dart';

final incidentRepositoryProvider = Provider<IncidentRepository>((ref) {
  return IncidentRepository(
    FirebaseFirestore.instance,
    ref.watch(notificationServiceProvider),
  );
});

final incidentsProvider = StreamProvider<List<IncidentModel>>((ref) {
  return ref.watch(incidentRepositoryProvider).watchIncidents();
});

class IncidentRepository {
  final FirebaseFirestore _firestore;
  final NotificationService _notificationService;

  IncidentRepository(this._firestore, this._notificationService);

  Future<String> createIncident({
    required UserModel reporter,
    required String type,
    required String description,
    required String location,
  }) async {
    final incident = IncidentModel(
      id: '',
      reporterId: reporter.uid,
      reporterName: reporter.fullName,
      reporterNic: reporter.nic,
      type: type,
      description: description,
      location: location,
      priority: _priorityFor(type),
      status: 'Acknowledged',
      createdAt: DateTime.now(),
    );

    final doc = await _firestore.collection('incidents').add(incident.toMap());
    await _notifyResponders(doc.id, incident);
    return doc.id;
  }

  Stream<List<IncidentModel>> watchIncidents() {
    return _firestore.collection('incidents').snapshots().map((snapshot) {
      final incidents = snapshot.docs
          .map((doc) => IncidentModel.fromMap(doc.data(), doc.id))
          .toList();
      incidents.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return incidents;
    });
  }

  Future<void> updateStatus({
    required String incidentId,
    required String status,
    required String responderUid,
    String? notes,
  }) async {
    await _firestore.collection('incidents').doc(incidentId).update({
      'status': status,
      'responseNotes': notes,
      'updatedAt': FieldValue.serverTimestamp(),
      'lastUpdatedBy': responderUid,
    });
  }

  String _priorityFor(String type) {
    switch (type) {
      case 'Fire':
      case 'Medical':
      case 'Crime':
      case 'Accident':
        return 'Critical';
      case 'Flood':
        return 'High';
      default:
        return 'Medium';
    }
  }

  Future<void> _notifyResponders(
    String incidentId,
    IncidentModel incident,
  ) async {
    final byRole = await _firestore
        .collection('users')
        .where('role', whereIn: ['gn_officer', 'admin', 'committee'])
        .get();
    final notified = <String>{};
    for (final doc in byRole.docs) {
      notified.add(doc.id);
      await _sendResponderNotification(doc.id, incidentId, incident);
    }

    final byCapability = await _firestore
        .collection('users')
        .where('capabilities.isCommitteeMember', isEqualTo: true)
        .get();
    for (final doc in byCapability.docs) {
      if (!notified.add(doc.id)) continue;
      await _sendResponderNotification(doc.id, incidentId, incident);
    }
  }

  Future<void> _sendResponderNotification(
    String userId,
    String incidentId,
    IncidentModel incident,
  ) {
    return _notificationService.sendNotification(
      userId: userId,
      type: 'incident',
      title: '${incident.type} alert reported',
      message:
          '${incident.reporterName} reported an emergency at ${incident.location}.',
      relatedId: incidentId,
      actionRoute: '/incidents',
    );
  }
}
