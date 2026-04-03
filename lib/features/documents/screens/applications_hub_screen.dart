import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class ApplicationsHubScreen extends StatefulWidget {
  const ApplicationsHubScreen({super.key});

  @override
  State<ApplicationsHubScreen> createState() => _ApplicationsHubScreenState();
}

class _ApplicationsHubScreenState extends State<ApplicationsHubScreen> {
  String _selectedCategory = 'All';
  String _searchQuery = '';

  final List<Map<String, dynamic>> _applications = [
    {
      'title': 'Residence Certificate',
      'category': 'Personal Identification & Verification',
      'details': [
        'Full Name',
        'NIC Number',
        'Permanent Address',
        'Duration of residence',
        'Purpose of certificate',
        'Contact number',
      ],
      'icon': Icons.verified_user_rounded,
    },
    {
      'title': 'Character Certificate',
      'category': 'Personal Identification & Verification',
      'details': [
        'Full Name',
        'NIC Number',
        'Address',
        'Occupation / Student status',
        'Purpose (job, school, etc.)',
        'Referee details (if required)',
      ],
      'icon': Icons.assignment_ind_rounded,
    },
    {
      'title': 'NIC Application Confirmation',
      'category': 'Personal Identification & Verification',
      'details': [
        'Full Name',
        'Date of Birth',
        'Birth Certificate Number',
        'Address',
        'Parent/Guardian details',
        'Declaration of correctness',
      ],
      'icon': Icons.badge_rounded,
    },
    {
      'title': 'Family Composition Certificate',
      'category': 'Personal Identification & Verification',
      'details': [
        'Head of household name',
        'Address',
        'List of family members (name, age, relationship)',
        'NIC numbers (if available)',
      ],
      'icon': Icons.family_restroom_rounded,
    },
    {
      'title': 'Land Ownership Confirmation',
      'category': 'Land & Property Related',
      'details': [
        'Owner’s name',
        'NIC Number',
        'Address',
        'Land location (address)',
        'Land size',
        'Deed/permit details',
      ],
      'icon': Icons.landscape_rounded,
    },
    {
      'title': 'Boundary Verification',
      'category': 'Land & Property Related',
      'details': [
        'Owner’s name',
        'Land location',
        'Survey plan details',
        'Neighbor details',
        'Issue description',
      ],
      'icon': Icons.map_rounded,
    },
    {
      'title': 'Land Permit Recommendation',
      'category': 'Land & Property Related',
      'details': [
        'Applicant name',
        'NIC Number',
        'Address',
        'Requested land details',
        'Purpose of land use',
      ],
      'icon': Icons.description_rounded,
    },
    {
      'title': 'Samurdhi / Aswesuma Application',
      'category': 'Social Welfare & Benefits',
      'details': [
        'Full Name',
        'NIC Number',
        'Address',
        'Family details',
        'Monthly income',
        'Employment status',
        'Assets owned',
      ],
      'icon': Icons.volunteer_activism_rounded,
    },
    {
      'title': 'Low-Income Certificate',
      'category': 'Social Welfare & Benefits',
      'details': [
        'Applicant name',
        'NIC Number',
        'Address',
        'Occupation',
        'Monthly income',
        'Family dependents',
      ],
      'icon': Icons.savings_rounded,
    },
    {
      'title': 'Disability / Elderly Allowance',
      'category': 'Social Welfare & Benefits',
      'details': [
        'Name',
        'NIC Number',
        'Age',
        'Medical condition (if applicable)',
        'Income details',
        'Family support details',
      ],
      'icon': Icons.accessible_forward_rounded,
    },
    {
      'title': 'Scholarship Application Support',
      'category': 'Education Related',
      'details': [
        'Student name',
        'Date of Birth',
        'School name',
        'Address',
        'Parent income details',
        'Family details',
      ],
      'icon': Icons.school_rounded,
    },
    {
      'title': 'University / Hostel Income Verification',
      'category': 'Education Related',
      'details': [
        'Student name',
        'Parent/Guardian name',
        'Address',
        'Occupation',
        'Monthly income',
        'Number of dependents',
      ],
      'icon': Icons.apartment_rounded,
    },
    {
      'title': 'Passport Verification',
      'category': 'Legal & Official Documentation',
      'details': [
        'Full Name',
        'NIC Number',
        'Address',
        'Duration of residence',
        'Occupation',
      ],
      'icon': Icons.travel_explore_rounded,
    },
    {
      'title': 'Birth/Marriage/Death Confirmation',
      'category': 'Legal & Official Documentation',
      'details': [
        'Relevant person’s name',
        'Date of event',
        'Address',
        'Relationship to applicant',
      ],
      'icon': Icons.fact_check_rounded,
    },
    {
      'title': 'Police Clearance Support',
      'category': 'Legal & Official Documentation',
      'details': [
        'Name',
        'NIC Number',
        'Address',
        'Duration of residence',
        'Purpose',
      ],
      'icon': Icons.gavel_rounded,
    },
    {
      'title': 'Job Character Certificate',
      'category': 'Employment & Migration',
      'details': [
        'Name',
        'NIC Number',
        'Address',
        'Occupation',
        'Purpose (job type)',
      ],
      'icon': Icons.work_rounded,
    },
    {
      'title': 'Foreign Employment Documents',
      'category': 'Employment & Migration',
      'details': [
        'Name',
        'NIC Number',
        'Address',
        'Passport details',
        'Job details abroad',
      ],
      'icon': Icons.flight_takeoff_rounded,
    },
    {
      'title': 'Electricity / Water Connection',
      'category': 'Utility & Service Connections',
      'details': [
        'Applicant name',
        'NIC Number',
        'Address',
        'Proof of residence',
        'Land ownership/permission details',
      ],
      'icon': Icons.electrical_services_rounded,
    },
    {
      'title': 'Business Registration Support',
      'category': 'Miscellaneous / Special Requests',
      'details': [
        'Applicant name',
        'NIC Number',
        'Address',
        'Business type',
        'Business location',
      ],
      'icon': Icons.storefront_rounded,
    },
    {
      'title': 'Disaster Damage Report',
      'category': 'Miscellaneous / Special Requests',
      'details': [
        'Applicant name',
        'Address',
        'Type of disaster',
        'Date of incident',
        'Damage description',
      ],
      'icon': Icons.warning_amber_rounded,
    },
  ];

