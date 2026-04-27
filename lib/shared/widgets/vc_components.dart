import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class VcPageHeader extends StatelessWidget {
  const VcPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leadingIcon,
    this.trailing,
    this.tone = AppColors.primary,
    this.dark = false,
  });

  final String title;
  final String? subtitle;
  final IconData? leadingIcon;
  final Widget? trailing;
  final Color tone;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final fg = dark ? AppColors.textOnPrimary : AppColors.textPrimary;
    final sub = dark
        ? AppColors.textOnPrimary.withValues(alpha: 0.78)
        : AppColors.textSecondary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: dark ? tone : AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: dark ? null : Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          if (leadingIcon != null) ...[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: dark
                    ? Colors.white.withValues(alpha: 0.16)
                    : tone.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(leadingIcon, color: dark ? Colors.white : tone),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.h2.copyWith(color: fg)),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: AppTextStyles.caption.copyWith(color: sub),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
    );
  }
}

class VcStepIndicator extends StatelessWidget {
  const VcStepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.labels,
  });

  final int currentStep;
  final int totalSteps;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.card,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      child: Column(
        children: [
          Row(
            children: List.generate(totalSteps * 2 - 1, (index) {
              if (index.isOdd) {
                final stepBefore = index ~/ 2;
                return Expanded(
                  child: Container(
                    height: 2,
                    color: stepBefore < currentStep
                        ? AppColors.primary
                        : AppColors.divider,
                  ),
                );
              }

              final step = index ~/ 2;
              final isCompleted = step < currentStep;
              final isActive = step == currentStep;
              return Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: isCompleted || isActive
                      ? AppColors.primary
                      : AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isCompleted || isActive
                        ? AppColors.primary
                        : AppColors.border,
                  ),
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 16,
                        )
                      : Text(
                          '${step + 1}',
                          style: AppTextStyles.small.copyWith(
                            color: isActive
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(totalSteps, (index) {
              final isActive = index == currentStep;
              final isCompleted = index < currentStep;
              return Expanded(
                child: Text(
                  labels[index],
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.small.copyWith(
                    color: isActive
                        ? AppColors.primary
                        : isCompleted
                        ? AppColors.textSecondary
                        : AppColors.textMuted,
                    fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class VcSectionHeader extends StatelessWidget {
  const VcSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.h3),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(subtitle!, style: AppTextStyles.caption),
              ],
            ],
          ),
        ),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

class VcStatusPill extends StatelessWidget {
  const VcStatusPill({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: AppTextStyles.small.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class VcMetricTile extends StatelessWidget {
  const VcMetricTile({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value, style: AppTextStyles.h2),
          const SizedBox(height: 2),
          Text(title, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class VcActionTile extends StatelessWidget {
  const VcActionTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.bodySemiBold),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              trailing ??
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textMuted,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class VcEmptyState extends StatelessWidget {
  const VcEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 30, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTextStyles.bodySemiBold,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                style: AppTextStyles.caption,
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

class VcOfflineBanner extends StatelessWidget {
  const VcOfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.warningLight,
      child: Row(
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            size: 18,
            color: AppColors.warning,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'You are offline. Some features may be unavailable.',
              style: AppTextStyles.small.copyWith(
                color: AppColors.warning,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
