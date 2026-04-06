import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class IncidentDetailScreen extends StatefulWidget {
  const IncidentDetailScreen({super.key});

  @override
  State<IncidentDetailScreen> createState() => _IncidentDetailScreenState();
}

class _IncidentDetailScreenState extends State<IncidentDetailScreen> {
  final String _title = 'Fallen Tree Blocking Main Road';
  final String _description =
      'A large tree fell across the main road near the temple junction during last night\'s storm. Both lanes are blocked. Several vehicles are stranded. Urgent response needed.';
  final String _location = 'Temple Junction, Kaduwela';
  final String _reportedBy = 'Nadeeka Silva';
  final String _reporterNIC = '199512345678';
  final String _reporterInitials = 'NS';
  final String _reportedAt = 'Today at 10:30 AM';
  final String _category = 'Emergency Alert';
  final String _id = 'INC-2026-0089';

  String _selectedStatus = 'Acknowledged';
  final TextEditingController _notesController = TextEditingController();

  final List<Map<String, dynamic>> _statusOptions = [
    {
      'label': 'Acknowledged',
      'desc': 'You are aware and investigating',
      'color': AppColors.info,
    },
    {
      'label': 'In Progress',
      'desc': 'Active response is underway',
      'color': AppColors.warning,
    },
    {
      'label': 'Resolved',
      'desc': 'Incident fully dealt with',
      'color': AppColors.success,
    },
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Widget _buildStatusTile(Map<String, dynamic> option) {
    final isSelected = _selectedStatus == option['label'];
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStatus = option['label'];
        });
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: isSelected ? option['color'] : AppColors.textMuted,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option['label'],
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isSelected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(option['desc'], style: AppTextStyles.small),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_rounded,
                size: 18,
                color: AppColors.primary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncidentHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  size: 28,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_title, style: AppTextStyles.h3, maxLines: 2),
                    const SizedBox(height: 4),
                    Text('Ref: $_id', style: AppTextStyles.caption),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: AppColors.divider),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.location_on_outlined, 'Location', _location),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.access_time_rounded, 'Reported', _reportedAt),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.category_outlined, 'Category', _category),
        ],
      ),
    );
  }

  Widget _buildReporterCard() {
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
          Text('Reported By', style: AppTextStyles.bodySemiBold),
          const SizedBox(height: 12),
          Row(
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
                    _reporterInitials,
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
                    Text(_reportedBy, style: AppTextStyles.bodyMedium),
                    Text('NIC: $_reporterNIC', style: AppTextStyles.caption),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Citizen',
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
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
          Text('Description', style: AppTextStyles.bodySemiBold),
          const SizedBox(height: 10),
          Text(
            _description,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textMuted),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.small.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 2),
              Text(value, style: AppTextStyles.body),
            ],
          ),
        ),
      ],
    );
  }

  void _updateStatus() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Status updated to $_selectedStatus'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    context.pop();
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
        title: Text('Incident Details', style: AppTextStyles.h3),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.priority_high_rounded,
                    size: 14,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'High Priority',
                    style: AppTextStyles.small.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildIncidentHeader(),
                  const SizedBox(height: 16),
                  _buildReporterCard(),
                  const SizedBox(height: 16),
                  _buildDescriptionCard(),
                  const SizedBox(height: 24),
                  Text('Update Status', style: AppTextStyles.h3),
                  const SizedBox(height: 12),
                  ..._statusOptions.map(
                    (opt) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildStatusTile(opt),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Response Notes', style: AppTextStyles.h3),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: TextField(
                      controller: _notesController,
                      maxLines: 4,
                      style: AppTextStyles.body,
                      decoration: InputDecoration(
                        hintText: 'Add response notes...',
                        hintStyle: AppTextStyles.body.copyWith(
                          color: AppColors.textMuted,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () => context.push('/committee/tasks'),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.infoLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.info.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.group_outlined,
                            color: AppColors.info,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Assign to Village Committee',
                                  style: AppTextStyles.bodyMedium,
                                ),
                                Text(
                                  'Delegate follow-up tasks',
                                  style: AppTextStyles.small,
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: AppColors.textMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            decoration: BoxDecoration(
              color: AppColors.card,
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _updateStatus,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Update Incident Status',
                    style: AppTextStyles.button.copyWith(
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
