import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/models/dashboard_metrics.dart';
import '../../../core/models/request_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/user_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../community/repositories/community_post_repository.dart';
import '../repositories/official_repository.dart';

final officialQueuePreviewProvider = StreamProvider<List<RequestModel>>((ref) {
  return ref.watch(officialRepositoryProvider).getPendingRequests();
});

class OfficialDashboardScreen extends ConsumerStatefulWidget {
  const OfficialDashboardScreen({super.key});

  @override
  ConsumerState<OfficialDashboardScreen> createState() =>
      _OfficialDashboardScreenState();
}

class _OfficialDashboardScreenState
    extends ConsumerState<OfficialDashboardScreen> {
  final _noticeTitleController = TextEditingController();
  final _noticeBodyController = TextEditingController();
  final _committeeNicController = TextEditingController();
  String _noticeCategory = 'General';
  bool _isPostingNotice = false;
  bool _isSearchingCitizen = false;
  bool _isPromotingCitizen = false;
  UserModel? _committeeCandidate;
  String? _committeeMessage;
  bool _committeeMessageIsError = false;

  @override
  void dispose() {
    _noticeTitleController.dispose();
    _noticeBodyController.dispose();
    _committeeNicController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final metricsAsync = ref.watch(dashboardMetricsProvider);
    final queueAsync = ref.watch(officialQueuePreviewProvider);
    final pendingPostsAsync = ref.watch(pendingCommunityPostsProvider);
    final currentUser = ref.watch(authServiceProvider).currentUser;
    final officerName = currentUser?.displayName?.trim().isNotEmpty == true
        ? currentUser!.displayName!
        : 'GN Officer';

    return Scaffold(
      backgroundColor: AppColors.surfaceParchment,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: Colors.white,
        title: const Text('GN Officer Dashboard'),
        actions: [
          IconButton(
            onPressed: () => context.push('/notifications'),
            tooltip: 'Notifications',
            icon: const Icon(Icons.notifications_outlined),
          ),
          IconButton(
            onPressed: () => context.push('/profile'),
            tooltip: 'Profile',
            icon: const Icon(Icons.person_outline),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardMetricsProvider);
          ref.invalidate(officialQueuePreviewProvider);
          ref.invalidate(pendingCommunityPostsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            _OfficerHero(officerName: officerName),
            const SizedBox(height: 20),
            metricsAsync.when(
              data: (metrics) => _MetricsRow(metrics: metrics),
              loading: () => const _LoadingBlock(height: 96),
              error: (_, __) => const _InlineError(
                message: 'Unable to load request metrics.',
              ),
            ),
            const SizedBox(height: 24),
            _SectionHeader(
              title: 'Pending Requests',
              actionLabel: 'View queue',
              onAction: () => context.go('/official/requests/pending'),
            ),
            const SizedBox(height: 10),
            queueAsync.when(
              data: (items) => _PendingRequestsPreview(items: items),
              loading: () => const _LoadingBlock(height: 116),
              error: (_, __) => const _InlineError(
                message: 'Unable to load pending requests.',
              ),
            ),
            const SizedBox(height: 24),
            const _SectionLabel('Core Workflows'),
            const SizedBox(height: 10),
            _WorkflowGrid(
              actions: [
                _WorkflowAction(
                  icon: Icons.person_add_alt_outlined,
                  title: 'Register Citizen',
                  subtitle: 'Create account and email credentials.',
                  onTap: () => context.go('/auth/create-resident'),
                ),
                _WorkflowAction(
                  icon: Icons.fact_check_outlined,
                  title: 'Review Requests',
                  subtitle: 'Approve or reject certificate requests.',
                  onTap: () => context.go('/official/requests/pending'),
                ),
                _WorkflowAction(
                  icon: Icons.verified_user_outlined,
                  title: 'Moderate Posts',
                  subtitle: 'Approve jobs and lost item posts.',
                  onTap: () => context.go('/community/moderation'),
                ),
                _WorkflowAction(
                  icon: Icons.warning_amber_outlined,
                  title: 'Incident Desk',
                  subtitle: 'Acknowledge and resolve alerts.',
                  onTap: () => context.go('/incidents'),
                ),
                _WorkflowAction(
                  icon: Icons.manage_search_outlined,
                  title: 'Citizen Records',
                  subtitle: 'Search by NIC, email, or phone.',
                  onTap: () => context.go('/official/citizens'),
                ),
                _WorkflowAction(
                  icon: Icons.record_voice_over_outlined,
                  title: 'Announcements',
                  subtitle: 'Send village-wide messages.',
                  onTap: () => context.go('/official/announcements'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const _SectionLabel('Promote Citizen to Committee'),
            const SizedBox(height: 10),
            _buildCommitteePromotionPanel(),
            const SizedBox(height: 24),
            const _SectionLabel('Post Official Notice'),
            const SizedBox(height: 10),
            _buildNoticeComposer(),
            const SizedBox(height: 24),
            _SectionHeader(
              title: 'Community Moderation',
              actionLabel: 'Open',
              onAction: () => context.go('/community/moderation'),
            ),
            const SizedBox(height: 10),
            pendingPostsAsync.when(
              data: (posts) => _ModerationSummary(count: posts.length),
              loading: () => const _LoadingBlock(height: 84),
              error: (_, __) => const _InlineError(
                message: 'Unable to load moderation queue.',
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _OfficerBottomBar(context: context),
    );
  }

  Widget _buildCommitteePromotionPanel() {
    final candidate = _committeeCandidate;
    final isCommittee =
        candidate?.capabilities['isCommitteeMember'] == true &&
        candidate?.capabilities['canModerateCommunity'] == true;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceIvory,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceWarmSand),
        boxShadow: AppColors.shadowLow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Search a citizen by NIC, then grant committee moderation access.',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _committeeNicController,
            enabled: !_isSearchingCitizen && !_isPromotingCitizen,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _findCommitteeCandidate(),
            decoration: const InputDecoration(
              labelText: 'Citizen NIC',
              hintText: '200012345678 or 987654321V',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isSearchingCitizen ? null : _findCommitteeCandidate,
              icon: _isSearchingCitizen
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.manage_search_outlined),
              label: Text(
                _isSearchingCitizen ? 'Searching...' : 'Find Citizen',
              ),
            ),
          ),
          if (candidate != null) ...[
            const SizedBox(height: 14),
            _CommitteeCandidateCard(
              user: candidate,
              isCommittee: isCommittee,
              isPromoting: _isPromotingCitizen,
              onPromote: isCommittee ? null : _promoteCandidateToCommittee,
            ),
          ],
          if (_committeeMessage != null) ...[
            const SizedBox(height: 12),
            _InlineNotice(
              message: _committeeMessage!,
              isError: _committeeMessageIsError,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _findCommitteeCandidate() async {
    final nic = _committeeNicController.text.trim();
    if (nic.isEmpty) {
      _setCommitteeMessage('Enter a citizen NIC first.', isError: true);
      return;
    }

    setState(() {
      _isSearchingCitizen = true;
      _committeeCandidate = null;
      _committeeMessage = null;
    });

    try {
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      final officer = currentUid == null
          ? null
          : await ref.read(userServiceProvider).getUserProfileOnce(currentUid);
      final officerRole = officer?.role == 'super_admin'
          ? 'admin'
          : officer?.role ?? 'gn_officer';

      Query<Map<String, dynamic>> query = FirebaseFirestore.instance
          .collection('users')
          .where('nic', isEqualTo: nic);

      if (officerRole == 'gn_officer') {
        final village = officer?.village.trim() ?? '';
        if (village.isEmpty) {
          _setCommitteeMessage(
            'Your GN profile needs a village before citizen search.',
            isError: true,
          );
          return;
        }
        query = query.where('village', isEqualTo: village);
      }

      final snapshot = await query.limit(1).get();

      if (snapshot.docs.isEmpty) {
        _setCommitteeMessage('No citizen found for this NIC.', isError: true);
        return;
      }

      final candidate = UserModel.fromMap(
        snapshot.docs.first.data(),
        snapshot.docs.first.id,
      );
      if (candidate.role != 'citizen' && candidate.role != 'admin_resident') {
        _setCommitteeMessage(
          'Only citizen accounts can be promoted to committee.',
          isError: true,
        );
        return;
      }

      if (officerRole == 'gn_officer' &&
          officer?.village.isNotEmpty == true &&
          candidate.village.isNotEmpty &&
          officer!.village != candidate.village) {
        _setCommitteeMessage(
          'This citizen belongs to another village record.',
          isError: true,
        );
        return;
      }

      if (!mounted) return;
      setState(() {
        _committeeCandidate = candidate;
        _committeeMessage = null;
      });
    } catch (error) {
      _setCommitteeMessage('Search failed: $error', isError: true);
    } finally {
      if (mounted) setState(() => _isSearchingCitizen = false);
    }
  }

  Future<void> _promoteCandidateToCommittee() async {
    final candidate = _committeeCandidate;
    if (candidate == null) return;

    setState(() => _isPromotingCitizen = true);
    try {
      final actorUid = FirebaseAuth.instance.currentUser?.uid;
      final capabilities = {
        ...candidate.capabilities,
        'isCommitteeMember': true,
        'canModerateCommunity': true,
        'canManageIncidents': true,
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(candidate.uid)
          .update({
            'capabilities': capabilities,
            'updatedAt': FieldValue.serverTimestamp(),
          });
      await FirebaseFirestore.instance.collection('audit_logs').add({
        'action': 'promote_citizen_to_committee',
        'targetUid': candidate.uid,
        'actorUid': actorUid,
        'actorRole': 'gn_officer',
        'details': {'capabilities': capabilities},
        'createdAt': FieldValue.serverTimestamp(),
      });
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': candidate.uid,
        'title': 'Committee access enabled',
        'message':
            'You have been added to the village committee. Committee tools are now available.',
        'type': 'committee_access',
        'actionRoute': '/committee/tasks',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      setState(() {
        _committeeCandidate = UserModel(
          uid: candidate.uid,
          fullName: candidate.fullName,
          nic: candidate.nic,
          phone: candidate.phone,
          email: candidate.email,
          address: candidate.address,
          village: candidate.village,
          district: candidate.district,
          role: candidate.role,
          accountStatus: candidate.accountStatus,
          capabilities: capabilities,
          memberType: candidate.memberType,
          relationship: candidate.relationship,
          hasSystemAccess: candidate.hasSystemAccess,
          createdByUid: candidate.createdByUid,
          createdAt: candidate.createdAt,
          photoURL: candidate.photoURL,
        );
      });
      _setCommitteeMessage('Citizen promoted to committee.', isError: false);
    } catch (error) {
      _setCommitteeMessage('Promotion failed: $error', isError: true);
    } finally {
      if (mounted) setState(() => _isPromotingCitizen = false);
    }
  }

  void _setCommitteeMessage(String message, {required bool isError}) {
    if (!mounted) return;
    setState(() {
      _committeeMessage = message;
      _committeeMessageIsError = isError;
    });
  }

  Widget _buildNoticeComposer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceIvory,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceWarmSand),
        boxShadow: AppColors.shadowLow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _noticeCategory,
            items: const [
              DropdownMenuItem(value: 'General', child: Text('General')),
              DropdownMenuItem(
                value: 'Development',
                child: Text('Development'),
              ),
              DropdownMenuItem(value: 'Health', child: Text('Health')),
              DropdownMenuItem(value: 'Emergency', child: Text('Emergency')),
            ],
            onChanged: _isPostingNotice
                ? null
                : (value) => setState(() {
                    _noticeCategory = value ?? _noticeCategory;
                  }),
            decoration: const InputDecoration(
              labelText: 'Category',
              prefixIcon: Icon(Icons.label_outline),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noticeTitleController,
            enabled: !_isPostingNotice,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Notice title',
              prefixIcon: Icon(Icons.campaign_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noticeBodyController,
            enabled: !_isPostingNotice,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Notice details',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isPostingNotice ? null : _postNotice,
              icon: _isPostingNotice
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_outlined),
              label: Text(_isPostingNotice ? 'Posting...' : 'Post Notice'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _postNotice() async {
    final title = _noticeTitleController.text.trim();
    final description = _noticeBodyController.text.trim();
    if (title.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a title and notice details.')),
      );
      return;
    }

    setState(() => _isPostingNotice = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('notices').add({
        'title': title,
        'description': description,
        'body': description,
        'category': _noticeCategory,
        'date': FieldValue.serverTimestamp(),
        'status': 'published',
        'isVerified': true,
        'createdBy': user?.uid,
        'publishedBy': user?.uid,
        'publishedByRole': 'gn_officer',
        'createdByName': user?.displayName ?? 'GN Officer',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await FirebaseFirestore.instance.collection('audit_logs').add({
        'action': 'publish_notice',
        'actorUid': user?.uid,
        'actorRole': 'gn_officer',
        'targetCollection': 'notices',
        'details': {'title': title, 'category': _noticeCategory},
        'createdAt': FieldValue.serverTimestamp(),
      });
      _noticeTitleController.clear();
      _noticeBodyController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Official notice posted.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to post notice: $error'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isPostingNotice = false);
    }
  }
}

class _OfficerHero extends StatelessWidget {
  const _OfficerHero({required this.officerName});

  final String officerName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.shadowMedium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            officerName,
            style: AppTextStyles.displayLarge.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Citizen registration, certificate review, notices, moderation, and incident response.',
            style: AppTextStyles.body.copyWith(
              color: Colors.white.withValues(alpha: 0.82),
            ),
          ),
          const SizedBox(height: 16),
          _DarkChip(
            icon: Icons.verified_user_outlined,
            label: 'Workflow desk active',
          ),
        ],
      ),
    );
  }
}

class _DarkChip extends StatelessWidget {
  const _DarkChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _MetricsRow extends StatelessWidget {
  const _MetricsRow({required this.metrics});

  final DashboardMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricBox(
            title: 'Pending',
            value: '${metrics.totalPending}',
            color: AppColors.statusPending,
            icon: Icons.pending_actions_outlined,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricBox(
            title: 'Approved',
            value: '${metrics.approvedThisMonth}',
            color: AppColors.statusApproved,
            icon: Icons.check_circle_outline,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricBox(
            title: 'Rejected',
            value: '${metrics.rejectedThisMonth}',
            color: AppColors.statusRejected,
            icon: Icons.cancel_outlined,
          ),
        ),
      ],
    );
  }
}

class _MetricBox extends StatelessWidget {
  const _MetricBox({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String title;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceIvory,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceWarmSand),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value, style: AppTextStyles.h2),
          Text(title, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _PendingRequestsPreview extends StatelessWidget {
  const _PendingRequestsPreview({required this.items});

  final List<RequestModel> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptyMessage(
        icon: Icons.inbox_outlined,
        message: 'No certificate requests are waiting for review.',
      );
    }

    return Column(
      children: [
        for (final request in items.take(3))
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _RequestTile(request: request),
          ),
      ],
    );
  }
}

class _RequestTile extends StatelessWidget {
  const _RequestTile({required this.request});

  final RequestModel request;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/official/requests/${request.id}/review'),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceIvory,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.surfaceWarmSand),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.description_outlined,
                color: AppColors.brandGreen,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(request.fullName, style: AppTextStyles.bodySemiBold),
                    const SizedBox(height: 2),
                    Text(request.documentType, style: AppTextStyles.caption),
                  ],
                ),
              ),
              Text(_timeAgo(request.submittedAt), style: AppTextStyles.small),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkflowGrid extends StatelessWidget {
  const _WorkflowGrid({required this.actions});

  final List<_WorkflowAction> actions;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.92,
      ),
      itemBuilder: (context, index) => _WorkflowCard(action: actions[index]),
    );
  }
}