  List<String> get _categories {
    final values =
        _applications.map((app) => app['category'] as String).toSet().toList()
          ..sort();
    return ['All', ...values];
  }

  List<Map<String, dynamic>> get _filteredApplications {
    final query = _searchQuery.trim().toLowerCase();
    return _applications.where((app) {
      final category = app['category'] as String;
      final title = (app['title'] as String).toLowerCase();
      final categoryLower = category.toLowerCase();
      final details = (app['details'] as List<String>).join(' ').toLowerCase();

      final matchesCategory =
          _selectedCategory == 'All' || category == _selectedCategory;
      final matchesQuery =
          query.isEmpty ||
          title.contains(query) ||
          categoryLower.contains(query) ||
          details.contains(query);

      return matchesCategory && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceGrey.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.textPrimary,
                size: 20,
              ),
            ),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
          ),
        ),
        title: Text(
          'Applications',
          style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border.withOpacity(0.3), height: 1),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          _buildSearchBar(),
          const SizedBox(height: 12),
          _buildCategoryFilters(),
          const SizedBox(height: 8),
          Expanded(child: _buildApplicationList()),
          _buildTrackCard(),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildTrackCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.track_changes_rounded,
                color: AppColors.info,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Track Application Progress',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'See current status and updates for submitted requests.',
                    style: AppTextStyles.small.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => context.push('/documents/tracking'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Track'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Search applications',
          prefixIcon: const Icon(Icons.search_rounded),
          filled: true,
          fillColor: AppColors.card,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.border.withOpacity(0.6)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.border.withOpacity(0.6)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == _selectedCategory;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = category),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.card,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.border.withOpacity(0.6),
                ),
              ),
              child: Text(
                category,
                style: AppTextStyles.caption.copyWith(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemCount: _categories.length,
      ),
    );
  }

  Widget _buildApplicationList() {
    final filtered = _filteredApplications;
    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'No applications found for your current filter.',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      itemCount: filtered.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final app = filtered[index];
        return _buildApplicationCard(app);
      },
    );
  }

  Widget _buildApplicationCard(Map<String, dynamic> app) {
    final title = app['title'] as String;
    final category = app['category'] as String;
    final details = app['details'] as List<String>;
    final icon = app['icon'] as IconData;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceGrey.withOpacity(0.6),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              category,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Required details: ${details.length}',
            style: AppTextStyles.small.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => _showRequiredDetailsSheet(title, details),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.list_alt_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Form Details',
                        style: AppTextStyles.small.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  context.push(
                    '/documents/request',
                    extra: {'documentType': title},
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Apply',
                    style: AppTextStyles.small.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showRequiredDetailsSheet(String title, List<String> details) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.78,
          ),
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Required details for GN submission',
                style: AppTextStyles.small.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView.separated(
                  itemCount: details.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final detail = details[index];
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 7),
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            detail,
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
