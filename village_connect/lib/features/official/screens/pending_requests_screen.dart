import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class PendingRequestsScreen extends StatefulWidget {
  const PendingRequestsScreen({super.key});

  @override
  State<PendingRequestsScreen> createState() => _PendingRequestsScreenState();
}

class _PendingRequestsScreenState extends State<PendingRequestsScreen> {
  String _selectedFilter = 'All';

  final List<String> _filters = [
    'All',
    'Character Cert',
    'Residence Cert',
    'Income Cert',
  ];

  final List<_RequestItem> _requests = [
    _RequestItem(
      citizenName: 'Nadeeka Silva',
      documentType: 'Character Certificate',
      submittedDate: '22 Feb 2026',
      nic: '199512345678',
      initials: 'NS',
    ),
    _RequestItem(
      citizenName: 'Ruwan Jayasinghe',
      documentType: 'Residence Certificate',
      submittedDate: '21 Feb 2026',
      nic: '198823456789',
      initials: 'RJ',
    ),
    _RequestItem(
      citizenName: 'Malini Kumari',
      documentType: 'Income Certificate',
      submittedDate: '20 Feb 2026',
      nic: '197634567890',
      initials: 'MK',
    ),
    _RequestItem(
      citizenName: 'Sunil Bandara',
      documentType: 'Character Certificate',
      submittedDate: '19 Feb 2026',
      nic: '200045678901',
      initials: 'SB',
    ),
    _RequestItem(
      citizenName: 'Priya Fernando',
      documentType: 'Residence Certificate',
      submittedDate: '18 Feb 2026',
      nic: '199256789012',
      initials: 'PF',
    ),
    _RequestItem(
      citizenName: 'Amara Wijesinghe',
      documentType: 'Character Certificate',
      submittedDate: '17 Feb 2026',
      nic: '198567890123',
      initials: 'AW',
    ),
    _RequestItem(
      citizenName: 'Dinesh Rajapaksa',
      documentType: 'Income Certificate',
      submittedDate: '16 Feb 2026',
      nic: '199378901234',
      initials: 'DR',
    ),
    _RequestItem(
      citizenName: 'Kamala Herath',
      documentType: 'Residence Certificate',
      submittedDate: '15 Feb 2026',
      nic: '198189012345',
      initials: 'KH',
    ),
  ];

  List<_RequestItem> get _filteredRequests {
    if (_selectedFilter == 'All') return _requests;

    final typeMap = {
      'Character Cert': 'Character Certificate',
      'Residence Cert': 'Residence Certificate',
      'Income Cert': 'Income Certificate',
    };
    final targetType = typeMap[_selectedFilter] ?? '';
    return _requests.where((r) => r.documentType == targetType).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () => context.pop(),
          tooltip: 'Go back',
        ),
        title: Text(
          'Pending Requests',
          style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.filter_list_rounded,
              color: AppColors.textPrimary,
            ),
            onPressed: () {
              // Filter action
            },
            tooltip: 'Filter requests',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(child: _buildRequestsList()),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: _filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilter = filter;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                ),
              ),
              child: Text(
                filter,
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
    );
  }

  Widget _buildRequestsList() {
    final filtered = _filteredRequests;

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 56,
              color: AppColors.textMuted.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'No pending requests',
              style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount: filtered.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        return _buildRequestCard(filtered[index]);
      },
    );
  }

  Widget _buildRequestCard(_RequestItem request) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.secondarySurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                request.initials,
                style: AppTextStyles.captionMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(request.citizenName, style: AppTextStyles.bodySemiBold),
                const SizedBox(height: 4),
                Text(request.documentType, style: AppTextStyles.caption),
                const SizedBox(height: 2),
                Text(
                  'Submitted: ${request.submittedDate}',
                  style: AppTextStyles.small,
                ),
                const SizedBox(height: 2),
                Text(
                  'NIC: ${request.nic}',
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                context.push('/official/review');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: Text(
                'Review',
                style: AppTextStyles.buttonSmall.copyWith(
                  color: AppColors.textOnPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestItem {
  final String citizenName;
  final String documentType;
  final String submittedDate;
  final String nic;
  final String initials;

  const _RequestItem({
    required this.citizenName,
    required this.documentType,
    required this.submittedDate,
    required this.nic,
    required this.initials,
  });
}
