import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Language selector screen.
/// Allows the user to choose from English, Sinhala, or Tamil before
/// proceeding to the login screen.
class LanguageSelectorScreen extends StatefulWidget {
  const LanguageSelectorScreen({super.key});

  @override
  State<LanguageSelectorScreen> createState() => _LanguageSelectorScreenState();
}

class _LanguageSelectorScreenState extends State<LanguageSelectorScreen> {
  /// Index of the currently selected language (null = none selected).
  int? _selectedIndex;

  /// Available languages with native label, English label, and locale code.
  static const List<_LanguageOption> _languages = [
    _LanguageOption(
      nativeLabel: 'English',
      englishLabel: 'English',
      localeCode: 'en',
    ),
    _LanguageOption(
      nativeLabel: '\u0DC3\u0DD2\u0D82\u0DC4\u0DBD',
      englishLabel: 'Sinhala',
      localeCode: 'si',
    ),
    _LanguageOption(
      nativeLabel: '\u0BA4\u0BAE\u0BBF\u0BB4\u0BCD',
      englishLabel: 'Tamil',
      localeCode: 'ta',
    ),
  ];

  // ------------------------------------------------------------------
  // Navigation
  // ------------------------------------------------------------------

  void _onContinue() {
    if (_selectedIndex == null) return;
    context.go('/auth/login');
  }

  // ------------------------------------------------------------------
  // Build
  // ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),

              // Header icon
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.accentBlue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.translate_rounded,
                    size: 36,
                    color: AppColors.primary,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Title
              Text(
                'Choose Your Language',
                textAlign: TextAlign.center,
                style: AppTextStyles.h1.copyWith(fontSize: 26),
              ),

              const SizedBox(height: 8),

              // Subtitle
              Text(
                'Select the language you are most comfortable with',
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 40),

              // Language cards
              Expanded(
                child: ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _languages.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final lang = _languages[index];
                    final bool isSelected = _selectedIndex == index;
                    return _buildLanguageCard(
                      lang: lang,
                      isSelected: isSelected,
                      onTap: () => setState(() => _selectedIndex = index),
                    );
                  },
                ),
              ),

              // Continue button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _selectedIndex != null ? _onContinue : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.disabledBackground,
                    foregroundColor: AppColors.textOnPrimary,
                    disabledForegroundColor: AppColors.disabled,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text('Continue', style: AppTextStyles.button),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // Widgets
  // ------------------------------------------------------------------

  Widget _buildLanguageCard({
    required _LanguageOption lang,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          constraints: const BoxConstraints(minHeight: 80),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
            color: isSelected
                ? AppColors.primary.withOpacity(0.04)
                : AppColors.card,
          ),
          child: Row(
            children: [
              // Language labels
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      lang.nativeLabel,
                      style: AppTextStyles.h3.copyWith(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                    if (lang.nativeLabel != lang.englishLabel) ...[
                      const SizedBox(height: 4),
                      Text(
                        lang.englishLabel,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Checkmark for selected state
              AnimatedOpacity(
                opacity: isSelected ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------
// Helper model
// ------------------------------------------------------------------

class _LanguageOption {
  final String nativeLabel;
  final String englishLabel;
  final String localeCode;

  const _LanguageOption({
    required this.nativeLabel,
    required this.englishLabel,
    required this.localeCode,
  });
}
