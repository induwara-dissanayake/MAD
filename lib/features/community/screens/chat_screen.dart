import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class ChatScreen extends StatefulWidget {
  final String name; // 👈 ADD THIS

  const ChatScreen({super.key, required this.name});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();
  Timer? _debounce;
  bool _isTyping = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _updatePresence(false);
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    
    if (!_isTyping) {
      setState(() { _isTyping = true; });
      _updatePresence(true);
    }

    _debounce = Timer(const Duration(seconds: 2), () {
      if (mounted && _isTyping) {
        setState(() { _isTyping = false; });
        _updatePresence(false);
      }
    });
  }

  void _updatePresence(bool isTyping) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance.collection('community_chat_presence').doc(user.uid).set({
        'isTyping': isTyping,
        'timestamp': FieldValue.serverTimestamp(),
        'userName': user.displayName ?? 'Anonymous',
      }, SetOptions(merge: true));
    }
  }

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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.name, style: const TextStyle(fontSize: 18)),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('community_chat_presence')
                        .where('isTyping', isEqualTo: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Text("Online", style: TextStyle(fontSize: 12, color: Colors.white70));
                      
                      final typingDocs = snapshot.data!.docs.where((d) => d.id != FirebaseAuth.instance.currentUser?.uid).toList();
                      
                      if (typingDocs.isEmpty) {
                        return const Text("Online", style: TextStyle(fontSize: 12, color: Colors.white70));
                      }
                      
                      if (typingDocs.length == 1) {
                        final name = (typingDocs.first.data() as Map<String, dynamic>)['userName'] ?? 'Someone';
                        return Text("$name is typing...", style: const TextStyle(fontSize: 12, color: Colors.white70, fontStyle: FontStyle.italic));
                      } else {
                        return const Text("Multiple people typing...", style: TextStyle(fontSize: 12, color: Colors.white70, fontStyle: FontStyle.italic));
                      }
                    },
                  ),
                ],
              ),
            ),
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
                    DateTime messageDate = DateTime.now();
                    if (data['timestamp'] != null) {
                      messageDate = (data['timestamp'] as Timestamp).toDate();
                      timeStr = TimeOfDay.fromDateTime(messageDate).format(context);
                    } else {
                      timeStr = TimeOfDay.now().format(context);
                    }

                    bool showDateHeader = false;
                    if (index == docs.length - 1) {
                      showDateHeader = true; // Oldest message always shows date
                    } else {
                      final prevData = docs[index + 1].data() as Map<String, dynamic>;
                      DateTime prevDate = DateTime.now();
                      if (prevData['timestamp'] != null) {
                        prevDate = (prevData['timestamp'] as Timestamp).toDate();
                      }
                      
                      if (!_isSameDay(messageDate, prevDate)) {
                        showDateHeader = true;
                      }
                    }

                    final messageWidget = buildMessage(data['text'] ?? '', isMe, timeStr, data['senderName'] ?? '');
                    
                    if (showDateHeader) {
                      return Column(
                        children: [
                          _buildDateHeader(messageDate),
                          messageWidget,
                        ],
                      );
                    }
                    return messageWidget;
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
                    onChanged: _onSearchChanged,
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
        margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
        padding: const EdgeInsets.only(left: 10, right: 10, top: 8, bottom: 4),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFFDCF8C6) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 1,
              offset: const Offset(0, 1),
            )
          ]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
            Text(text, style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 2),
            Align(
              alignment: Alignment.bottomRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(time, style: const TextStyle(fontSize: 10, color: Colors.black54)),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.done_all, size: 14, color: Colors.blue),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  Widget _buildDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final messageDate = DateTime(date.year, date.month, date.day);

    String dateStr;
    if (messageDate == today) {
      dateStr = "Today";
    } else if (messageDate == yesterday) {
      dateStr = "Yesterday";
    } else {
      dateStr = "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE1F5FE),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ]
      ),
      child: Text(
        dateStr,
        style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w500),
      ),
    );
  }
}