class _WorkflowCard extends StatelessWidget {
  const _WorkflowCard({required this.action});

  final _WorkflowAction action;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceIvory,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.surfaceWarmSand),
            boxShadow: AppColors.shadowLow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.brandGreenSurface,
                  shape: BoxShape.circle,
                ),
                child: Icon(action.icon, color: AppColors.brandGreen),
              ),
              const Spacer(),
              Text(action.title, style: AppTextStyles.bodySemiBold),
              const SizedBox(height: 4),
              Text(
                action.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkflowAction {
  const _WorkflowAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
}

class _ModerationSummary extends StatelessWidget {
  const _ModerationSummary({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return _SummaryPanel(
      icon: Icons.verified_user_outlined,
      title: count == 0
          ? 'Moderation queue clear'
          : '$count posts awaiting review',
      subtitle: count == 0
          ? 'Approved posts are visible to citizens.'
          : 'Open moderation to approve or remove community posts.',
      onTap: () => context.go('/community/moderation'),
    );
  }
}

class _CommitteeCandidateCard extends StatelessWidget {
  const _CommitteeCandidateCard({
    required this.user,
    required this.isCommittee,
    required this.isPromoting,
    required this.onPromote,
  });

  final UserModel user;
  final bool isCommittee;
  final bool isPromoting;
  final VoidCallback? onPromote;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceParchment,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceWarmSand),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.brandGreenSurface,
                foregroundColor: AppColors.brandGreen,
                child: Text(_initial(user.fullName)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName.isEmpty ? 'Unnamed citizen' : user.fullName,
                      style: AppTextStyles.bodySemiBold,
                    ),
                    Text(
                      '${user.nic} - ${user.village.isEmpty ? 'Village not set' : user.village}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              _AccessPill(active: isCommittee),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isPromoting ? null : onPromote,
              icon: isPromoting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.group_add_outlined),
              label: Text(
                isCommittee
                    ? 'Committee Access Enabled'
                    : isPromoting
                    ? 'Promoting...'
                    : 'Promote to Committee',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccessPill extends StatelessWidget {
  const _AccessPill({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: active ? AppColors.brandGreenSurface : AppColors.warningLight,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        active ? 'Committee' : 'Citizen',
        style: AppTextStyles.small.copyWith(
          color: active ? AppColors.brandGreen : AppColors.warning,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isError ? AppColors.errorLight : AppColors.brandGreenSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isError ? AppColors.errorRed : AppColors.brandGreenBorder,
        ),
      ),
      child: Text(
        message,
        style: AppTextStyles.caption.copyWith(
          color: isError ? AppColors.errorRed : AppColors.brandGreen,
        ),
      ),
    );
  }
}

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.brandGreenSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.brandGreenBorder),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.brandGreen),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.bodySemiBold),
                    Text(subtitle, style: AppTextStyles.caption),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.brandGreen,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: AppTextStyles.h3)),
        TextButton(onPressed: onAction, child: Text(actionLabel)),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label.toUpperCase(), style: AppTextStyles.overline);
  }
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceIvory,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceWarmSand),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.inkLight),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: AppTextStyles.caption)),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: AppTextStyles.caption.copyWith(color: AppColors.error),
      ),
    );
  }
}

