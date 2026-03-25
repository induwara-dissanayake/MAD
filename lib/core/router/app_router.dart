import 'dart:async';
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
import '../../features/community/screens/community_feed_screen.dart';
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
import '../../features/official/screens/request_review_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/emergency/screens/emergency_alert_screen.dart';
import '../../features/incidents/screens/incident_dashboard_screen.dart';
import '../../features/committee/screens/committee_task_screen.dart';
import '../../features/committee/screens/meeting_scheduler_screen.dart';
import '../../features/committee/screens/polling_screen.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  refreshListenable: GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges()),
  redirect: (context, state) {
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;
    final path = state.uri.path;

    // Allow splash, login, language, and member-creation screens
    if (path == '/splash' || path.startsWith('/auth')) {
      // Allow member creation screens even when logged in
      if (path == '/auth/create-resident' || path == '/auth/add-member') {
        return null;
      }
      if (isLoggedIn) {
        return '/home';
      }
      return null;
    }

    if (!isLoggedIn) {
      return '/auth/login';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
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

    // Shell Route for Bottom Navigation
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppShell(navigationShell: navigationShell);
      },
      branches: [
        // Home Branch
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const CitizenHomeScreen(),
            ),
          ],
        ),
        // Notifications Branch
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/notifications',
              builder: (context, state) => const NotificationsScreen(),
            ),
          ],
        ),
        // Placeholder for FAB (handled in AppShell)
        StatefulShellBranch(
           routes: [
             GoRoute(
               path: '/fab-placeholder',
               builder: (context, state) => const SizedBox(),
             )
           ]
        ),
        // Notices Branch
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/notices',
              builder: (context, state) => const NoticeBoardScreen(),
            ),
          ],
        ),
        // Help Branch
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/help',
              builder: (context, state) => const HelpScreen(),
            ),
          ],
        ),
      ],
    ),

    // Other routes (push on top of shell)
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
      path: '/community',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const CommunityFeedScreen(),
    ),
    GoRoute(
      path: '/community/add',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AddCommunityPostScreen(),
    ),
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
      path: '/profile',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/notice-detail',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final notice = state.extra as Map<String, String>;
        return NoticeDetailScreen(notice: notice);
      },
    ),
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
    _subscription = stream.listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
