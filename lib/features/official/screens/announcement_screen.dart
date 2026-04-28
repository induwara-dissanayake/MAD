import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/user_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class AnnouncementScreen extends ConsumerStatefulWidget {
  const AnnouncementScreen({super.key});

  @override
  ConsumerState<AnnouncementScreen> createState() => _AnnouncementScreenState();
}

class _AnnouncementScreenState extends ConsumerState<AnnouncementScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String _targetRole = 'all';
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    if (title.isEmpty || body.isEmpty) {
      _showSnack('Enter a title and message.', isError: true);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        throw Exception('Session expired. Please sign in again.');
      }
      final profile = await ref
          .read(userServiceProvider)
          .getUserProfileOnce(uid);

      await FirebaseFirestore.instance.collection('announcements').add({
        'title': title,
        'body': body,
        'targetRole': _targetRole,
        'targetVillage': profile?.village ?? '',
        'createdBy': uid,
        'createdByRole': profile?.role ?? 'gn_officer',
        'status': 'sent',
        'createdAt': FieldValue.serverTimestamp(),
      });
      await FirebaseFirestore.instance.collection('notices').add({
        'title': title,
        'description': body,
        'body': body,
        'category': 'General',
        'date': FieldValue.serverTimestamp(),
        'status': 'published',
        'isVerified': true,
        'createdBy': uid,
        'publishedBy': uid,
        'publishedByRole': profile?.role ?? 'gn_officer',
        'createdByName': profile?.fullName ?? 'GN Officer',
        'targetRole': _targetRole,
        'village': profile?.village ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await FirebaseFirestore.instance.collection('audit_logs').add({
        'action': 'publish_announcement',
        'actorUid': uid,
        'actorRole': profile?.role ?? 'gn_officer',
        'targetCollection': 'announcements',
        'details': {'targetRole': _targetRole, 'title': title},
        'createdAt': FieldValue.serverTimestamp(),
      });

      _titleController.clear();
      _bodyController.clear();
      _showSnack('Announcement published.');
    } catch (error) {
      _showSnack('Publish failed: $error', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceParchment,
      appBar: AppBar(
        title: const Text('Announcements'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/official/dashboard');
            }
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          _Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mass Communication', style: AppTextStyles.h3),
                const SizedBox(height: 8),
                Text(
                  'Creates one announcement document instead of fan-out notifications, keeping reads/writes friendly for Spark Plan.',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _targetRole,
                  decoration: const InputDecoration(
                    labelText: 'Audience',
                    prefixIcon: Icon(Icons.groups_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All users')),
                    DropdownMenuItem(value: 'citizen', child: Text('Citizens')),
                    DropdownMenuItem(
                      value: 'committee',
                      child: Text('Committee'),
                    ),
                    DropdownMenuItem(
                      value: 'gn_officer',
                      child: Text('GN officers'),
                    ),
                  ],
                  onChanged: _isSaving
                      ? null
                      : (value) => setState(() => _targetRole = value ?? 'all'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _titleController,
                  enabled: !_isSaving,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    prefixIcon: Icon(Icons.campaign_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _bodyController,
                  enabled: !_isSaving,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Message',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isSaving ? null : _publish,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_outlined),
                    label: Text(_isSaving ? 'Publishing...' : 'Publish'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceIvory,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceWarmSand),
        boxShadow: AppColors.shadowLow,
      ),
      child: child,
    );
  }
}
