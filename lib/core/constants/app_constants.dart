class AppConstants {
  AppConstants._();

  static const String appName = 'Village Connect';
  static const String appTagline =
      'Connecting communities, simplifying governance';

  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingSM = 8.0;
  static const double spacingMD = 16.0;
  static const double spacingLG = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // Border Radius
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusFull = 100.0;

  // Min tap target
  static const double minTapTarget = 48.0;

  // Animation durations
  static const Duration animFast = Duration(milliseconds: 200);
  static const Duration animNormal = Duration(milliseconds: 300);
  static const Duration animSlow = Duration(milliseconds: 500);

  // Document types
  static const List<String> documentTypes = [
    'Character Certificate',
    'Residence Certificate',
    'Income Certificate',
    'Birth Certificate',
    'Identity Verification',
    'Land Ownership Certificate',
  ];

  // Incident categories
  static const List<String> incidentCategories = [
    'Road Damage',
    'Water Supply Issue',
    'Electricity Problem',
    'Waste Management',
    'Public Safety',
    'Environmental',
    'Other',
  ];

  // Request statuses
  static const List<String> requestStatuses = [
    'Pending',
    'In Review',
    'Approved',
    'Rejected',
    'More Info Required',
  ];
}
