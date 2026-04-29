import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/community_post_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../repositories/community_post_repository.dart';

class CommunityModerationScreen extends ConsumerWidget {
  const CommunityModerationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingCommunityPostsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Community Moderation'),
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
      body: pendingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Failed to load posts: $error')),
        data: (posts) {
          if (posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.verified_rounded,
                    size: 64,
                    color: AppColors.success.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No posts waiting for moderation',
                    style: AppTextStyles.body,
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: posts.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) =>
                _PostModerationCard(post: posts[index]),
          );
        },
      ),
    );
  }
}

class _PostModerationCard extends ConsumerStatefulWidget {
  final CommunityPostModel post;

  const _PostModerationCard({required this.post});

  @override
  ConsumerState<_PostModerationCard> createState() =>
      _PostModerationCardState();
}

class _PostModerationCardState extends ConsumerState<_PostModerationCard> {
  bool _isBusy = false;

  Future<void> _approve() async {
    await _moderate((uid) {
      return ref
          .read(communityPostRepositoryProvider)
          .approvePost(post: widget.post, moderatorUid: uid);
    }, 'Post approved');
  }

  Future<void> _reject() async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Post'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Optional reason shown to the citizen',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason == null) return;

    await _moderate((uid) {
      return ref
          .read(communityPostRepositoryProvider)
          .rejectPost(post: widget.post, moderatorUid: uid, reason: reason);
    }, 'Post removed');
  }

  Future<void> _moderate(
    Future<void> Function(String uid) action,
    String successMessage,
  ) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => _isBusy = true);
    try {
      await action(uid);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Moderation failed: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  post.title,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                post.type.replaceAll('_', ' '),
                style: AppTextStyles.small.copyWith(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('By ${post.authorName}', style: AppTextStyles.small),
          const SizedBox(height: 12),
          Text(post.description, style: AppTextStyles.body),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16),
              const SizedBox(width: 4),
              Expanded(child: Text(post.location, style: AppTextStyles.small)),
              const SizedBox(width: 8),
              const Icon(Icons.phone_outlined, size: 16),
              const SizedBox(width: 4),
              Text(post.contact, style: AppTextStyles.small),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isBusy ? null : _approve,
                  icon: const Icon(Icons.check_circle_rounded, size: 18),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isBusy ? null : _reject,
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('Remove'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
