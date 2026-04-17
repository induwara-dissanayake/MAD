import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class OfficialDashboardScreen extends StatefulWidget {
  const OfficialDashboardScreen({super.key});

  @override
  State<OfficialDashboardScreen> createState() =>
      _OfficialDashboardScreenState();
}

class _OfficialDashboardScreenState extends State<OfficialDashboardScreen> {
  static const Color _brandGreen = Color(0xFF1D6F2B);
  static const Color _brandGreenDark = Color(0xFF124D1D);
  static const Color _brandGreenSoft = Color(0xFFEAF6E7);
  static const Color _warmSand = Color(0xFFF2E5D8);
  static const Color _warmSandBorder = Color(0xFFDCC9B8);
  static const Color _warmSandText = Color(0xFF8A4E1C);
  static const Color _softSurface = Color(0xFFF8F7F3);
  static const Color _tealMap = Color(0xFF169B94);
  static const Color _tealMapDark = Color(0xFF0E5D5A);

  final TextEditingController _broadcastController = TextEditingController();

  final List<_PendingRequest> _pendingRequests = [
    _PendingRequest(
      citizenName: 'K. Perera',
      documentType: 'Address Verification',
      submittedDate: '22 Feb 2026',
      initials: 'KP',
      needsSignature: true,
    ),
    _PendingRequest(
      citizenName: 'S. Silva',
      documentType: 'Land Deed Attestation',
      submittedDate: '21 Feb 2026',
      initials: 'SS',
      needsSignature: true,
    ),
    _PendingRequest(
      citizenName: 'Nadeeka Silva',
      documentType: 'Character Certificate',
      submittedDate: '20 Feb 2026',
      initials: 'NS',
      needsSignature: false,
    ),
  ];

  final List<_CommunityPost> _awaitingModeration = [
    _CommunityPost(
      username: 'Amara Jayasekara',
      userHandle: 'Community Forum',
      timeAgo: '2 hours ago',
      content:
          '"Has anyone seen the water supply schedule for next week? The main pipe near the temple seems to be leaking. Should we organise a village cleaning day?"',
    ),
  ];

