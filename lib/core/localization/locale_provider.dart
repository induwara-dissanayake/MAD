import 'dart:ui';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'locale_provider.g.dart';

@riverpod
class LocaleNotifier extends _$LocaleNotifier {
  @override
  Locale build() {
    // TODO: Load from local storage
    return const Locale('en');
  }

  void setLocale(Locale locale) {
    state = locale;
    // TODO: Save to local storage
  }

  void setLocaleByCode(String languageCode) {
    state = Locale(languageCode);
  }
}
