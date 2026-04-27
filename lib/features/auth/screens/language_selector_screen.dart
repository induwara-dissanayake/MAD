import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/locale_provider.dart';
import '../../../core/localization/vc_copy.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class LanguageSelectorScreen extends ConsumerStatefulWidget {
  const LanguageSelectorScreen({super.key});

  @override
  ConsumerState<LanguageSelectorScreen> createState() =>
      _LanguageSelectorScreenState();
}

class _LanguageSelectorScreenState
    extends ConsumerState<LanguageSelectorScreen> {
  String _selectedCode = 'en';

  static const List<_LanguageOption> _languages = [
    _LanguageOption('English', 'English', 'en'),
    _LanguageOption('සිංහල', 'Sinhala', 'si'),
    _LanguageOption('தமிழ்', 'Tamil', 'ta'),
  ];

  void _continue() {
    ref.read(localeProvider.notifier).setLocaleByCode(_selectedCode);
    context.go(RoutePaths.login);
  }

  @override
  Widget build(BuildContext context) {
    final copy = VcCopy(_selectedCode);

    return Scaffold(
      backgroundColor: AppColors.surfaceParchment,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(
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
                  Icons.translate_outlined,
                  color: AppColors.brandGreen,
                  size: 28,
                ),
              ),
              const SizedBox(height: 28),
              Text(copy.t('chooseLanguage'), style: AppTextStyles.displayLarge),
              const SizedBox(height: 10),
              Text(
                copy.t('languageIntro'),
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.inkMid,
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView.separated(
                  itemCount: _languages.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final language = _languages[index];
                    final selected = language.code == _selectedCode;
                    return _LanguageCard(
                      option: language,
                      selected: selected,
                      onTap: () => setState(() {
                        _selectedCode = language.code;
                        ref
                            .read(localeProvider.notifier)
                            .setLocaleByCode(language.code);
                      }),
                    );
                  },
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _continue,
                  child: Text(copy.t('continue')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _LanguageOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: option.englishLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.brandGreenSurface
                  : AppColors.surfaceIvory,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? AppColors.brandGreen
                    : AppColors.surfaceWarmSand,
                width: selected ? 1.5 : 1,
              ),
              boxShadow: AppColors.shadowLow,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(option.nativeLabel, style: AppTextStyles.h3),
                      const SizedBox(height: 2),
                      Text(option.englishLabel, style: AppTextStyles.caption),
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected ? AppColors.brandGreen : AppColors.inkLight,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageOption {
  const _LanguageOption(this.nativeLabel, this.englishLabel, this.code);

  final String nativeLabel;
  final String englishLabel;
  final String code;
}
