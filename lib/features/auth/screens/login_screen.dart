import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/localization/vc_copy.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../core/router/route_paths.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  String _resolveEmail(String input) {
    final trimmed = input.trim();
    final isEmail = RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(trimmed);
    if (isEmail) return trimmed;
    return Validators.nicToEmail(trimmed);
  }

  Future<String> _dashboardForCurrentUser(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final data = doc.data() ?? {};
      final role = data['role'] == 'super_admin'
          ? 'admin'
          : data['role'] as String? ?? 'citizen';
      final capabilities = data['capabilities'] is Map
          ? data['capabilities'] as Map
          : const {};
      switch (role) {
        case 'committee':
          return RoutePaths.committeeTasks;
        case 'admin':
          return RoutePaths.adminDashboard;
        case 'gn_officer':
          return RoutePaths.officialDashboard;
        default:
          if (capabilities['canAccessAdminDashboard'] == true) {
            return RoutePaths.adminDashboard;
          }
          return RoutePaths.home;
      }
    } catch (_) {
      return RoutePaths.home;
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final email = _resolveEmail(_identifierController.text);
      final credential = await ref
          .read(authServiceProvider)
          .signInWithEmail(email, _passwordController.text);

      if (mounted) {
        final uid = credential.user?.uid ?? '';
        final destination = await _dashboardForCurrentUser(uid);
        if (mounted) context.go(destination);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        final l = context.l10n;
        String message;
        switch (e.code) {
          case 'user-not-found':
            message = l.loginFailedNoAccount;
            break;
          case 'wrong-password':
            message = l.loginFailedWrongPassword;
            break;
          case 'invalid-credential':
            message = l.loginFailedInvalidCredential;
            break;
          default:
            message = '${l.loginFailedDefault} (${e.message})';
        }
        _showError(message);
      }
    } catch (e) {
      if (mounted) _showError(context.l10n.loginFailedDefault);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final copy = VcCopy.of(context);
    return Scaffold(
      backgroundColor: AppColors.surfaceParchment,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLanguageSwitch(),
                const SizedBox(height: 32),
                _buildLogoHeader(copy),
                const SizedBox(height: 40),
                Text(copy.t('loginTitle'), style: AppTextStyles.displayLarge),
                const SizedBox(height: 8),
                Text(
                  copy.t('loginSubtitle'),
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.inkMid,
                  ),
                ),
                const SizedBox(height: 36),
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel(copy.t('nicOrEmail')),
                      const SizedBox(height: 8),
                      _buildSoftWellField(
                        controller: _identifierController,
                        hint: copy.t('nicHint'),
                        prefixIcon: Icons.badge_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => (v == null || v.isEmpty)
                            ? l.nicOrEmailRequired
                            : null,
                      ),
                      const SizedBox(height: 20),
                      _buildLabel(copy.t('password')),
                      const SizedBox(height: 8),
                      _buildSoftWellField(
                        controller: _passwordController,
                        hint: copy.t('passwordHint'),
                        prefixIcon: Icons.lock_outline_rounded,
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                        validator: (v) => (v == null || v.isEmpty)
                            ? l.passwordRequired
                            : null,
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _isLoading ? null : _login,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(l.signIn),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildHelpSection(copy),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSwitch() {
    const languages = [('English', 'en'), ('සිංහල', 'si'), ('தமிழ்', 'ta')];
    final currentCode = Localizations.localeOf(context).languageCode;
    return Align(
      alignment: Alignment.centerRight,
      child: Wrap(
        spacing: 6,
        children: [
          for (final language in languages)
            ChoiceChip(
              label: Text(language.$1),
              selected: currentCode == language.$2,
              onSelected: (_) => ref
                  .read(localeProvider.notifier)
                  .setLocaleByCode(language.$2),
            ),
        ],
      ),
    );
  }

  Widget _buildLogoHeader(VcCopy copy) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.brandGreenSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.brandGreenBorder),
          ),
          child: const Icon(
            Icons.account_balance_outlined,
            color: AppColors.brandGreen,
            size: 28,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          copy.t('officialPortal').toUpperCase(),
          style: AppTextStyles.overline.copyWith(color: AppColors.brandGreen),
        ),
        const SizedBox(height: 6),
        Text('Village Connect', style: AppTextStyles.h2),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: AppTextStyles.label.copyWith(color: AppColors.textPrimary),
    );
  }

  Widget _buildSoftWellField({
    required TextEditingController controller,
    required String hint,
    required IconData prefixIcon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      keyboardType: keyboardType,
      textDirection: TextDirection.ltr,
      style: AppTextStyles.bodyLarge,
      strutStyle: AppTextStyles.strutStyle(16, height: 1.65),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.bodyLarge.copyWith(
          color: AppColors.textMuted,
          height: 1.65,
        ),
        prefixIcon: Icon(prefixIcon, size: 20),
        suffixIcon: suffixIcon,
      ),
    );
  }

  Widget _buildHelpSection(VcCopy copy) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceIvory,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceWarmSand),
        boxShadow: AppColors.shadowLow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, size: 18),
              const SizedBox(width: 8),
              Text(copy.t('firstTime'), style: AppTextStyles.captionMedium),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            copy.t('firstTimeBody'),
            style: AppTextStyles.small.copyWith(
              color: AppColors.inkMid,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
