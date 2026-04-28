import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/screens/language_selector_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/first_login_setup_screen.dart';
import '../../features/auth/screens/create_resident_screen.dart';
import '../../features/auth/screens/add_member_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/chatbot/screens/chatbot_screen.dart';
import '../../features/community/screens/add_community_post_screen.dart';
import '../../features/community/screens/chat_screen.dart';
import '../../features/community/screens/community_Home_screen.dart';
import '../../features/community/screens/community_moderation_screen.dart';
import '../../features/documents/screens/document_request_screen.dart';
import '../../features/documents/screens/applications_hub_screen.dart';
import '../../features/documents/screens/request_detail_screen.dart';
import '../../features/documents/screens/request_tracking_screen.dart';
import '../../features/help/screens/help_screen.dart';
import '../../features/home/screens/app_shell.dart';
import '../../features/home/screens/citizen_home_screen.dart';
import '../../features/emergency/screens/emergency_alert_screen.dart';
import '../../features/notices/screens/notice_board_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/incidents/screens/incident_dashboard_screen.dart';
import '../../features/incidents/screens/incident_detail_screen.dart';
import '../../features/profile/screens/change_password_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/change_personal_information.dart';
import '../../features/profile/screens/edit_family_member_screen.dart';
import '../../features/committee/screens/committee_task_screen.dart';
import '../../features/committee/screens/meeting_scheduler_screen.dart';
import '../../features/committee/screens/polling_screen.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/admin/screens/user_management_screen.dart';
import '../../features/admin/screens/official_registration_screen.dart';
import '../../features/admin/screens/certificate_management_screen.dart';
import '../../features/official/screens/official_dashboard_screen.dart';
import '../../features/official/screens/pending_requests_screen.dart';
import '../../features/official/screens/request_review_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

String _normalizeRole(String? role) {
  return role == 'super_admin' ? 'admin' : role ?? 'citizen';
}

/// Returns the correct dashboard path for a given Firestore role string.
String _dashboardForRole(
  String role, {
  Map<String, dynamic> capabilities = const {},
}) {
  final normalizedRole = _normalizeRole(role);
  switch (normalizedRole) {
    case 'committee':
      return '/committee/tasks';
    case 'admin':
      return '/admin/dashboard';
    case 'gn_officer':
      return '/official/dashboard';
    default:
      if (capabilities['canAccessAdminDashboard'] == true) {
        return '/admin/dashboard';
      }
      return '/home';
  }
}

/// Fetches the role for the currently signed-in Firebase user from Firestore.
/// Returns 'citizen' as a safe fallback if anything goes wrong.
Future<String> _fetchCurrentUserRole() async {
  try {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return 'citizen';
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    return _normalizeRole(doc.data()?['role'] as String?);
  } catch (_) {
    return 'citizen';
  }
}

Future<Map<String, dynamic>> _fetchCurrentUserData() async {
  try {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return {};
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    return doc.data() ?? {};
  } catch (_) {
    return {};
  }
}

Map<String, dynamic> _capabilitiesFrom(Map<String, dynamic> userData) {
  final value = userData['capabilities'];
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return {};
}

