import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/user_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class CitizenRecordsScreen extends StatefulWidget {
  const CitizenRecordsScreen({super.key});

  @override
  State<CitizenRecordsScreen> createState() => _CitizenRecordsScreenState();
}

class _CitizenRecordsScreenState extends State<CitizenRecordsScreen> {
  final _searchController = TextEditingController();
  String _searchType = 'nic';
  bool _isSearching = false;
  UserModel? _citizen;
  String? _message;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() => _message = 'Enter a value to search.');
      return;
    }

    setState(() {
      _isSearching = true;
      _message = null;
      _citizen = null;
    });

    try {
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      if (currentUid == null) {
        setState(() => _message = 'Session expired. Please sign in again.');
        return;
      }

      final requesterDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUid)
          .get();
      final requester = requesterDoc.data() ?? const <String, dynamic>{};
      final requesterRole = requester['role'] == 'super_admin'
          ? 'admin'
          : requester['role'] as String? ?? 'gn_officer';

      final field = switch (_searchType) {
        'email' => 'email',
        'phone' => 'phone',
        _ => 'nic',
      };
      Query<Map<String, dynamic>> recordQuery = FirebaseFirestore.instance
          .collection('users')
          .where(field, isEqualTo: query);

      if (requesterRole == 'gn_officer') {
        final village = (requester['village'] as String? ?? '').trim();
        if (village.isEmpty) {
          setState(
            () => _message =
                'Your GN profile needs a village before citizen search.',
          );
          return;
        }
        recordQuery = recordQuery.where('village', isEqualTo: village);
      }

      final snapshot = await recordQuery.limit(1).get();

      if (snapshot.docs.isEmpty) {
        setState(() => _message = 'No citizen record found.');
        return;
      }
      final user = UserModel.fromMap(
        snapshot.docs.first.data(),
        snapshot.docs.first.id,
      );
      setState(() => _citizen = user);
    } catch (error) {
      setState(() => _message = 'Search failed: $error');
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceParchment,
      appBar: AppBar(
        title: const Text('Citizen Records'),
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
                Text('Search Record', style: AppTextStyles.h3),
                const SizedBox(height: 10),
                SegmentedButton<String>(
                  selected: {_searchType},
                  onSelectionChanged: (value) =>
                      setState(() => _searchType = value.first),
                  segments: const [
                    ButtonSegment(value: 'nic', label: Text('NIC')),
                    ButtonSegment(value: 'email', label: Text('Email')),
                    ButtonSegment(value: 'phone', label: Text('Phone')),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  onSubmitted: (_) => _search(),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search_outlined),
                    hintText: 'Search exact $_searchType',
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isSearching ? null : _search,
                    icon: _isSearching
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.manage_search_outlined),
                    label: Text(_isSearching ? 'Searching...' : 'Search'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_message != null) _Panel(child: Text(_message!)),
          if (_citizen != null) _CitizenCard(user: _citizen!),
        ],
      ),
    );
  }
}

class _CitizenCard extends StatelessWidget {
  const _CitizenCard({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('UID', user.uid),
      ('Name', user.fullName),
      ('NIC', user.nic),
      ('Email', user.email),
      ('Phone', user.phone),
      ('Address', user.address),
      ('Village', user.village),
      ('District', user.district),
      ('Role', user.role),
      ('Status', user.accountStatus),
    ];

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: AppColors.brandGreenSurface,
                foregroundColor: AppColors.brandGreen,
                child: Icon(Icons.person_outline),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(user.fullName, style: AppTextStyles.h3)),
            ],
          ),
          const SizedBox(height: 16),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 82,
                    child: Text(row.$1, style: AppTextStyles.small),
                  ),
                  Expanded(child: Text(row.$2.isEmpty ? '-' : row.$2)),
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
      width: double.infinity,
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
