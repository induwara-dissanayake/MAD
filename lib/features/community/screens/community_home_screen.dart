import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'chat_screen.dart';
import 'complaints_screen.dart';
import 'jobs_services_screen.dart';
import 'lost_found_screen.dart';


// ---------------- MAIN SCREEN ----------------
class CommunityHomeScreen extends StatefulWidget {
  const CommunityHomeScreen({super.key});

  @override
  State<CommunityHomeScreen> createState() =>
      _CommunityHomeScreenState();
}

class _CommunityHomeScreenState
    extends State<CommunityHomeScreen> {
  static const _green     = Color(0xFF2E7D32);
  static const _greenLight = Color(0xFFE8F5E9);
  static const _bg        = Color(0xFFF8F9FA);

  List<Map<String, dynamic>> _todayHighlights = [];
  bool _isLoadingHighlights = true;

  StreamSubscription? _complaintsSub;
  StreamSubscription? _jobsSub;
  StreamSubscription? _lostFoundSub;
  StreamSubscription? _eventsSub;

  List<Map<String, dynamic>> _latestComplaints = [];
  List<Map<String, dynamic>> _latestJobs = [];
  List<Map<String, dynamic>> _latestLostFound = [];
  List<Map<String, dynamic>> _latestEvents = [];

  @override
  void initState() {
    super.initState();
    _listenToHighlights();
  }

  void _listenToHighlights() {
    final firestore = FirebaseFirestore.instance;

    _complaintsSub = firestore.collection('community_complaints')
        .orderBy('timestamp', descending: true)
        .limit(3)
        .snapshots()
        .listen((snapshot) {
      _latestComplaints = snapshot.docs.map((doc) {
        final data = doc.data();
        data['source'] = 'complaint';
        return data;
      }).toList();
      _updateMergedHighlights();
    });

    _jobsSub = firestore.collection('community_jobs')
        .orderBy('timestamp', descending: true)
        .limit(3)
        .snapshots()
        .listen((snapshot) {
      _latestJobs = snapshot.docs.map((doc) {
        final data = doc.data();
        data['source'] = 'job';
        return data;
      }).toList();
      _updateMergedHighlights();
    });

    _lostFoundSub = firestore.collection('community_lost_found')
        .orderBy('timestamp', descending: true)
        .limit(3)
        .snapshots()
        .listen((snapshot) {
      _latestLostFound = snapshot.docs.map((doc) {
        final data = doc.data();
        data['source'] = 'lost_found';
        return data;
      }).toList();
      _updateMergedHighlights();
    });

    _eventsSub = firestore.collection('community_events')
        .orderBy('timestamp', descending: true)
        .limit(3)
        .snapshots()
        .listen((snapshot) {
      _latestEvents = snapshot.docs.map((doc) {
        final data = doc.data();
        data['source'] = 'event';
        return data;
      }).toList();
      _updateMergedHighlights();
    });
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return 'Recently';
    final date = timestamp.toDate();
    final now = DateTime.now();
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
    
    if (isToday) {
      return 'Today, ${DateFormat('h:mm a').format(date)}';
    } else {
      return DateFormat('MMM d, h:mm a').format(date);
    }
  }

  void _updateMergedHighlights() {
    final all = [
      ..._latestComplaints,
      ..._latestJobs,
      ..._latestLostFound,
      ..._latestEvents
    ];

    all.sort((a, b) {
      final ta = a['timestamp'] as Timestamp?;
      final tb = b['timestamp'] as Timestamp?;
      if (ta == null && tb == null) return 0;
      if (ta == null) return 1;
      if (tb == null) return -1;
      return tb.compareTo(ta); // Descending
    });

    final recentTop = all.take(4).toList();
    final formattedHighlights = recentTop.map((item) {
      String title = "";
      String time = _formatTime(item['timestamp'] as Timestamp?);
      IconData icon = Icons.info;
      Color color = Colors.grey;

      if (item['source'] == 'complaint') {
        title = item['title'] ?? 'Complaint';
        icon = Icons.warning_rounded;
        color = const Color(0xFFF57C00); // Orange
      } else if (item['source'] == 'job') {
        title = item['title'] ?? 'New Job Opportunity';
        icon = Icons.work_rounded;
        color = const Color(0xFF00897B); // Teal/Green
      } else if (item['source'] == 'lost_found') {
        final itemType = item['type'] ?? 'Lost';
        final itemTitle = item['title'] ?? 'Item';
        title = "$itemType: $itemTitle";
        icon = itemType == 'Lost' ? Icons.search_rounded : Icons.check_circle_rounded;
        color = itemType == 'Lost' ? const Color(0xFFE53935) : const Color(0xFF1E88E5); // Red for Lost, Blue for Found
      } else if (item['source'] == 'event') {
        title = item['title'] ?? 'Community Event';
        icon = Icons.celebration_rounded;
        color = const Color(0xFF8E24AA); // Purple
      }

      return {
        'icon': icon,
        'title': title,
        'time': time,
        'color': color,
      };
    }).toList();

    if (mounted) {
      setState(() {
        _todayHighlights = formattedHighlights;
        _isLoadingHighlights = false;
      });
    }
  }

  @override
  void dispose() {
    _complaintsSub?.cancel();
    _jobsSub?.cancel();
    _lostFoundSub?.cancel();
    _eventsSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,

      appBar: AppBar(
        title: const Text("Community",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: _green,
        centerTitle: true,
        elevation: 0,
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // HEADER CARD — green gradient, compact
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2E7D32).withOpacity(0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(greeting(),
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 4),
                const Text("Welcome Community!",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    )),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _buildOverlappingAvatars(),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("120 Members",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 8, height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.greenAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Text("15 Online",
                                style: TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          buildCommunityActions(),

          const SizedBox(height: 20),

          buildTodayHighlights(),
        ],
      ),
    );
  }

  // ---------------- TODAY HIGHLIGHTS ----------------
  Widget buildTodayHighlights() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.whatshot, color: Color(0xFFEC6A00), size: 18),
            SizedBox(width: 6),
            Text(
              "TODAY HIGHLIGHTS",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFFEC6A00),
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoadingHighlights)
          const SizedBox(
            height: 140,
            child: Center(child: CircularProgressIndicator(color: Color(0xFFEC6A00))),
          )
        else if (_todayHighlights.isEmpty)
          const SizedBox(
            height: 140,
            child: Center(child: Text("No highlights today.", style: TextStyle(color: Colors.grey))),
          )
        else
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _todayHighlights.length,
            itemBuilder: (context, index) {
              final highlight = _todayHighlights[index];
              return Container(
                width: 240,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      highlight['color'].withOpacity(0.85),
                      highlight['color'],
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: highlight['color'].withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(highlight['icon'], color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            highlight['title'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        highlight['time'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ---------------- COMMUNITY ACTIONS ----------------
  Widget buildCommunityActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.grid_view_rounded, color: Color(0xFF2E7D32), size: 16),
            SizedBox(width: 6),
            Text(
              "QUICK ACTIONS",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final w = (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                buildActionCard(Icons.chat_bubble_outline_rounded, "Chat", w),
                buildActionCard(Icons.report_outlined, "Complaints", w),
                buildActionCard(Icons.work_outline_rounded, "Jobs", w),
                buildActionCard(Icons.search_rounded, "Lost & Found", w),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget buildActionCard(IconData icon, String title, double width) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => navigate(title.replaceAll(' & Found', '')),
        child: Container(
          width: width,
          height: 86,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8F5E9), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: _green, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF1B5E20),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- NAVIGATION ----------------
  void navigate(String title) {
    if (title == "Chat") {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const ChatScreen(name: "Community Chat")));
    } else if (title == "Complaints") {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const ComplaintsScreen()));
    } else if (title == "Jobs") {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const JobsServicesScreen()));
    } else if (title == "Lost") {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const LostFoundScreen()));
    }
  }

  // ---------------- GREETING ----------------
  String greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning ☀️";
    if (hour < 17) return "Good Afternoon 🌤️";
    return "Good Evening 🌙";
  }

  // ---------------- AVATARS ----------------
  Widget _buildOverlappingAvatars() {
    return SizedBox(
      width: 112,
      height: 38,
      child: Stack(
        children: [
          Positioned(left: 0,  child: _buildAvatar('AM', Colors.orange, true)),
          Positioned(left: 20, child: _buildAvatar('KP', Colors.blue, true)),
          Positioned(left: 40, child: _buildAvatar('SL', Colors.redAccent, false)),
          Positioned(left: 60, child: _buildAvatar('MD', Colors.purple, true)),
          Positioned(
            left: 80,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white54, width: 1.5),
              ),
              child: const Center(
                child: Text("+12",
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String initials, Color bgColor, bool isOnline) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white54, width: 1.5),
          ),
          child: CircleAvatar(
            radius: 17,
            backgroundColor: bgColor,
            child: Text(
              initials,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        if (isOnline)
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                color: Colors.greenAccent,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }
}