bool _canModerateCommunity(Map<String, dynamic> userData) {
  final role = _normalizeRole(userData['role'] as String?);
  final capabilities = _capabilitiesFrom(userData);
  return role == 'admin' ||
      role == 'gn_officer' ||
      role == 'committee' ||
      capabilities['canModerateCommunity'] == true;
}

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  refreshListenable: GoRouterRefreshStream(
    FirebaseAuth.instance.authStateChanges(),
  ),
  redirect: (context, state) async {
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;
    final path = state.uri.path;

    if (isLoggedIn) {
      final userData = await _fetchCurrentUserData();
      final accountStatus = (userData['accountStatus'] as String? ?? 'active')
          .toLowerCase();
      final role = _normalizeRole(userData['role'] as String?);
      final capabilities = _capabilitiesFrom(userData);

      if (accountStatus == 'pending_first_login' &&
          path != '/auth/first-login') {
        return '/auth/first-login';
      }
      if ((accountStatus == 'inactive' || accountStatus == 'suspended') &&
          path != '/auth/login') {
        await FirebaseAuth.instance.signOut();
        return '/auth/login';
      }
      if (path == '/auth/first-login' &&
          accountStatus != 'pending_first_login') {
        return _dashboardForRole(role, capabilities: capabilities);
      }
    }

    // ── Pre-login screens ────────────────────────────────────────────────
    // Always allow splash and auth screens through.
    // Exception: create-resident and add-member are role-gated actions
    // that can be reached while already logged in.
    if (path == '/splash' || path.startsWith('/auth')) {
      if (path == '/auth/create-resident' || path == '/auth/add-member') {
        if (!isLoggedIn) return '/auth/login';

        final role = await _fetchCurrentUserRole();
        if (path == '/auth/create-resident') {
          if (role != 'admin_resident' &&
              role != 'gn_officer' &&
              role != 'admin') {
            return _dashboardForRole(role);
          }
        } else {
          if (role != 'citizen' &&
              role != 'admin_resident' &&
              role != 'gn_officer') {
            return _dashboardForRole(role);
          }
        }
        return null;
      }
      if (path == '/auth/first-login') {
        return isLoggedIn ? null : '/auth/login';
      }
      if (isLoggedIn) {
        // User is already authenticated — send them to the right dashboard.
        final userData = await _fetchCurrentUserData();
        final role = _normalizeRole(userData['role'] as String?);
        return _dashboardForRole(
          role,
          capabilities: _capabilitiesFrom(userData),
        );
      }
      return null;
    }

    // ── Not logged in ────────────────────────────────────────────────────
    if (!isLoggedIn) {
      return '/auth/login';
    }

    // ── Role-gate specific dashboards ─────────────────────────────────────
    // Prevent unauthorized users from accessing restricted routes.
    if (path == '/incidents') {
      final role = await _fetchCurrentUserRole();
      if (role != 'admin' && role != 'gn_officer') {
        return _dashboardForRole(role);
      }
    }

    if (path == '/committee/tasks' ||
        path == '/committee/meetings' ||
        path == '/committee/polls') {
      final userData = await _fetchCurrentUserData();
      final role = _normalizeRole(userData['role'] as String?);
      final capabilities = _capabilitiesFrom(userData);
      if (role != 'committee' &&
          role != 'admin' &&
          capabilities['isCommitteeMember'] != true) {
        return _dashboardForRole(role, capabilities: capabilities);
      }
    }

    if (path == '/admin/dashboard' ||
        path == '/admin/users' ||
        path == '/admin/create-user' ||
        path == '/admin/certificates' ||
        path == '/admin/register-official') {
      final userData = await _fetchCurrentUserData();
      final role = _normalizeRole(userData['role'] as String?);
      final capabilities = _capabilitiesFrom(userData);
      if (role != 'admin' && capabilities['canAccessAdminDashboard'] != true) {
        return _dashboardForRole(role, capabilities: capabilities);
      }
    }

    if (path == '/community/moderation') {
      final userData = await _fetchCurrentUserData();
      if (!_canModerateCommunity(userData)) {
        final role = _normalizeRole(userData['role'] as String?);
        return _dashboardForRole(
          role,
          capabilities: _capabilitiesFrom(userData),
        );
      }
    }

    if (path.startsWith('/official')) {
      final role = await _fetchCurrentUserRole();
      if (role != 'gn_officer' && role != 'admin') {
        return _dashboardForRole(role);
      }
    }

    // ── Catch all: redirect unauthorized users away from citizen shell routes ──
    if (path == '/home' ||
        path == '/applications' ||
        path == '/community' ||
        path == '/fab-placeholder' ||
        path == '/documents') {
      final role = await _fetchCurrentUserRole();
      // Allow citizen-facing roles to access these routes.
      if (role != 'citizen' && role != 'admin_resident') {
        return _dashboardForRole(role);
      }
    }

    return null;
  },
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(
      path: '/auth/language',
      builder: (context, state) => const LanguageSelectorScreen(),
    ),
    GoRoute(
      path: '/auth/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/auth/first-login',
      builder: (context, state) => const FirstLoginSetupScreen(),
    ),
    GoRoute(
      path: '/auth/create-resident',
      builder: (context, state) => const CreateResidentScreen(),
    ),
    GoRoute(
      path: '/auth/add-member',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AddMemberScreen(),
    ),

    // Shell Route for Bottom Navigation (citizen shell)
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppShell(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const CitizenHomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/applications',
              builder: (context, state) => const ApplicationsHubScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/fab-placeholder',
              builder: (context, state) => const SizedBox(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/notices',
              builder: (context, state) => const NoticeBoardScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/community',
              builder: (context, state) => const CommunityHomeScreen(),
            ),
          ],
        ),
      ],
    ),

    // ── Shared / push routes ─────────────────────────────────────────────
    GoRoute(
      path: '/chatbot',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ChatbotScreen(),
    ),
    GoRoute(
      path: '/documents/request',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final extras = state.extra as Map<String, dynamic>? ?? {};
        return DocumentRequestScreen(
          initialDocumentType: extras['documentType'] as String?,
        );
      },
    ),
    GoRoute(
      path: '/documents/tracking',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const RequestTrackingScreen(),
    ),
    GoRoute(
      path: '/notifications',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/help',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const HelpScreen(),
    ),
    GoRoute(
      path: '/emergency/alert',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const EmergencyAlertScreen(),
    ),
    GoRoute(
      path: '/documents/detail',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final extras = state.extra as Map<String, dynamic>? ?? {};
        return RequestDetailScreen(
          trackingId: extras['trackingId'] as String? ?? '',
          documentType: extras['documentType'] as String? ?? '',
          status: extras['status'] as String? ?? '',
        );
      },
    ),
    GoRoute(
      path: '/community/add',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AddCommunityPostScreen(),
    ),
    GoRoute(
      path: '/community/moderation',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const CommunityModerationScreen(),
    ),
    GoRoute(
      path: '/community/chat',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final extras = state.extra as Map<String, dynamic>? ?? {};
        final name = extras['name'] as String? ?? 'Community Chat';
        return ChatScreen(name: name);
      },
    ),

    // ── Profile ──────────────────────────────────────────────────────────
    GoRoute(
      path: '/profile',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/profile/change-password',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ChangePasswordScreen(),
    ),
    GoRoute(
      path: '/profile/edit-personal-information',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ChangePersonalInfoScreen(),
    ),
    GoRoute(
      path: '/profile/edit-family-member',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final memberUid = state.extra as String;
        return EditFamilyMemberScreen(memberUid: memberUid);
      },
    ),

    GoRoute(
      path: '/incidents',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const IncidentDashboardScreen(),
    ),
    GoRoute(
      path: '/incidents/detail',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const IncidentDetailScreen(),
    ),

    // ── Village Committee routes ──────────────────────────────────────────
    GoRoute(
      path: '/committee/tasks',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const CommitteeTaskScreen(),
    ),
    GoRoute(
      path: '/committee/meetings',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const MeetingSchedulerScreen(),
    ),
    GoRoute(
      path: '/committee/polls',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const PollingScreen(),
    ),

    // ── Admin ────────────────────────────────────────────────────────────
    GoRoute(
      path: '/admin/dashboard',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AdminDashboardScreen(),
    ),
    GoRoute(
      path: '/admin/users',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const UserManagementScreen(),
    ),
    GoRoute(
      path: '/admin/create-user',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const CreateResidentScreen(),
    ),
    GoRoute(
      path: '/admin/certificates',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const CertificateManagementScreen(),
    ),
    GoRoute(
      path: '/admin/register-official',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const OfficialRegistrationScreen(),
    ),

    // ── GN Officer ──────────────────────────────────────────────────────
    GoRoute(
      path: '/official/dashboard',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const OfficialDashboardScreen(),
    ),
    GoRoute(
      path: '/official/requests/pending',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const PendingRequestsScreen(),
    ),
    GoRoute(
      path: '/official/requests/:requestId/review',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final requestId = state.pathParameters['requestId'] ?? '';
        return RequestReviewScreen(requestId: requestId);
      },
    ),
  ],
);

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.listen((dynamic _) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
