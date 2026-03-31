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
      'title': 'Character Certificate',
      'description': 'For employment and visa applications',
      'category': 'Certificates',
      'eta': '2-5 working days',
      'icon': Icons.verified_user_rounded,
    },
    {
      'title': 'Residence Certificate',
      'description': 'Official proof of residence in GN division',
      'category': 'Certificates',
      'eta': '1-3 working days',
      'icon': Icons.home_rounded,
    },
    {
      'title': 'Income Certificate',
      'description': 'For subsidies, scholarships and aid',
      'category': 'Certificates',
      'eta': '2-4 working days',
      'icon': Icons.account_balance_wallet_rounded,
    },
    {
      'title': 'Birth Certificate',
      'description': 'Birth registration and certified copies',
      'category': 'Civil Records',
      'eta': '3-7 working days',
      'icon': Icons.child_care_rounded,
    },
    {
      'title': 'Identity Verification',
      'description': 'NIC-based identity confirmation letter',
      'category': 'Identity',
      'eta': '1-2 working days',
      'icon': Icons.badge_rounded,
    },
    {
      'title': 'Land Ownership',
      'description': 'Land title and ownership-related letters',
      'category': 'Property',
      'eta': '4-8 working days',
      'icon': Icons.landscape_rounded,
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
      final description = (app['description'] as String).toLowerCase();

      final matchesCategory =
          _selectedCategory == 'All' || category == _selectedCategory;
      final matchesQuery =
          query.isEmpty || title.contains(query) || description.contains(query);

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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Choose an application type to submit to the GN officer.',
              style: AppTextStyles.small.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 12),
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
    final description = app['description'] as String;
    final category = app['category'] as String;
    final eta = app['eta'] as String;
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
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
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
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: AppTextStyles.small.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 16,
                color: AppColors.info,
              ),
              const SizedBox(width: 6),
              Text(
                'Estimated: $eta',
                style: AppTextStyles.caption.copyWith(color: AppColors.info),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  context.push(
                    '/documents/request',
                    extra: {'documentType': title},
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Apply'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