class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surfaceIvory,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceWarmSand),
      ),
      child: const CircularProgressIndicator(),
    );
  }
}

class _OfficerBottomBar extends StatelessWidget {
  const _OfficerBottomBar({required this.context});

  final BuildContext context;

  @override
  Widget build(BuildContext _) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.surfaceWarmSand)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            children: [
              _BottomItem(
                icon: Icons.dashboard_outlined,
                label: 'Desk',
                active: true,
                onTap: () => context.go('/official/dashboard'),
              ),
              _BottomItem(
                icon: Icons.person_add_alt_outlined,
                label: 'Register',
                onTap: () => context.go('/auth/create-resident'),
              ),
              _BottomItem(
                icon: Icons.description_outlined,
                label: 'Review',
                onTap: () => context.go('/official/requests/pending'),
              ),
              _BottomItem(
                icon: Icons.verified_user_outlined,
                label: 'Moderate',
                onTap: () => context.go('/community/moderation'),
              ),
              _BottomItem(
                icon: Icons.warning_amber_outlined,
                label: 'Incidents',
                onTap: () => context.go('/incidents'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  const _BottomItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: active ? AppColors.brandGreen : AppColors.inkLight,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: active ? AppTextStyles.tab : AppTextStyles.tabInactive,
            ),
          ],
        ),
      ),
    );
  }
}

String _timeAgo(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return DateFormat.MMMd().format(date);
}

String _initial(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '?';
  return trimmed[0].toUpperCase();
}
