import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/router/route_paths.dart';

/// Language selector screen.
/// Allows the user to choose from English, Sinhala, or Tamil before
/// proceeding to the login screen.
class LanguageSelectorScreen extends ConsumerStatefulWidget {
  const LanguageSelectorScreen({super.key});

  @override
  ConsumerState<LanguageSelectorScreen> createState() =>
      _LanguageSelectorScreenState();
}

class _LanguageSelectorScreenState
    extends ConsumerState<LanguageSelectorScreen> {
  /// Index of the currently selected language (null = none selected).
  int? _selectedIndex;

  /// Available languages with native label, English label, and locale code.
  static const List<_LanguageOption> _languages = [
    _LanguageOption(
      nativeLabel: 'සිංහල',
      englishLabel: 'Sinhala',
      localeCode: 'si',
    ),
    _LanguageOption(
      nativeLabel: 'தமிழ்',
      englishLabel: 'Tamil',
      localeCode: 'ta',
    ),
    _LanguageOption(
      nativeLabel: 'English',
      englishLabel: 'English',
      localeCode: 'en',
    ),
  ];

  void _onContinue() {
    if (_selectedIndex == null) return;

    final selected = _languages[_selectedIndex!];
    ref.read(localeProvider.notifier).setLocaleByCode(selected.localeCode);
    context.go(RoutePaths.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              
              // Minimalist Header
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.translate_rounded,
                  size: 24,
                  color: AppColors.primary,
                ),
              ),
              
              const SizedBox(height: 32),
              
              Text(
                'Choose Your\nPreferred Language',
                style: AppTextStyles.displaySmall,
              ),
              
              const SizedBox(height: 12),
              
              Text(
                'Select a language to proceed with Village Connect',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              
              const SizedBox(height: 48),

              // Language List
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: _languages.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final lang = _languages[index];
                    final bool isSelected = _selectedIndex == index;
                    return _buildLanguageItem(
                      lang: lang,
                      isSelected: isSelected,
                      onTap: () => setState(() => _selectedIndex = index),
                    );
                  },
                ),
              ),

              // Action
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _selectedIndex != null ? _onContinue : null,
                    child: const Text('Continue'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageItem({
    required _LanguageOption lang,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.primary.withOpacity(0.06) 
              : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
          border: isSelected 
              ? Border.all(color: AppColors.primary, width: 1.5)
              : Border.all(color: Colors.transparent, width: 1.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lang.nativeLabel,
                    style: AppTextStyles.h3.copyWith(
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    lang.englishLabel,
                    style: AppTextStyles.small.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}

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
