// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Village Connect';

  @override
  String get login => 'Login';

  @override
  String get register => 'Register';

  @override
  String get submit => 'Submit';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get language => 'Language';

  @override
  String get settings => 'Settings';

  @override
  String get profile => 'Profile';

  @override
  String get logout => 'Logout';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Error';

  @override
  String get success => 'Success';

  @override
  String get offline => 'You are offline';

  @override
  String get online => 'You are back online';

  @override
  String get noInternet => 'No internet connection';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get signUp => 'Sign Up';

  @override
  String get welcome => 'Welcome';

  @override
  String get myDocuments => 'My Documents';

  @override
  String get myIncidents => 'My Incidents';

  @override
  String get notifications => 'Notifications';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get applyDocument => 'Apply for Document';

  @override
  String get reportIncident => 'Report Incident';

  @override
  String get documentName => 'Document Name';

  @override
  String get status => 'Status';

  @override
  String get upload => 'Upload';

  @override
  String get file => 'File';

  @override
  String get download => 'Download';

  @override
  String get pending => 'Pending';

  @override
  String get approved => 'Approved';

  @override
  String get rejected => 'Rejected';

  @override
  String get incidentType => 'Incident Type';

  @override
  String get description => 'Description';

  @override
  String get location => 'Location';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get submitReport => 'Submit Report';

  @override
  String get fieldRequired => 'This field is required';

  @override
  String get validEmail => 'Please enter a valid email';

  @override
  String get validPassword => 'Password must be at least 6 characters';

  @override
  String get connectGoogle => 'Connect Google Account';

  @override
  String get googleConnected => 'Google Account Connected';

  @override
  String get welcomeBack => 'Welcome Back';

  @override
  String get signIn => 'Sign In';

  @override
  String get signInSubtitle => 'Sign in with your NIC number or email address.';

  @override
  String get nicOrEmail => 'NIC Number or Email';

  @override
  String get nicOrEmailHint => 'Enter NIC (e.g., 200012345678) or email';

  @override
  String get nicOrEmailRequired => 'NIC number or email is required';

  @override
  String get passwordHint => 'Enter your password';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get officialPlatform => 'Official Government Platform';

  @override
  String get gnServicesPortal => 'Grama Niladhari Services Portal';

  @override
  String get firstTimeAccessing => 'First time accessing?';

  @override
  String get firstTimeDesc =>
      'Your account is created by your Grama Niladhari officer or an authorized resident. Check your email for your login credentials.';

  @override
  String get loginFailedDefault => 'Login failed. Please try again.';

  @override
  String get loginFailedNoAccount =>
      'No account found. Please contact your Grama Niladhari office.';

  @override
  String get loginFailedWrongPassword =>
      'Incorrect password. Please try again.';

  @override
  String get loginFailedInvalidCredential =>
      'Invalid credentials. Please check and try again.';

  @override
  String get loginFailedNotEnabled =>
      'Sign-in is not enabled. Please contact the administrator.';

  @override
  String get offlineBanner => 'You are currently in Offline Mode';

  @override
  String get services => 'Services';

  @override
  String get recentActivity => 'Recent Activity';

  @override
  String get viewAll => 'View All';

  @override
  String get noRecentActivity => 'No recent activity';

  @override
  String get trackApplication => 'Track Application';

  @override
  String get viewStatusOfRequests => 'View status of your requests';

  @override
  String get requestCertificates =>
      'Request certificates and official documents';

  @override
  String get noticeBoard => 'Notice Board';

  @override
  String get officialAnnouncements => 'Official announcements';

  @override
  String get communityFeed => 'Community Feed';

  @override
  String get householdManagement => 'Household Management';

  @override
  String get registerNewResident => 'Register New Resident';

  @override
  String get createAccountNewResident =>
      'Create account for a new village resident';

  @override
  String get registerFamilyMember =>
      'Register a family member or rental occupant';

  @override
  String get reportIncidentDesc =>
      'Report issues in your area to the GN office';

  @override
  String get inReview => 'In Review';

  @override
  String get total => 'Total';

  @override
  String get citizen => 'Citizen';

  @override
  String get homeAlertsAndUpdates => 'Alerts & updates';

  @override
  String get homeNotificationsSubtitle => 'Appointments, community, and more';

  @override
  String homeNotificationsSubtitleUnread(int count) {
    return '$count unread';
  }

  @override
  String get notificationsEmptyBody =>
      'Certificate updates, community messages, and complaint status changes will appear here.';
}
