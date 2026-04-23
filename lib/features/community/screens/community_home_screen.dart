import 'package:flutter/material.dart';
import 'chat_screen.dart';
import 'complaints_screen.dart';
import 'jobs_services_screen.dart';
import 'lost_found_screen.dart';

// ---------------- ALERT DETAIL ----------------
class AlertDetailScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const AlertDetailScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              subtitle,
              style: TextStyle(color: color, fontSize: 16),
            ),
            const SizedBox(height: 20),
            const Text(
              "More details about this update can be shown here.",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- MAIN SCREEN ----------------
class CommunityHomeScreen extends StatefulWidget {
  const CommunityHomeScreen({super.key});

  @override
  State<CommunityHomeScreen> createState() =>
      _CommunityHomeScreenState();
}

class _CommunityHomeScreenState
    extends State<CommunityHomeScreen> {
  final primaryGreen = const Color(0xFF2E7D32);
  final lightGreen = const Color(0xFF388E3C);
  final bgColor = const Color(0xFFF5F5F5);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,



      appBar: AppBar(
        title: const Text("Kaduwela Village"),
        backgroundColor: primaryGreen,
        centerTitle: true,
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryGreen,
        onPressed: () {},
        child: const Icon(Icons.add),
      ),

      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [

          // HEADER
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: primaryGreen,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(greeting(),
                    style: const TextStyle(color: Colors.white70)),
                const Text("Kaduwela Village Community",
                    style: TextStyle(color: Colors.white)),
                const Text("120 Members",
                    style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),

          const SizedBox(height: 16),

          buildCommunityActions(),

          const SizedBox(height: 20),

          buildRecentUpdates(),
        ],
      ),
    );
  }


  // ---------------- COMMUNITY ACTIONS ----------------
  Widget buildCommunityActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryGreen,
        borderRadius: BorderRadius.circular(20),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          double width = constraints.maxWidth;

          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              buildActionCard(Icons.chat, "Chat", width),
              buildActionCard(Icons.report, "Complaints", width),
              buildActionCard(Icons.work, "Jobs", width),
              buildActionCard(Icons.search, "Lost", width),
            ],
          );
        },
      ),
    );
  }

  Widget buildActionCard(IconData icon, String title, double width) {
    return Material(
      color: const Color(0xFF53A252),
      borderRadius: BorderRadius.circular(14),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => navigate(title),
        child: SizedBox(
          width: (width - 12) / 2,
          height: 90,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white),
              Text(title, style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- ALERTS ----------------
  Widget buildRecentUpdates() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1F1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [const Text(
          "RECENT UPDATES",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFFEC6A00),
            letterSpacing: 1,
          ),
        ),
          buildAlertItem(Icons.work, "Electrician needed",
              "Urgent requirement", Colors.orange),
          buildAlertItem(Icons.search, "Wallet found",
              "Near school area", Colors.green),
          buildAlertItem(Icons.event, "Meeting Sunday",
              "Community discussion", Colors.red),
        ],
      ),
    );
  }

  Widget buildAlertItem(
      IconData icon, String title, String subtitle, Color color) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AlertDetailScreen(
              title: title,
              subtitle: subtitle,
              icon: icon,
              color: color,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Expanded(child: Text(title)),
          ],
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
}