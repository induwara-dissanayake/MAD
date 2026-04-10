import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/models/request_model.dart';
import '../repositories/document_repository.dart';

class PendingRequestsScreen extends ConsumerStatefulWidget {
  const PendingRequestsScreen({super.key});

  @override
  ConsumerState<PendingRequestsScreen> createState() =>
      _PendingRequestsScreenState();
}

class _PendingRequestsScreenState
    extends ConsumerState<PendingRequestsScreen> {
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  final List<String> _filters = [
    'All',
    'Character Certificate',
    'Residence Certificate',
    'Income Certificate',
    'Birth Certificate',
  ];

  List<RequestModel> _filterAndSearchRequests(List<RequestModel> requests) {
    List<RequestModel> results;
    if (_selectedFilter == 'All') {
      results = requests;
    } else {
      results = requests
          .where((r) => r.documentType == _selectedFilter)
          .toList();
    }

    final query = _searchQuery.toLowerCase();
    if (query.isNotEmpty) {
      results = results
          .where(
            (r) =>
                r.fullName.toLowerCase().contains(query) ||
                r.nic.toLowerCase().contains(query),
          )
          .toList();
    }

    return results;
  }

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(pendingRequestsProvider(null));

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
      body: requestsAsync.when(
        data: (requests) => _buildContent(context, requests),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppColors.error,
              ),
              const SizedBox(height: 16),
              Text('Error loading requests', style: AppTextStyles.bodyMedium),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  err.toString(),
                  style: AppTextStyles.caption,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<RequestModel> requests) {
    final filtered = _filterAndSearchRequests(requests);

    return Column(
      children: [
        _buildSearchBar(),
        _buildFilterChips(),
        _buildResultsCount(filtered.length),
        Expanded(child: _buildRequestsList(context, filtered)),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        style: AppTextStyles.body,
        decoration: InputDecoration(
          hintText: 'Search by name or NIC...',
          hintStyle: AppTextStyles.body.copyWith(color: AppColors.textMuted),
          filled: true,
          fillColor: AppColors.card,
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.textMuted,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
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
        separatorBuilder: (_, __) => const SizedBox(width: 8),
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

  Widget _buildResultsCount(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Text(
        '$count result${count == 1 ? "" : "s"}',
        style: AppTextStyles.caption,
      ),
    );
  }

  Widget _buildRequestsList(BuildContext context, List<RequestModel> filtered) {
    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 56,
              color: AppColors.textMuted.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'No matching requests',
              style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 4),
            Text(
              'Try adjusting your search or filter',
              style: AppTextStyles.caption,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        return _buildRequestCard(context, filtered[index]);
      },
    );
  }

  Widget _buildRequestCard(BuildContext context, RequestModel request) {
    // Extract first and last initial for avatar
    final initials = request.fullName.isNotEmpty
        ? (request.fullName.split(' ')[0][0] +
                (request.fullName.split(' ').length > 1
                    ? request.fullName.split(' ')[1][0]
                    : ''))
            .toUpperCase()
        : 'N/A';

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
                initials,
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
                Text(request.fullName, style: AppTextStyles.bodySemiBold),
                const SizedBox(height: 4),
                Text(request.documentType, style: AppTextStyles.caption),
                const SizedBox(height: 2),
                Text(
                  'Submitted: ${_formatDate(request.submittedAt)}',
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
                context.push('/official/review/${request.id}');
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.day} ${_monthName(date.month)} ${date.year}';
    }
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }
}
