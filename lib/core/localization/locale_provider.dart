import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds the currently selected app locale.
///
/// Defaults to English on first run.
///
/// To persist across restarts, add `shared_preferences` to pubspec.yaml and
/// replace the in-memory implementation below with SharedPreferences reads/writes.
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>(
  (ref) => LocaleNotifier(),
);

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('en'));

  void setLocale(Locale locale) {
    state = locale;
  }

  void setLocaleByCode(String languageCode) {
    state = Locale(languageCode);
  }
}
