import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class CommunityModerationScreen extends StatefulWidget {
  const CommunityModerationScreen({super.key});

  @override
  State<CommunityModerationScreen> createState() =>
      _CommunityModerationScreenState();
}

class _CommunityModerationScreenState extends State<CommunityModerationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<_CommunityPost> _posts = [
    _CommunityPost(
      id: 'P001',
      authorName: 'Nadeeka Silva',
      authorInitials: 'NS',
      category: 'Lost & Found',
      title: 'Lost Black Wallet',
      description:
          'Lost near the temple on Sunday. Contains NIC and bank cards.',
      location: 'Temple Junction',
      contactInfo: '+94 77 111 2233',
      submittedDate: 'Today, 9:00 AM',
      status: 'pending',
    ),
    _CommunityPost(
      id: 'P002',
      authorName: 'Ruwan Perera',
      authorInitials: 'RP',
      category: 'Jobs',
      title: 'Electrician Needed',
      description:
          'Seeking experienced electrician for house rewiring work. 2-day job.',
      location: 'Kaduwela',
      contactInfo: '+94 71 234 5678',
      submittedDate: 'Today, 8:30 AM',
      status: 'pending',
    ),
    _CommunityPost(
      id: 'P003',
      authorName: 'Malini Kumari',
      authorInitials: 'MK',
      category: 'Lost & Found',
      title: 'Found: Brown Puppy',
      description:
          'Found a small brown puppy near the school. Very friendly. Owner please contact.',
      location: 'School Road',
      contactInfo: '+94 76 345 6789',
      submittedDate: 'Yesterday',
      status: 'pending',
    ),
    _CommunityPost(
      id: 'P004',
      authorName: 'Sunil Bandara',
      authorInitials: 'SB',
      category: 'Jobs',
      title: 'Plumbing Work Available',
      description:
          'Experienced plumber offering services. Pipe repairs and installations.',
      location: 'Malabe',
      contactInfo: '+94 77 456 7890',
      submittedDate: 'Yesterday',
      status: 'approved',
    ),
    _CommunityPost(
      id: 'P005',
      authorName: 'Priya Fernando',
      authorInitials: 'PF',
      category: 'Lost & Found',
      title: 'Lost Gold Earring',
      description:
          'Lost one gold hoop earring around the market area on Monday evening.',
      location: 'Main Market',
      contactInfo: '+94 71 567 8901',
      submittedDate: '2 days ago',
      status: 'approved',
    ),
    _CommunityPost(
      id: 'P006',
      authorName: 'Amara Wijesinghe',
      authorInitials: 'AW',
      category: 'Jobs',
      title: 'House Cleaning Services',
      description:
          'Offering part-time house cleaning. Reliable and experienced.',
      location: 'Kaduwela',
      contactInfo: '+94 76 678 9012',
      submittedDate: '3 days ago',
      status: 'approved',
    ),
    _CommunityPost(
      id: 'P007',
      authorName: 'Dinesh Rajapaksa',
      authorInitials: 'DR',
      category: 'Jobs',
      title: 'Spam Job Posting',
      description:
          'Click here to earn money fast from home no experience needed.',
      location: 'Online',
      contactInfo: 'spam@example.com',
      submittedDate: '4 days ago',
      status: 'removed',
    ),
    _CommunityPost(
      id: 'P008',
      authorName: 'Kamala Herath',
      authorInitials: 'KH',
      category: 'Lost & Found',
      title: 'Inappropriate Content',
      description: '[removed - violated community guidelines]',
      location: 'Unknown',
      contactInfo: 'N/A',
      submittedDate: '5 days ago',
      status: 'removed',
    ),
  ];

  List<_CommunityPost> get _pendingPosts =>
      _posts.where((p) => p.status == 'pending').toList();
  List<_CommunityPost> get _approvedPosts =>
      _posts.where((p) => p.status == 'approved').toList();
  List<_CommunityPost> get _removedPosts =>
      _posts.where((p) => p.status == 'removed').toList();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _approvePost(_CommunityPost post) {
    setState(() {
      post.status = 'approved';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Post approved and published to community feed'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showRemoveDialog(_CommunityPost post) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.errorLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.error,
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Remove this post?',
              style: AppTextStyles.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'The post will be hidden from the community feed. The author will be notified.',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => dialogContext.pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      dialogContext.pop();
                      setState(() {
                        post.status = 'removed';
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Post removed'),
                          backgroundColor: AppColors.error,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: AppColors.textOnPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: const Size(double.infinity, 48),
                      elevation: 0,
                    ),
                    child: const Text('Remove'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard(_CommunityPost post) {
    final isLostAndFound = post.category == 'Lost & Found';
    final categoryBg = isLostAndFound
        ? AppColors.warningLight
        : AppColors.successLight;
    final categoryIcon = isLostAndFound ? AppColors.warning : AppColors.success;
    final categoryIconData = isLostAndFound
        ? Icons.search_outlined
        : Icons.work_outline_rounded;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: categoryBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(categoryIconData, color: categoryIcon, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: categoryBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            post.category,
                            style: AppTextStyles.small.copyWith(
                              color: categoryIcon,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(post.submittedDate, style: AppTextStyles.small),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      post.title,
                      style: AppTextStyles.bodySemiBold,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            post.description,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 14,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  post.location,
                  style: AppTextStyles.small,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.phone_outlined,
                size: 14,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  post.contactInfo,
                  style: AppTextStyles.small,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.secondarySurface,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    post.authorInitials,
                    style: AppTextStyles.small.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text('by ${post.authorName}', style: AppTextStyles.small),
            ],
          ),
          if (post.status == 'pending') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showRemoveDialog(post),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      minimumSize: const Size(double.infinity, 44),
                    ),
                    child: const Text('Remove'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _approvePost(post),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: AppColors.textOnPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      minimumSize: const Size(double.infinity, 44),
                      elevation: 0,
                    ),
                    child: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
          if (post.status == 'approved') ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton(
                onPressed: () => _showRemoveDialog(post),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Remove Post'),
              ),
            ),
          ],
          if (post.status == 'removed') ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Removed by GN Officer',
                style: AppTextStyles.small.copyWith(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.textMuted.withOpacity(0.45)),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _posts.where((p) => p.status == 'pending').length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text('Community Moderation', style: AppTextStyles.h3),
        actions: [
          if (pendingCount > 0)
            Stack(
              clipBehavior: Clip.none,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    Icons.pending_actions_outlined,
                    color: AppColors.textPrimary,
                  ),
                ),
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$pendingCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textMuted,
            labelStyle: AppTextStyles.tab,
            unselectedLabelStyle: AppTextStyles.tabInactive,
            indicator: const UnderlineTabIndicator(
              borderSide: BorderSide(color: AppColors.primary, width: 2.5),
            ),
            tabs: [
              Tab(text: 'Pending ($_pendingPosts.length)'),
              const Tab(text: 'Approved'),
              const Tab(text: 'Removed'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _pendingPosts.isEmpty
              ? _buildEmptyState(
                  Icons.pending_actions_outlined,
                  'No Pending Posts',
                  'All community posts have been reviewed',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  itemCount: _pendingPosts.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) =>
                      _buildPostCard(_pendingPosts[index]),
                ),
          _approvedPosts.isEmpty
              ? _buildEmptyState(
                  Icons.check_circle_outline,
                  'No Approved Posts',
                  'Approved posts will appear here',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  itemCount: _approvedPosts.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) =>
                      _buildPostCard(_approvedPosts[index]),
                ),
          _removedPosts.isEmpty
              ? _buildEmptyState(
                  Icons.delete_sweep_outlined,
                  'No Removed Posts',
                  'Removed posts will appear here',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  itemCount: _removedPosts.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) =>
                      _buildPostCard(_removedPosts[index]),
                ),
        ],
      ),
    );
  }
}

class _CommunityPost {
  final String id;
  final String authorName;
  final String authorInitials;
  final String category;
  final String title;
  final String description;
  final String location;
  final String contactInfo;
  final String submittedDate;
  String status;

  _CommunityPost({
    required this.id,
    required this.authorName,
    required this.authorInitials,
    required this.category,
    required this.title,
    required this.description,
    required this.location,
    required this.contactInfo,
    required this.submittedDate,
    required this.status,
  });
}
