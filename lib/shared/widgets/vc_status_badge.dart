import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class VcStatusBadge extends StatelessWidget {
  final String label;
  final StatusType type;

  const VcStatusBadge({super.key, required this.label, required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTextStyles.small.copyWith(
          color: _textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color get _backgroundColor {
    switch (type) {
      case StatusType.pending:
        return AppColors.accentYellow;
      case StatusType.inReview:
        return AppColors.accentBlue;
      case StatusType.approved:
        return AppColors.accentGreen;
      case StatusType.rejected:
        return AppColors.accentRed;
      case StatusType.info:
        return AppColors.accentPurple;
    }
  }

  Color get _textColor {
    switch (type) {
      case StatusType.pending:
        return AppColors.warning;
      case StatusType.inReview:
        return AppColors.info;
      case StatusType.approved:
        return AppColors.success;
      case StatusType.rejected:
        return AppColors.error;
      case StatusType.info:
        return const Color(0xFF6D28D9);
    }
  }
}

enum StatusType { pending, inReview, approved, rejected, info }

StatusType statusTypeFromString(String status) {
  switch (status.toLowerCase()) {
    case 'pending':
      return StatusType.pending;
    case 'in review':
    case 'in_review':
      return StatusType.inReview;
    case 'approved':
      return StatusType.approved;
    case 'rejected':
      return StatusType.rejected;
    default:
      return StatusType.info;
  }
}

class VcVerifiedBadge extends StatelessWidget {
  final double size;

  const VcVerifiedBadge({super.key, this.size = 18});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.check, color: Colors.white, size: size - 6),
    );
  }
}
