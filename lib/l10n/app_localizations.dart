import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_si.dart';
import 'app_localizations_ta.dart';

// ignore_for_file: type=lint

abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('si'),
    Locale('ta'),
  ];

  // ── Existing keys ────────────────────────────────────────────────
  String get appTitle;
  String get login;
  String get register;
  String get submit;
  String get cancel;
  String get save;
  String get delete;
  String get edit;
  String get back;
  String get next;
  String get language;
  String get settings;
  String get profile;
  String get logout;
  String get loading;
  String get error;
  String get success;
  String get offline;
  String get online;
  String get noInternet;
  String get email;
  String get password;
  String get confirmPassword;
  String get forgotPassword;
  String get signInWithGoogle;
  String get dontHaveAccount;
  String get signUp;
  String get welcome;
  String get myDocuments;
  String get myIncidents;
  String get notifications;
  String get quickActions;
  String get applyDocument;
  String get reportIncident;
  String get documentName;
  String get status;
  String get upload;
  String get file;
  String get download;
  String get pending;
  String get approved;
  String get rejected;
  String get incidentType;
  String get description;
  String get location;
  String get takePhoto;
  String get submitReport;
  String get fieldRequired;
  String get validEmail;
  String get validPassword;
  String get connectGoogle;
  String get googleConnected;

  // ── Login screen keys ─────────────────────────────────────────────
  String get welcomeBack;
  String get signIn;
  String get signInSubtitle;
  String get nicOrEmail;
  String get nicOrEmailHint;
  String get nicOrEmailRequired;
  String get passwordHint;
  String get passwordRequired;
  String get officialPlatform;
  String get gnServicesPortal;
  String get firstTimeAccessing;
  String get firstTimeDesc;
  String get loginFailedDefault;
  String get loginFailedNoAccount;
  String get loginFailedWrongPassword;
  String get loginFailedInvalidCredential;
  String get loginFailedNotEnabled;

  // ── Home screen keys ──────────────────────────────────────────────
  String get offlineBanner;
  String get services;
  String get recentActivity;
  String get viewAll;
  String get noRecentActivity;
  String get trackApplication;
  String get viewStatusOfRequests;
  String get requestCertificates;
  String get noticeBoard;
  String get officialAnnouncements;
  String get communityFeed;
  String get householdManagement;
  String get registerNewResident;
  String get createAccountNewResident;
  String get registerFamilyMember;
  String get reportIncidentDesc;
  String get inReview;
  String get total;
  String get citizen;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'si', 'ta'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'si':
      return AppLocalizationsSi();
    case 'ta':
      return AppLocalizationsTa();
  }
  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale".',
  );
}
