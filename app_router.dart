import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/screens/language_selector_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/create_resident_screen.dart';
import '../../features/auth/screens/add_member_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/chatbot/screens/chatbot_screen.dart';
import '../../features/community/screens/add_community_post_screen.dart';
import '../../features/community/screens/community_Home_screen.dart';
import '../../features/documents/screens/document_request_screen.dart';
import '../../features/documents/screens/request_detail_screen.dart';
import '../../features/documents/screens/request_tracking_screen.dart';
import '../../features/help/screens/help_screen.dart';
import '../../features/home/screens/app_shell.dart';
import '../../features/home/screens/citizen_home_screen.dart';
import '../../features/notices/screens/notice_board_screen.dart';
import '../../features/notices/screens/notice_detail_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/official/screens/mass_broadcast_screen.dart';
import '../../features/official/screens/official_dashboard_screen.dart';
import '../../features/official/screens/pending_requests_screen.dart';
import '../../features/official/screens/post_notice_screen.dart';
import '../../features/official/screens/registered_users_screen.dart';
import '../../features/official/screens/request_review_screen.dart';
import '../../features/profile/screens/change_password_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/emergency/screens/emergency_alert_screen.dart';
import '../../features/incidents/screens/incident_dashboard_screen.dart';
import '../../features/committee/screens/committee_task_screen.dart';
import '../../features/committee/screens/meeting_scheduler_screen.dart';
import '../../features/committee/screens/polling_screen.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Returns the correct dashboard path for a given Firestore role string.
String _dashboardForRole(String role) {
  switch (role) {
    case 'gn_officer':
      return '/official/dashboard';
    case 'committee':
      return '/committee/tasks';
    case 'admin':
      return '/admin/dashboard';
    default:
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
    return doc.data()?['role'] as String? ?? 'citizen';
  } catch (_) {
    return 'citizen';
  }
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

    // ── Pre-login screens ────────────────────────────────────────────────
    // Always allow splash and auth screens through.
    // Exception: create-resident and add-member are officer-only actions
    // that can be reached while already logged in.
    if (path == '/splash' || path.startsWith('/auth')) {
      if (path == '/auth/create-resident' || path == '/auth/add-member') {
        return null;
      }
      if (isLoggedIn) {
        // User is already authenticated — send them to the right dashboard.
        final role = await _fetchCurrentUserRole();
        return _dashboardForRole(role);
      }
      return null;
    }

    // ── Not logged in ────────────────────────────────────────────────────
    if (!isLoggedIn) {
      return '/auth/login';
    }

    // ── Role-gate specific dashboards ─────────────────────────────────────
    // Prevent a citizen from directly navigating to officer/admin routes
    // (e.g. by typing the path or following a deep-link).
    if (path == '/official/dashboard' ||
        path == '/official/pending' ||
        path == '/official/review' ||
        path == '/official/post-notice' ||
        path == '/official/broadcast' ||
        path == '/official/registered-users' ||
        path == '/incidents') {
      final role = await _fetchCurrentUserRole();
      if (role != 'gn_officer' && role != 'admin') {
        return _dashboardForRole(role);
      }
    }

    if (path == '/committee/tasks' ||
        path == '/committee/meetings' ||
        path == '/committee/polls') {
      final role = await _fetchCurrentUserRole();
      if (role != 'committee' && role != 'admin') {
        return _dashboardForRole(role);
      }
    }

    if (path == '/admin/dashboard') {
      final role = await _fetchCurrentUserRole();
      if (role != 'admin') {
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
      path: '/auth/create-resident',
      builder: (context, state) => const CreateResidentScreen(),
    ),
    GoRoute(
      path: '/auth/add-member',
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
              builder: (context, state) => const RequestTrackingScreen(),
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
      builder: (context, state) => const DocumentRequestScreen(),
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

    // ── GN Officer routes ────────────────────────────────────────────────
    GoRoute(
      path: '/official/dashboard',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const OfficialDashboardScreen(),
    ),
    GoRoute(
      path: '/official/pending',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const PendingRequestsScreen(),
    ),
    GoRoute(
      path: '/official/review',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const RequestReviewScreen(),
    ),
    GoRoute(
      path: '/official/post-notice',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const PostNoticeScreen(),
    ),
    GoRoute(
      path: '/official/broadcast',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const MassBroadcastScreen(),
    ),
    GoRoute(
      path: '/official/registered-users',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const RegisteredUsersScreen(),
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

    // ── Notice detail ────────────────────────────────────────────────────
    GoRoute(
      path: '/notice-detail',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final notice = state.extra as Map<String, String>;
        return NoticeDetailScreen(notice: notice);
      },
    ),

    // ── Emergency & incidents ────────────────────────────────────────────
    GoRoute(
      path: '/emergency/alert',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const EmergencyAlertScreen(),
    ),
    GoRoute(
      path: '/incidents',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const IncidentDashboardScreen(),
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
