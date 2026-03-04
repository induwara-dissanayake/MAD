import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _searchController = TextEditingController();

  final List<_SystemUser> _users = [
    _SystemUser('Kasun Perera', 'kasun@vc.lk', 'Resident', true),
    _SystemUser('Nimal Silva', 'nimal@vc.lk', 'GN Officer', true),
    _SystemUser('Priya Fernando', 'priya@vc.lk', 'Committee', true),
    _SystemUser('Amaya Dias', 'amaya@vc.lk', 'Resident', true),
    _SystemUser('Ranjith Kumara', 'ranjith@vc.lk', 'Committee', false),
    _SystemUser('Sunil Jayawardena', 'sunil@vc.lk', 'Resident', true),
    _SystemUser('Lahiru Mendis', 'lahiru@vc.lk', 'Admin', true),
    _SystemUser('Malini Rathnayake', 'malini@vc.lk', 'Resident', false),
  ];

  final List<_AuditLog> _auditLogs = [
    _AuditLog('Nimal Silva', 'Approved certificate request REQ-045', '10 min ago', 'approve'),
    _AuditLog('Lahiru Mendis', 'Changed role for Priya Fernando to Committee', '25 min ago', 'role'),
    _AuditLog('Nimal Silva', 'Posted official notice: Road Closure Alert', '1 hr ago', 'notice'),
    _AuditLog('Kasun Perera', 'Submitted certificate request REQ-046', '2 hrs ago', 'request'),
    _AuditLog('Lahiru Mendis', 'Deactivated user account: Malini Rathnayake', '3 hrs ago', 'user'),
    _AuditLog('Nimal Silva', 'Rejected certificate request REQ-044', '5 hrs ago', 'reject'),
    _AuditLog('Priya Fernando', 'Created new poll: Community Well Location', '1 day ago', 'poll'),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'Admin':
        return AppColors.error;
      case 'GN Officer':
        return AppColors.primary;
      case 'Committee':
        return const Color(0xFF7B1FA2);
      default:
        return AppColors.success;
    }
  }

  IconData _logIcon(String type) {
    switch (type) {
      case 'approve':
        return Icons.check_circle_rounded;
      case 'reject':
        return Icons.cancel_rounded;
      case 'role':
        return Icons.admin_panel_settings_rounded;
      case 'notice':
        return Icons.campaign_rounded;
      case 'request':
        return Icons.description_rounded;
      case 'user':
        return Icons.person_off_rounded;
      case 'poll':
        return Icons.poll_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  Color _logColor(String type) {
    switch (type) {
      case 'approve':
        return AppColors.success;
      case 'reject':
        return AppColors.error;
      case 'role':
        return const Color(0xFF7B1FA2);
      case 'notice':
        return AppColors.primary;
      case 'request':
        return AppColors.info;
      case 'user':
        return AppColors.warning;
      case 'poll':
        return const Color(0xFF00897B);
      default:
        return AppColors.textMuted;
    }
  }

  void _showEditRoleDialog(_SystemUser user) {
    String selectedRole = user.role;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text('Edit User Role', style: AppTextStyles.h3),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.name, style: AppTextStyles.bodyMedium),
              Text(user.email, style: AppTextStyles.small),
              const SizedBox(height: 20),
              Text('Assign Role', style: AppTextStyles.label),
              const SizedBox(height: 8),
              ...['Resident', 'GN Officer', 'Committee', 'Admin'].map((role) {
                return RadioListTile<String>(
                  title: Text(role, style: AppTextStyles.body),
                  value: role,
                  groupValue: selectedRole,
                  onChanged: (v) => setDialogState(() => selectedRole = v!),
                  activeColor: AppColors.primary,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                );
              }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Role updated to $selectedRole')),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: AnimationLimiter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: AnimationConfiguration.toStaggeredList(
              duration: const Duration(milliseconds: 375),
              childAnimationBuilder: (widget) => SlideAnimation(
                verticalOffset: 40,
                child: FadeInAnimation(child: widget),
              ),
              children: [
                // Stats Cards
                _buildStatsRow(),
                const SizedBox(height: 28),

                // System Health
                _buildSystemHealth(),
                const SizedBox(height: 28),

                // User Management
                _buildSectionHeader('User & Role Management', Icons.people_rounded),
                const SizedBox(height: 12),
                _buildSearchBar(),
                const SizedBox(height: 12),
                _buildUserList(),
                const SizedBox(height: 28),

                // Analytics
                _buildSectionHeader('Analytics Overview', Icons.analytics_rounded),
                const SizedBox(height: 12),
                _buildAnalyticsChart(),
                const SizedBox(height: 28),

                // Audit Logs
                _buildSectionHeader('Recent Audit Logs', Icons.security_rounded),
                const SizedBox(height: 12),
                _buildAuditLogs(),
                const SizedBox(height: 28),

                // CMS Links
                _buildSectionHeader('Content Management', Icons.edit_note_rounded),
                const SizedBox(height: 12),
                _buildCMSLinks(),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _statsCard('Total Users', '156', Icons.people_rounded, AppColors.primary,
            AppColors.primaryLight),
        const SizedBox(width: 12),
        _statsCard('Active Today', '48', Icons.trending_up_rounded,
            AppColors.success, AppColors.successLight),
        const SizedBox(width: 12),
        _statsCard('Requests', '23', Icons.description_rounded,
            AppColors.warning, AppColors.warningLight),
      ],
    );
  }

  Widget _statsCard(
      String label, String value, IconData icon, Color color, Color bgColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 10),
            Text(value,
                style: AppTextStyles.h2
                    .copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label,
                style: AppTextStyles.small.copyWith(
                    fontSize: 11, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemHealth() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.successLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.check_circle_rounded,
                color: AppColors.success, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('System Status: Healthy',
                    style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.success)),
                Text('All services running • Last sync: 2 min ago',
                    style: AppTextStyles.small
                        .copyWith(color: AppColors.success.withOpacity(0.8))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.success,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('99.9%',
                style: AppTextStyles.captionMedium.copyWith(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 22, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(title, style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildSearchBar() {
    return TextFormField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search users...',
        prefixIcon:
            const Icon(Icons.search_rounded, size: 20, color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.surfaceGrey,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }

  Widget _buildUserList() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Column(
        children: List.generate(_users.length, (i) {
          final user = _users[i];
          return Column(
            children: [
              if (i > 0)
                const Divider(height: 1, indent: 64, color: AppColors.divider),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showEditRoleDialog(user),
                  borderRadius: i == 0
                      ? const BorderRadius.vertical(top: Radius.circular(16))
                      : i == _users.length - 1
                          ? const BorderRadius.vertical(
                              bottom: Radius.circular(16))
                          : BorderRadius.zero,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _roleColor(user.role).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              user.name.split(' ').map((w) => w[0]).join(),
                              style: AppTextStyles.captionMedium.copyWith(
                                color: _roleColor(user.role),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user.name,
                                  style: AppTextStyles.bodyMedium
                                      .copyWith(fontWeight: FontWeight.w500)),
                              Text(user.email,
                                  style: AppTextStyles.small
                                      .copyWith(fontSize: 11)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _roleColor(user.role).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            user.role,
                            style: AppTextStyles.small.copyWith(
                              color: _roleColor(user.role),
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: user.isActive
                                ? AppColors.success
                                : AppColors.disabled,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildAnalyticsChart() {
    // Simple bar chart simulation
    final data = [
      _ChartBar('Jan', 0.45),
      _ChartBar('Feb', 0.65),
      _ChartBar('Mar', 0.80),
      _ChartBar('Apr', 0.55),
      _ChartBar('May', 0.70),
      _ChartBar('Jun', 0.90),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Requests Over Time',
              style: AppTextStyles.bodyMedium
                  .copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Last 6 months', style: AppTextStyles.small),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data.map((bar) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${(bar.value * 30).toInt()}',
                          style: AppTextStyles.small.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: bar.value * 100,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.primary,
                                AppColors.primary.withOpacity(0.6),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(bar.label,
                            style: AppTextStyles.small
                                .copyWith(fontSize: 11)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditLogs() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Column(
        children: List.generate(_auditLogs.length, (i) {
          final log = _auditLogs[i];
          return Column(
            children: [
              if (i > 0)
                const Divider(height: 1, indent: 56, color: AppColors.divider),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _logColor(log.type).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(_logIcon(log.type),
                          color: _logColor(log.type), size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              style: AppTextStyles.caption,
                              children: [
                                TextSpan(
                                  text: log.user,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                                TextSpan(text: ' ${log.action}'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(log.time,
                              style: AppTextStyles.small
                                  .copyWith(fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildCMSLinks() {
    final items = [
      _CMSItem('Manage FAQs', 'Update help content and questions',
          Icons.help_outline_rounded, AppColors.primary),
      _CMSItem('Edit Notices', 'Manage official notice templates',
          Icons.article_rounded, AppColors.info),
      _CMSItem('Chatbot KB', 'Update chatbot knowledge base',
          Icons.smart_toy_rounded, AppColors.success),
      _CMSItem('App Settings', 'Configure app behavior and features',
          Icons.settings_rounded, AppColors.textSecondary),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Column(
        children: List.generate(items.length, (i) {
          final item = items[i];
          return Column(
            children: [
              if (i > 0)
                const Divider(height: 1, indent: 56, color: AppColors.divider),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${item.title} coming soon')),
                    );
                  },
                  borderRadius: i == 0
                      ? const BorderRadius.vertical(top: Radius.circular(16))
                      : i == items.length - 1
                          ? const BorderRadius.vertical(
                              bottom: Radius.circular(16))
                          : BorderRadius.zero,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: item.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(item.icon, color: item.color, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.title,
                                  style: AppTextStyles.bodyMedium
                                      .copyWith(fontWeight: FontWeight.w500)),
                              Text(item.subtitle,
                                  style: AppTextStyles.small
                                      .copyWith(fontSize: 11)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            color: AppColors.textMuted, size: 22),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _SystemUser {
  final String name;
  final String email;
  final String role;
  final bool isActive;
  const _SystemUser(this.name, this.email, this.role, this.isActive);
}

class _AuditLog {
  final String user;
  final String action;
  final String time;
  final String type;
  const _AuditLog(this.user, this.action, this.time, this.type);
}

class _ChartBar {
  final String label;
  final double value;
  const _ChartBar(this.label, this.value);
}

class _CMSItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  const _CMSItem(this.title, this.subtitle, this.icon, this.color);
}
