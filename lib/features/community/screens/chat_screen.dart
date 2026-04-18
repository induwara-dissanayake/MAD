import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
class ChatScreen extends StatefulWidget {
  final String name; // 👈 ADD THIS

  const ChatScreen({super.key, required this.name});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();

  void sendMessage() async {
    if (controller.text.trim().isEmpty) return;

    final text = controller.text.trim();
    controller.clear();

    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('community_chats').add({
        'text': text,
        'senderId': user?.uid ?? 'unknown',
        'senderName': user?.displayName ?? 'Anonymous',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to send message: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECE5DD),

      appBar: AppBar(
  backgroundColor: const Color(0xFF2E7D32),
  title: Row(
    children: [
      const CircleAvatar(
        radius: 16,
        child: Icon(Icons.group, size: 18),
      ),
      const SizedBox(width: 10),
      Text(widget.name), // 👈 IMPORTANT
    ],
  ),
),
      body: Column(
        children: [

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('community_chats')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "Error: ${snapshot.error}",
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];
                
                if (docs.isEmpty) {
                  return const Center(child: Text("No messages yet. Be the first to say hi!"));
                }

                return ListView.builder(
                  controller: scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(10),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    
                    final isMe = data['senderId'] == FirebaseAuth.instance.currentUser?.uid;
                    
                    String timeStr = "";
                    if (data['timestamp'] != null) {
                      final date = (data['timestamp'] as Timestamp).toDate();
                      timeStr = TimeOfDay.fromDateTime(date).format(context);
                    } else {
                      timeStr = TimeOfDay.now().format(context);
                    }

                    return buildMessage(data['text'] ?? '', isMe, timeStr, data['senderName'] ?? '');
                  },
                );
              },
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            color: Colors.white,
            child: Row(
              children: [

                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: "Message...",
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 6),

                CircleAvatar(
                  backgroundColor: Color(0xFF2E7D32),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildMessage(String text, bool isMe, String time, String senderName) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(10),
        constraints: const BoxConstraints(maxWidth: 250),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFFDCF8C6) : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe && senderName.isNotEmpty) ...[
              Text(
                senderName,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(height: 2),
            ],
            Text(text),
            const SizedBox(height: 4),
            Text(time,
                style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}