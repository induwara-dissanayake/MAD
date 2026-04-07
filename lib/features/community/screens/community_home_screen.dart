import 'package:flutter/material.dart';

import 'chat_list_screen.dart';
import 'complaints_screen.dart';
import 'jobs_services_screen.dart';
import 'lost_found_screen.dart';
import 'profile_screen.dart';

class CommunityHomeScreen extends StatefulWidget {
  const CommunityHomeScreen({super.key});

  @override
  State<CommunityHomeScreen> createState() => _CommunityHomeScreenState();
}

class _CommunityHomeScreenState extends State<CommunityHomeScreen>
    with SingleTickerProviderStateMixin {

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Community"),
        centerTitle: true,

        // ✅ FIXED TAB BAR (CENTERED PROPERLY)
        bottom: TabBar(
          controller: _tabController,

          // 🔥 IMPORTANT (this makes equal spacing)
          isScrollable: false,

          tabs: const [
            Tab(
              icon: Icon(Icons.chat),
              text: "Chats",
            ),
            Tab(
              icon: Icon(Icons.report_problem),
              text: "Issues",
            ),
            Tab(
              icon: Icon(Icons.work),
              text: "Jobs",
            ),
            Tab(
              icon: Icon(Icons.search),
              text: "Lost",
            ),
            Tab(
              icon: Icon(Icons.person),
              text: "Profile",
            ),
          ],

          indicatorColor: Colors.blue,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.label,

          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,

          labelStyle: const TextStyle(fontSize: 12),
        ),
      ),

      // ✅ TAB SCREENS
      body: TabBarView(
        controller: _tabController,
        children: const [
          ChatListScreen(),
          ComplaintsScreen(),
          JobsServicesScreen(),
          LostFoundScreen(),
          ProfileScreen(),
        ],
      ),
    );
  }
}   