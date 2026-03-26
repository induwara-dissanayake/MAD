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

  final tabs = const [
    Tab(icon: Icon(Icons.chat), text: "Chats"),
    Tab(icon: Icon(Icons.report), text: "Issues"),
    Tab(icon: Icon(Icons.work), text: "Jobs"),
    Tab(icon: Icon(Icons.search), text: "Lost"),
    Tab(icon: Icon(Icons.person), text: "Profile"),
  ];

  final screens = const [
    ChatListScreen(),
    ComplaintsScreen(),
    JobsServicesScreen(),
    LostFoundScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);
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
        bottom: TabBar(
          controller: _tabController,
          tabs: tabs,
          isScrollable: true,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: screens,
      ),
    );
  }
}