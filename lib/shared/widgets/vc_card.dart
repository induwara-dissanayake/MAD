import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class VcCard extends StatelessWidget {
  const VcCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.backgroundColor,
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(8);
    final content = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.card,
        borderRadius: radius,
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, borderRadius: radius, child: content),
    );
  }
}

class VcDashboardCard extends StatelessWidget {
  const VcDashboardCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    this.backgroundColor = AppColors.secondaryLight,
    this.iconColor = AppColors.primary,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return VcCard(
      onTap: onTap,
      backgroundColor: backgroundColor,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodySemiBold),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    style: AppTextStyles.caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: iconColor, size: 22),
        ],
      ),
    );
  }
}

class VcInfoCard extends StatelessWidget {
  const VcInfoCard({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.trailingWidget,
    this.leadingIcon,
    this.leadingIconColor,
    this.leadingIconBg,
    this.onTap,
    this.padding,
  });

  final String title;
  final String? subtitle;
  final String? trailing;
  final Widget? trailingWidget;
  final IconData? leadingIcon;
  final Color? leadingIconColor;
  final Color? leadingIconBg;
  final VoidCallback? onTap;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return VcCard(
      onTap: onTap,
      padding: padding ?? const EdgeInsets.all(14),
      child: Row(
        children: [
          if (leadingIcon != null) ...[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: leadingIconBg ?? AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                leadingIcon,
                color: leadingIconColor ?? AppColors.primary,
                size: 21,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodySemiBold,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: AppTextStyles.caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            Text(trailing!, style: AppTextStyles.captionMedium),
          ],
          if (trailingWidget != null) ...[
            const SizedBox(width: 8),
            trailingWidget!,
          ],
        ],
      ),
    );
  }
}
