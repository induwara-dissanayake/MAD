import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class NoticeHistoryScreen extends StatefulWidget {
  const NoticeHistoryScreen({super.key});

  @override
  State<NoticeHistoryScreen> createState() => _NoticeHistoryScreenState();
}

class _NoticeHistoryScreenState extends State<NoticeHistoryScreen> {
  String _selectedCategory = 'All';
  final List<String> _categories = [
    'All',
    'General',
    'Health',
    'Emergency',
    'Event',
    'Infrastructure',
  ];

  List<_Notice> _notices = [
    _Notice(
      id: 'N001',
      title: 'Dengue Prevention Drive',
      category: 'Health',
      description:
          'The MOH office will conduct a dengue prevention inspection on 10th March. Please ensure your compounds are cleared of stagnant water.',
      postedDate: 'Mar 8, 2026',
      hasAttachment: true,
      viewCount: 234,
    ),
    _Notice(
      id: 'N002',
      title: 'Road Closure — Temple Road',
      category: 'Infrastructure',
      description:
          'Temple Road will be closed for repairs from 9am to 5pm on 12th March. Please use alternative routes.',
      postedDate: 'Mar 7, 2026',
      hasAttachment: false,
      viewCount: 187,
    ),
    _Notice(
      id: 'N003',
      title: 'Samurdhi Distribution Schedule',
      category: 'General',
      description:
          'Samurdhi payments for March will be distributed on the 15th from 9am at the GN office. Please bring your ID card.',
      postedDate: 'Mar 5, 2026',
      hasAttachment: true,
      viewCount: 312,
    ),
    _Notice(
      id: 'N004',
      title: 'Village Annual Meeting',
      category: 'Event',
      description:
          'The annual village meeting will be held at the community hall on March 20th at 6pm. All residents are welcome.',
      postedDate: 'Mar 3, 2026',
      hasAttachment: false,
      viewCount: 145,
    ),
    _Notice(
      id: 'N005',
      title: 'Water Supply Interruption',
      category: 'Infrastructure',
      description:
          'Scheduled maintenance will cause water supply interruption in the eastern sector on March 22nd from 8am to 2pm.',
      postedDate: 'Feb 28, 2026',
      hasAttachment: false,
      viewCount: 98,
    ),
    _Notice(
      id: 'N006',
      title: 'COVID Booster Vaccination',
      category: 'Health',
      description:
          'Free COVID booster vaccinations will be available at the GN office on March 25th. Bring your vaccination card.',
      postedDate: 'Feb 25, 2026',
      hasAttachment: true,
      viewCount: 267,
    ),
  ];

  List<_Notice> get _filteredNotices => _selectedCategory == 'All'
      ? _notices
      : _notices.where((n) => n.category == _selectedCategory).toList();

  Color _categoryColor(String category) {
    switch (category) {
      case 'Emergency':
        return AppColors.error;
      case 'Health':
        return AppColors.info;
      case 'Event':
        return AppColors.success;
      case 'Infrastructure':
        return AppColors.warning;
      default:
        return AppColors.primary;
    }
  }

  Color _categoryBgColor(String category) {
    switch (category) {
      case 'Emergency':
        return AppColors.errorLight;
      case 'Health':
        return AppColors.infoLight;
      case 'Event':
        return AppColors.successLight;
      case 'Infrastructure':
        return AppColors.warningLight;
      default:
        return AppColors.secondarySurface;
    }
  }

  Widget _buildNoticeCard(_Notice notice) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showNoticeDetail(notice),
        borderRadius: BorderRadius.circular(14),
        child: Container(
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _categoryBgColor(notice.category),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      notice.category,
                      style: AppTextStyles.small.copyWith(
                        color: _categoryColor(notice.category),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(notice.postedDate, style: AppTextStyles.small),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                notice.title,
                style: AppTextStyles.bodySemiBold,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                notice.description,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Divider(color: AppColors.divider, height: 1),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.visibility_outlined,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text('${notice.viewCount} views', style: AppTextStyles.small),
                  if (notice.hasAttachment) ...[
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.attach_file_rounded,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text('Attachment', style: AppTextStyles.small),
                  ],
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _showDeleteDialog(notice),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.errorLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNoticeDetail(_Notice notice) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: Text(notice.title, style: AppTextStyles.h3)),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _categoryBgColor(notice.category),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    notice.category,
                    style: AppTextStyles.small.copyWith(
                      color: _categoryColor(notice.category),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(notice.postedDate, style: AppTextStyles.small),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              notice.description,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
            if (notice.hasAttachment) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.picture_as_pdf_outlined,
                      color: AppColors.error,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'notice_attachment.pdf',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                    Text(
                      'View',
                      style: AppTextStyles.captionMedium.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.success.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.verified_rounded,
                    color: AppColors.success,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Verified by GN Officer — Nimal Fernando',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(_Notice notice) {
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
                Icons.delete_forever_rounded,
                color: AppColors.error,
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Delete Notice?',
              style: AppTextStyles.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'This notice will be permanently removed from the notice board.',
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
                        _notices.removeWhere((n) => n.id == notice.id);
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Notice deleted'),
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
                    child: const Text('Delete'),
                  ),
                ),
              ],
            ),
          ],
        ),
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
        title: Text('My Notices', style: AppTextStyles.h3),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/official/post-notice'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: AppColors.textOnPrimary),
        label: Text(
          'New Notice',
          style: AppTextStyles.buttonSmall.copyWith(
            color: AppColors.textOnPrimary,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Column(
                  children: [
                    Text(
                      '${_notices.length}',
                      style: AppTextStyles.h2.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    Text('Total Notices', style: AppTextStyles.small),
                  ],
                ),
                const SizedBox(width: 20),
                Column(
                  children: [
                    Text(
                      '${_notices.where((n) => n.category == 'Health').length}',
                      style: AppTextStyles.h2.copyWith(color: AppColors.info),
                    ),
                    Text('Health', style: AppTextStyles.small),
                  ],
                ),
                const SizedBox(width: 20),
                Column(
                  children: [
                    Text(
                      '${_notices.where((n) => n.category == 'Emergency').length}',
                      style: AppTextStyles.h2.copyWith(color: AppColors.error),
                    ),
                    Text('Emergency', style: AppTextStyles.small),
                  ],
                ),
                const Spacer(),
                Icon(
                  Icons.campaign_rounded,
                  color: AppColors.primary,
                  size: 32,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              itemCount: _categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                    child: Text(
                      category,
                      style: AppTextStyles.captionMedium.copyWith(
                        color: isSelected
                            ? AppColors.textOnPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: _filteredNotices.isEmpty
                ? _buildEmptyState(
                    Icons.article_outlined,
                    'No notices found',
                    'Try a different category filter',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    itemCount: _filteredNotices.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) =>
                        _buildNoticeCard(_filteredNotices[index]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _Notice {
  final String id;
  final String title;
  final String category;
  final String description;
  final String postedDate;
  final bool hasAttachment;
  final int viewCount;

  const _Notice({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.postedDate,
    required this.hasAttachment,
    required this.viewCount,
  });
}
