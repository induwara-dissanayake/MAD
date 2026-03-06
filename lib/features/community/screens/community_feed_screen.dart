import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class CommunityFeedScreen extends StatefulWidget {
  const CommunityFeedScreen({super.key});

  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const List<Map<String, String>> _lostFoundItems = [
    {
      'type': 'Lost',
      'title': 'Lost Golden Retriever Dog',
      'description':
          'Male golden retriever, 3 years old, wearing a blue collar with name tag "Buddy". Last seen near Kaduwela town park.',
      'location': 'Kaduwela Town Park',
      'date': 'Feb 22, 2026',
      'contact': '077-1234567',
    },
    {
      'type': 'Found',
      'title': 'Found National Identity Card',
      'description':
          'National Identity Card found near the bus stop at Malabe Junction. Owner can claim by providing details.',
      'location': 'Malabe Junction',
      'date': 'Feb 21, 2026',
      'contact': '071-9876543',
    },
    {
      'type': 'Lost',
      'title': 'Lost School Bag',
      'description':
          'Blue school bag with textbooks and a pencil case. Lost on the school bus route from Kaduwela to Athurugiriya.',
      'location': 'Kaduwela - Athurugiriya Road',
      'date': 'Feb 20, 2026',
      'contact': '076-5551234',
    },
    {
      'type': 'Found',
      'title': 'Found Set of Keys',
      'description':
          'A set of house keys with a red keychain found near the Kaduwela Community Hall entrance on Saturday morning.',
      'location': 'Kaduwela Community Hall',
      'date': 'Feb 19, 2026',
      'contact': '078-4443210',
    },
  ];

  static const List<Map<String, String>> _jobItems = [
    {
      'title': 'Part-time Sales Assistant',
      'company': 'Saman Grocery Store',
      'location': 'Kaduwela Town',
      'salary': 'LKR 25,000 - 30,000/month',
      'date': 'Feb 22, 2026',
      'contact': '077-2223344',
    },
    {
      'title': 'Tuk-Tuk Driver Needed',
      'company': 'Nimal Fernando',
      'location': 'Malabe Area',
      'salary': 'Commission based',
      'date': 'Feb 20, 2026',
      'contact': '071-5556677',
    },
    {
      'title': 'Sewing Machine Operator',
      'company': 'Lanka Garments Workshop',
      'location': 'Kaduwela Industrial Zone',
      'salary': 'LKR 35,000 - 45,000/month',
      'date': 'Feb 18, 2026',
      'contact': '011-2345678',
    },
    {
      'title': 'Home Tutor for O/L Mathematics',
      'company': 'Mrs. Perera',
      'location': 'Athurugiriya',
      'salary': 'LKR 1,500 per session',
      'date': 'Feb 16, 2026',
      'contact': '076-8889900',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        title: const Text(
          'Community',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.textOnPrimary,
          indicatorWeight: 3,
          labelColor: AppColors.textOnPrimary,
          unselectedLabelColor: AppColors.textOnPrimary.withOpacity(0.6),
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: 'Lost & Found'),
            Tab(text: 'Jobs & Opportunities'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildLostFoundTab(), _buildJobsTab()],
      ),
      floatingActionButton: SizedBox(
        width: 56,
        height: 56,
        child: FloatingActionButton(
          onPressed: () {
            context.push('/community/add');
          },
          backgroundColor: AppColors.primary,
          tooltip: 'Add post',
          child: const Icon(
            Icons.add_rounded,
            color: AppColors.textOnPrimary,
            size: 28,
          ),
        ),
      ),
    );
  }

  Widget _buildLostFoundTab() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _lostFoundItems.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = _lostFoundItems[index];
        final isLost = item['type'] == 'Lost';

        return Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo placeholder
              Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.secondarySurface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.camera_alt_outlined,
                        size: 36,
                        color: AppColors.textMuted.withOpacity(0.5),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'No photo',
                        style: AppTextStyles.small.copyWith(
                          color: AppColors.textMuted.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isLost
                            ? AppColors.accentRed
                            : AppColors.accentGreen,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        item['type']!,
                        style: AppTextStyles.small.copyWith(
                          color: isLost ? AppColors.error : AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Title
                    Text(
                      item['title']!,
                      style: AppTextStyles.bodySemiBold,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // Description
                    Text(
                      item['description']!,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),

                    // Location + Date row
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item['location']!,
                            style: AppTextStyles.small,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 12,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(item['date']!, style: AppTextStyles.small),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Contact info
                    const Divider(
                      color: AppColors.divider,
                      thickness: 1,
                      height: 1,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          Icons.phone_outlined,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Contact: ${item['contact']}',
                          style: AppTextStyles.captionMedium.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildJobsTab() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _jobItems.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final job = _jobItems[index];

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.accentPurple,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.work_outline_rounded,
                      color: Color(0xFF7C3AED),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job['title']!,
                          style: AppTextStyles.bodySemiBold,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(job['company']!, style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Location
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(job['location']!, style: AppTextStyles.caption),
                ],
              ),
              const SizedBox(height: 6),

              // Salary
              if (job['salary'] != null && job['salary']!.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(
                      Icons.payments_outlined,
                      size: 16,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      job['salary']!,
                      style: AppTextStyles.captionMedium.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
              ],

              // Date
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 14,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text('Posted: ${job['date']}', style: AppTextStyles.small),
                ],
              ),
              const SizedBox(height: 12),

              // Contact button
              SizedBox(
                height: 48,
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Contact: ${job['contact']}'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.phone_outlined,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  label: Text(
                    'Contact',
                    style: AppTextStyles.captionMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
