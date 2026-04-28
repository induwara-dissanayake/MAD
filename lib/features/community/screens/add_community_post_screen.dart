import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/community_post_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/user_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/vc_components.dart';
import '../repositories/community_post_repository.dart';

enum PostType { general, lostItem, foundItem, jobOpportunity, communityIssue }

class AddCommunityPostScreen extends ConsumerStatefulWidget {
  const AddCommunityPostScreen({super.key});

  @override
  ConsumerState<AddCommunityPostScreen> createState() =>
      _AddCommunityPostScreenState();
}

class _AddCommunityPostScreenState
    extends ConsumerState<AddCommunityPostScreen> {
  PostType _selectedType = PostType.lostItem;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _contactController = TextEditingController();
  bool _isSubmitting = false;

  String _postTypeLabel(PostType type) {
    switch (type) {
      case PostType.general:
        return 'General';
      case PostType.lostItem:
        return 'Lost Item';
      case PostType.foundItem:
        return 'Found Item';
      case PostType.jobOpportunity:
        return 'Job Opportunity';
      case PostType.communityIssue:
        return 'Community Issue';
    }
  }

  IconData _postTypeIcon(PostType type) {
    switch (type) {
      case PostType.general:
        return Icons.forum_outlined;
      case PostType.lostItem:
        return Icons.search_rounded;
      case PostType.foundItem:
        return Icons.inventory_2_outlined;
      case PostType.jobOpportunity:
        return Icons.work_outline_rounded;
      case PostType.communityIssue:
        return Icons.report_problem_outlined;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  String _postTypeKey(PostType type) {
    switch (type) {
      case PostType.general:
        return 'general';
      case PostType.lostItem:
        return 'lost_item';
      case PostType.foundItem:
        return 'found_item';
      case PostType.jobOpportunity:
        return 'job_opportunity';
      case PostType.communityIssue:
        return 'community_issue';
    }
  }

  Future<void> _submitPost() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final authService = ref.read(authServiceProvider);
    final user = authService.currentUser;
    if (user == null) {
      context.go('/auth/login');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final profile = await ref
          .read(userServiceProvider)
          .getUserProfileOnce(user.uid);
      final post = CommunityPostModel(
        id: '',
        userId: user.uid,
        authorName: profile?.fullName ?? user.displayName ?? 'Citizen',
        type: _postTypeKey(_selectedType),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        contact: _contactController.text.trim(),
        status: 'pending_moderation',
        createdAt: DateTime.now(),
      );

      await ref.read(communityPostRepositoryProvider).createPost(post);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post submitted for moderation.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit post: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
          tooltip: 'Back',
        ),
        title: const Text('Create Post'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const VcPageHeader(
                title: 'Submit for moderation',
                subtitle:
                    'General updates, lost items, jobs, and issues become public after GN or committee approval.',
                leadingIcon: Icons.fact_check_outlined,
              ),
              const SizedBox(height: 20),
              // Post type selector
              Text('Post Type', style: AppTextStyles.label),
              const SizedBox(height: 10),
              Wrap(
                children: PostType.values.map((type) {
                  final isSelected = _selectedType == type;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8, bottom: 8),
                    child: SizedBox(
                      width: 150,
                      height: 46,
                      child: Material(
                        color: isSelected ? AppColors.primary : AppColors.card,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedType = type;
                            });
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.border,
                                width: 1.5,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _postTypeIcon(type),
                                  size: 16,
                                  color: isSelected
                                      ? AppColors.textOnPrimary
                                      : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    _postTypeLabel(type),
                                    style: AppTextStyles.small.copyWith(
                                      color: isSelected
                                          ? AppColors.textOnPrimary
                                          : AppColors.textSecondary,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Title field
              Text('Title', style: AppTextStyles.label),
              const SizedBox(height: 6),
              TextFormField(
                controller: _titleController,
                style: AppTextStyles.body,
                decoration: InputDecoration(
                  hintText: _selectedType == PostType.jobOpportunity
                      ? 'e.g., Part-time Sales Assistant'
                      : 'e.g., Lost Golden Retriever Dog',
                  hintStyle: AppTextStyles.caption.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Description field
              Text('Description', style: AppTextStyles.label),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descriptionController,
                style: AppTextStyles.body,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Provide details about your post...',
                  hintStyle: AppTextStyles.caption.copyWith(
                    color: AppColors.textMuted,
                  ),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Location field
              Text('Location', style: AppTextStyles.label),
              const SizedBox(height: 6),
              TextFormField(
                controller: _locationController,
                style: AppTextStyles.body,
                decoration: InputDecoration(
                  hintText: 'e.g., Kaduwela Town',
                  hintStyle: AppTextStyles.caption.copyWith(
                    color: AppColors.textMuted,
                  ),
                  prefixIcon: const Icon(
                    Icons.location_on_outlined,
                    color: AppColors.textMuted,
                    size: 22,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Contact information field
              Text('Contact Information', style: AppTextStyles.label),
              const SizedBox(height: 6),
              TextFormField(
                controller: _contactController,
                style: AppTextStyles.body,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: 'e.g., 077-1234567',
                  hintStyle: AppTextStyles.caption.copyWith(
                    color: AppColors.textMuted,
                  ),
                  prefixIcon: const Icon(
                    Icons.phone_outlined,
                    color: AppColors.textMuted,
                    size: 22,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter contact information';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Post button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitPost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text('Submit for Review', style: AppTextStyles.button),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
