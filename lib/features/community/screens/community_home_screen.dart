import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/vc_copy.dart';
import '../../../core/models/community_post_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/vc_components.dart';
import '../repositories/community_post_repository.dart';

class CommunityHomeScreen extends ConsumerStatefulWidget {
  const CommunityHomeScreen({super.key});

  @override
  ConsumerState<CommunityHomeScreen> createState() =>
      _CommunityHomeScreenState();
}

class _CommunityHomeScreenState extends ConsumerState<CommunityHomeScreen> {
  String _tab = 'lost_found';

  @override
  Widget build(BuildContext context) {
    final copy = VcCopy.of(context);
    final postsAsync = ref.watch(approvedCommunityPostsProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceParchment,
      appBar: AppBar(
        title: Text(copy.t('communityTitle')),
        actions: [
          IconButton(
            onPressed: () => context.push('/community/moderation'),
            tooltip: copy.t('moderation'),
            icon: const Icon(Icons.fact_check_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/community/add'),
        tooltip: copy.t('addPost'),
        child: const Icon(Icons.add_rounded),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(approvedCommunityPostsProvider),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 92),
          children: [
            Text(
              copy.t('communitySubtitle'),
              style: AppTextStyles.bodyLarge.copyWith(color: AppColors.inkMid),
            ),
            const SizedBox(height: 18),
            _SegmentedTabs(
              selected: _tab,
              lostLabel: copy.t('lostFound'),
              jobsLabel: copy.t('jobs'),
              onChanged: (value) => setState(() => _tab = value),
            ),
            const SizedBox(height: 18),
            postsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => _FeedError(message: '$error'),
              data: (posts) {
                final filtered = posts.where((post) {
                  if (_tab == 'jobs') return post.type == 'job_opportunity';
                  return post.type == 'lost_item' || post.type == 'found_item';
                }).toList();

                if (filtered.isEmpty) {
                  return VcEmptyState(
                    icon: Icons.forum_outlined,
                    title: copy.t('noPosts'),
                    subtitle: copy.t('noPostsBody'),
                    action: FilledButton.icon(
                      onPressed: () => context.push('/community/add'),
                      icon: const Icon(Icons.add_rounded),
                      label: Text(copy.t('addPost')),
                    ),
                  );
                }

                return Column(
                  children: filtered
                      .map(
                        (post) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _CommunityPostCard(post: post),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentedTabs extends StatelessWidget {
  const _SegmentedTabs({
    required this.selected,
    required this.lostLabel,
    required this.jobsLabel,
    required this.onChanged,
  });

  final String selected;
  final String lostLabel;
  final String jobsLabel;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceIvory,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceWarmSand),
      ),
      child: Row(
        children: [
          _TabButton(
            label: lostLabel,
            selected: selected == 'lost_found',
            onTap: () => onChanged('lost_found'),
          ),
          _TabButton(
            label: jobsLabel,
            selected: selected == 'jobs',
            onTap: () => onChanged('jobs'),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.brandGreenSurface : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.label.copyWith(
              color: selected ? AppColors.brandGreen : AppColors.inkMid,
            ),
          ),
        ),
      ),
    );
  }
}

class _CommunityPostCard extends StatelessWidget {
  const _CommunityPostCard({required this.post});

  final CommunityPostModel post;

  @override
  Widget build(BuildContext context) {
    final tone = _typeColor(post.type);

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
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_typeIcon(post.type), color: tone, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.title, style: AppTextStyles.bodySemiBold),
                    const SizedBox(height: 2),
                    Text(
                      '${post.authorName} · ${DateFormat.MMMd().format(post.createdAt)}',
                      style: AppTextStyles.small,
                    ),
                  ],
                ),
              ),
              VcStatusPill(label: _typeLabel(post.type), color: tone),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            post.description,
            style: AppTextStyles.body.copyWith(color: AppColors.inkMid),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (post.location.isNotEmpty)
                _MetaChip(
                  icon: Icons.location_on_outlined,
                  label: post.location,
                ),
              if (post.contact.isNotEmpty)
                _MetaChip(icon: Icons.call_outlined, label: post.contact),
            ],
          ),
        ],
      ),
    );
  }

  static Color _typeColor(String type) {
    switch (type) {
      case 'lost_item':
        return AppColors.statusRejected;
      case 'found_item':
        return AppColors.statusApproved;
      case 'job_opportunity':
        return AppColors.statusReview;
      default:
        return AppColors.brandGreen;
    }
  }

  static IconData _typeIcon(String type) {
    switch (type) {
      case 'lost_item':
        return Icons.search_outlined;
      case 'found_item':
        return Icons.inventory_2_outlined;
      case 'job_opportunity':
        return Icons.work_outline;
      default:
        return Icons.forum_outlined;
    }
  }

  static String _typeLabel(String type) {
    switch (type) {
      case 'lost_item':
        return 'Lost';
      case 'found_item':
        return 'Found';
      case 'job_opportunity':
        return 'Job';
      default:
        return 'Post';
    }
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.brandGreenSurface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.brandGreen),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.small.copyWith(color: AppColors.inkMid),
          ),
        ],
      ),
    );
  }
}

class _FeedError extends StatelessWidget {
  const _FeedError({required this.message});

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
        'Unable to load community feed. $message',
        style: AppTextStyles.caption.copyWith(color: AppColors.error),
      ),
    );
  }
}