  @override
  void dispose() {
    _broadcastController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _softSurface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 92),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Village Connect branding
              _buildHeaderSection(),
              // Status Alert Cards
              _buildStatusCards(),
              // Broadcast Section
              _buildBroadcastSection(),
              // Pending Requests Section
              _buildPendingRequestsSection(),
              // Awaiting Moderation Section
              _buildAwaitingModerationSection(),
              // Activity Overview
              _buildActivityOverviewSection(),
              // Citizen Sentiment Card
              _buildCitizenSentimentCard(),
              // Village Map Section
              _buildVillageMapSection(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_brandGreen, _brandGreenDark],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Village Connect Logo Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Village Connect',
                    style: AppTextStyles.h2.copyWith(
                      color: AppColors.textOnPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => context.push('/official/profile'),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.textOnPrimary.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.notifications_none_rounded,
                      color: AppColors.textOnPrimary,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Official Portal Info
          Text(
            'OFFICIAL PORTAL',
            style: AppTextStyles.small.copyWith(
              color: AppColors.textOnPrimary.withOpacity(0.8),
              fontWeight: FontWeight.w500,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Grama Niladhari - Division 412B',
            style: AppTextStyles.h1.copyWith(
              color: AppColors.textOnPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Kelani Village Administration',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textOnPrimary.withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCards() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          // Emergencies Card
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.error.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.warning_rounded,
                        color: AppColors.textOnPrimary,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '2',
                    style: AppTextStyles.h1.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w700,
                      fontSize: 28,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'NEW EMERGENCIES',
                    style: AppTextStyles.small.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Immediate action required',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.error.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Pending Requests Card
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _warmSand,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _warmSandBorder),
                boxShadow: [
                  BoxShadow(
                    color: _warmSandBorder.withOpacity(0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _warmSandText,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.schedule_rounded,
                        color: AppColors.textOnPrimary,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '5',
                    style: AppTextStyles.h1.copyWith(
                      color: _warmSandText,
                      fontWeight: FontWeight.w700,
                      fontSize: 28,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'PENDING REQUESTS',
                    style: AppTextStyles.small.copyWith(
                      color: _warmSandText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Awaiting your signature',
                    style: AppTextStyles.caption.copyWith(
                      color: _warmSandText.withOpacity(0.72),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBroadcastSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.campaign_rounded,
                color: AppColors.textMuted,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _broadcastController,
                  decoration: InputDecoration(
                    hintText: 'Broadcast a message...',
                    hintStyle: AppTextStyles.body.copyWith(
                      color: AppColors.textMuted,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  maxLines: 1,
                  style: AppTextStyles.body,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Broadcast: ${_broadcastController.text}',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    _broadcastController.clear();
                  },
                  child: Icon(
                    Icons.send_rounded,
                    color: AppColors.textOnPrimary,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPendingRequestsSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Pending Requests', style: AppTextStyles.h3),
              GestureDetector(
                onTap: () => context.push('/official/pending'),
                child: Text(
                  'View All',
                  style: AppTextStyles.captionMedium.copyWith(
                    color: _brandGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._pendingRequests
              .take(2)
              .map((request) => _buildPendingRequestCard(request))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildPendingRequestCard(_PendingRequest request) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_brandGreen, _brandGreenDark],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(
                  Icons.description_rounded,
                  color: AppColors.textOnPrimary,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.documentType,
                    style: AppTextStyles.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Requested by: ${request.citizenName}',
                    style: AppTextStyles.small,
                  ),
                ],
              ),
            ),
            if (request.needsSignature)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _warmSand,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'NEEDS SIGNATURE',
                  style: AppTextStyles.small.copyWith(
                    color: _warmSandText,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAwaitingModerationSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Awaiting Moderation', style: AppTextStyles.h3),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _brandGreenSoft,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Moderation Queue',
                  style: AppTextStyles.small.copyWith(
                    color: _brandGreen,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._awaitingModeration
              .map((post) => _buildModerationCard(post))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildModerationCard(_CommunityPost post) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _brandGreenSoft,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.person_rounded,
                      color: _brandGreen,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.username, style: AppTextStyles.bodyMedium),
                      Row(
                        children: [
                          Text(
                            post.userHandle,
                            style: AppTextStyles.small.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '• ${post.timeAgo}',
                            style: AppTextStyles.small.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _softSurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                post.content,
                style: AppTextStyles.body,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => context.push('/official/moderation'),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.success.withOpacity(0.3),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Approve',
                            style: AppTextStyles.buttonSmall.copyWith(
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => context.push('/official/moderation'),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.error.withOpacity(0.3),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Reject',
                            style: AppTextStyles.buttonSmall.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityOverviewSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Activity Overview', style: AppTextStyles.h3),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildActivityMetric('Active Requests', '12', 0.6, _brandGreen),
                const SizedBox(height: 16),
                _buildActivityMetric(
                  'Resolved Today',
                  '08',
                  0.4,
                  AppColors.success,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityMetric(
    String label,
    String value,
    double progress,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.body),
            Text(value, style: AppTextStyles.h3.copyWith(color: color)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildCitizenSentimentCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _warmSand,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.sentiment_satisfied_rounded,
                      color: _warmSandText,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'CITIZEN SENTIMENT',
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '92% Positive engagement this month\nin Division 412B.',
              style: AppTextStyles.body,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVillageMapSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'VILLAGE MAP',
            style: AppTextStyles.small.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text('Zone 4 - High Frequency Area', style: AppTextStyles.bodyMedium),
          const SizedBox(height: 12),
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: _tealMap,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  Container(
                    color: _tealMapDark,
                    child: Center(
                      child: Icon(
                        Icons.map_rounded,
                        size: 60,
                        color: _brandGreen.withOpacity(0.28),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: () => context.push('/official/pending'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.textOnPrimary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.public_rounded,
                              size: 16,
                              color: _tealMap,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Open GIS Portal',
                              style: AppTextStyles.buttonSmall.copyWith(
                                color: _tealMap,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withOpacity(0.08),
              blurRadius: 18,
              offset: const Offset(0, -4),
            ),
          ],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              icon: Icons.home_rounded,
              label: 'Home',
              isSelected: true,
              onTap: () => context.go('/official/dashboard'),
            ),
            _buildNavItem(
              icon: Icons.description_rounded,
              label: 'Requests',
              onTap: () => context.go('/official/pending'),
            ),
            _buildNavItem(
              icon: Icons.groups_rounded,
              label: 'Moderation',
              onTap: () => context.go('/official/moderation'),
            ),
            _buildNavItem(
              icon: Icons.person_rounded,
              label: 'Profile',
              onTap: () => context.go('/official/profile'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 14 : 10,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected ? _brandGreenSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? _brandGreen : Colors.black54,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.small.copyWith(
                color: isSelected ? _brandGreen : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingRequest {
  final String citizenName;
  final String documentType;
  final String submittedDate;
  final String initials;
  final bool needsSignature;

  const _PendingRequest({
    required this.citizenName,
    required this.documentType,
    required this.submittedDate,
    required this.initials,
    this.needsSignature = false,
  });
}

class _CommunityPost {
  final String username;
  final String userHandle;
  final String timeAgo;
  final String content;

  const _CommunityPost({
    required this.username,
    required this.userHandle,
    required this.timeAgo,
    required this.content,
  });
}
