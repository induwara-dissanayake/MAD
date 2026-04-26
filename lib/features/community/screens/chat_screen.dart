import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'dart:async' show Timer, TimeoutException;

class ChatScreen extends StatefulWidget {
  final String name;
  const ChatScreen({super.key, required this.name});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  bool _isTyping = false;
  bool _showEmojiPicker = false;
  bool _isUploading = false;

  // Reply state
  Map<String, dynamic>? _replyingTo;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus && _showEmojiPicker) {
        setState(() { _showEmojiPicker = false; });
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _updatePresence(false);
    controller.dispose();
    scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged(String query) {
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

  void _toggleEmojiPicker() {
    if (_showEmojiPicker) {
      _focusNode.requestFocus();
      setState(() { _showEmojiPicker = false; });
    } else {
      _focusNode.unfocus();
      setState(() { _showEmojiPicker = true; });
    }
  }

  void _updatePresence(bool isTyping) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('community_chat_presence')
          .doc('${user.uid}_${widget.name}')
          .set({
        'isTyping': isTyping,
        'room': widget.name,
        'timestamp': FieldValue.serverTimestamp(),
        'userName': user.displayName ?? 'Anonymous',
        'userId': user.uid,
      }, SetOptions(merge: true));
    }
  }

  void sendMessage({String? imageUrl, String? fileUrl, String? fileName}) async {
    final text = controller.text.trim();
    if (text.isEmpty && imageUrl == null && fileUrl == null) return;

    controller.clear();
    final replySnapshot = _replyingTo;
    setState(() { _replyingTo = null; });

    try {
      final user = FirebaseAuth.instance.currentUser;
      final payload = <String, dynamic>{
        'room': widget.name,
        'senderId': user?.uid ?? 'unknown',
        'senderName': user?.displayName ?? 'Anonymous',
        'status': 'sent',
        'timestamp': FieldValue.serverTimestamp(),
      };

      if (text.isNotEmpty) payload['text'] = text;
      if (imageUrl != null) payload['imageUrl'] = imageUrl;
      if (fileUrl != null) { payload['fileUrl'] = fileUrl; payload['fileName'] = fileName; }
      if (replySnapshot != null) {
        payload['replyToText'] = replySnapshot['text'] ?? '';
        payload['replyToSender'] = replySnapshot['senderName'] ?? 'Unknown';
      }

      await FirebaseFirestore.instance.collection('community_chats').add(payload);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked == null) return;

    setState(() { _isUploading = true; });

    try {
      // Step 1: Read bytes
      final bytes = await picked.readAsBytes();
      if (bytes.isEmpty) throw Exception('Step 1 failed: image bytes are empty.');

      // Step 2: Upload to Firebase Storage with timeout
      final ref = FirebaseStorage.instance
          .ref()
          .child('chat_images/${DateTime.now().millisecondsSinceEpoch}.jpg');

      final task = ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));

      // Listen for state changes for debugging
      task.snapshotEvents.listen((snapshot) {
        debugPrint('Upload state: ${snapshot.state}, bytes: ${snapshot.bytesTransferred}/${snapshot.totalBytes}');
      });

      // Wait with timeout
      final snapshot = await task.timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException('Upload timed out after 30s. Check Firebase Storage CORS settings.'),
      );

      if (snapshot.state != TaskState.success) {
        throw Exception('Upload did not complete. State: ${snapshot.state}');
      }

      // Step 3: Get download URL
      final url = await ref.getDownloadURL();
      if (url.isEmpty) throw Exception('Step 3 failed: download URL is empty.');

      // Step 4: Send message
      sendMessage(imageUrl: url);

    } on TimeoutException catch (e) {
      if (mounted) _showError('Upload Timed Out', '${e.message}\n\nPlease check:\n1. Firebase Storage rules allow authenticated users.\n2. Firebase Storage CORS is configured for web.');
    } catch (e) {
      if (mounted) _showError('Image Upload Failed', e.toString());
    } finally {
      if (mounted) setState(() { _isUploading = false; });
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result == null || result.files.single.bytes == null) return;

    setState(() { _isUploading = true; });
    try {
      final bytes = result.files.single.bytes!;
      final fileName = result.files.single.name;
      final ref = FirebaseStorage.instance
          .ref()
          .child('chat_files/${DateTime.now().millisecondsSinceEpoch}_$fileName');
      await ref.putData(bytes);
      final url = await ref.getDownloadURL();
      sendMessage(fileUrl: url, fileName: fileName);
    } catch (e) {
      if (mounted) _showError('File Upload Failed', e.toString());
    } finally {
      if (mounted) setState(() { _isUploading = false; });
    }
  }

  void _showError(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(message)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            const Text('Send Attachment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _attachOption(Icons.photo_library, 'Gallery', Colors.purple, () {
                  Navigator.pop(context);
                  _pickImage();
                }),
                _attachOption(Icons.camera_alt, 'Camera', Colors.red, () async {
                  Navigator.pop(context);
                  final picker = ImagePicker();
                  final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
                  if (picked == null) return;
                  setState(() { _isUploading = true; });
                  try {
                    final bytes = await picked.readAsBytes();
                    final ref = FirebaseStorage.instance.ref().child('chat_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
                    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
                    final url = await ref.getDownloadURL();
                    sendMessage(imageUrl: url);
                  } finally {
                    if (mounted) setState(() { _isUploading = false; });
                  }
                }),
                _attachOption(Icons.insert_drive_file, 'File', Colors.blue, () {
                  Navigator.pop(context);
                  _pickFile();
                }),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _attachOption(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _startReply(Map<String, dynamic> data) {
    setState(() { _replyingTo = data; });
    _focusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() { _replyingTo = null; });
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
              backgroundColor: Color(0xFF1B5E20),
              child: Icon(Icons.group, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.name, style: const TextStyle(fontSize: 16, color: Colors.white)),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('community_chat_presence').snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Text('Online', style: TextStyle(fontSize: 12, color: Colors.white70));
                      final typingDocs = snapshot.data!.docs.where((d) {
                        final data = d.data() as Map<String, dynamic>;
                        return data['room'] == widget.name &&
                            data['isTyping'] == true &&
                            data['userId'] != FirebaseAuth.instance.currentUser?.uid;
                      }).toList();
                      if (typingDocs.isEmpty) return const Text('Online', style: TextStyle(fontSize: 12, color: Colors.white70));
                      if (typingDocs.length == 1) {
                        final name = (typingDocs.first.data() as Map<String, dynamic>)['userName'] ?? 'Someone';
                        return Text('$name is typing...', style: const TextStyle(fontSize: 12, color: Colors.white70, fontStyle: FontStyle.italic));
                      }
                      return const Text('Multiple people typing...', style: TextStyle(fontSize: 12, color: Colors.white70, fontStyle: FontStyle.italic));
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
          // Upload progress bar
          if (_isUploading)
            const LinearProgressIndicator(
              backgroundColor: Color(0xFFB8E6B0),
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
            ),

          // Messages
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('community_chats')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                final allDocs = snapshot.data?.docs ?? [];
                final docs = allDocs.where((d) => (d.data() as Map<String, dynamic>)['room'] == widget.name).toList();

                if (docs.isEmpty) return const Center(child: Text('No messages yet. Be the first to say hi!'));

                return ListView.builder(
                  controller: scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(10),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final isMe = data['senderId'] == FirebaseAuth.instance.currentUser?.uid;

                    String timeStr = '';
                    DateTime messageDate = DateTime.now();
                    if (data['timestamp'] != null) {
                      messageDate = (data['timestamp'] as Timestamp).toDate();
                      timeStr = TimeOfDay.fromDateTime(messageDate).format(context);
                    } else {
                      timeStr = TimeOfDay.now().format(context);
                    }

                    bool showDateHeader = false;
                    if (index == docs.length - 1) {
                      showDateHeader = true;
                    } else {
                      final prevData = docs[index + 1].data() as Map<String, dynamic>;
                      DateTime prevDate = DateTime.now();
                      if (prevData['timestamp'] != null) prevDate = (prevData['timestamp'] as Timestamp).toDate();
                      if (!_isSameDay(messageDate, prevDate)) showDateHeader = true;
                    }

                    final messageWidget = GestureDetector(
                      onLongPress: () => _startReply(data),
                      child: buildMessage(data, isMe, timeStr),
                    );

                    if (showDateHeader) {
                      return Column(children: [_buildDateHeader(messageDate), messageWidget]);
                    }
                    return messageWidget;
                  },
                );
              },
            ),
          ),

          // Reply banner
          if (_replyingTo != null)
            Container(
              color: const Color(0xFFD9FCBA),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 3, height: 36,
                    decoration: BoxDecoration(color: const Color(0xFF2E7D32), borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Replying to ${_replyingTo!['senderName'] ?? 'Unknown'}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                        Text(_replyingTo!['text'] ?? '',
                            style: const TextStyle(fontSize: 12, color: Colors.black54),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close, size: 18, color: Colors.black54), onPressed: _cancelReply),
                ],
              ),
            ),

          // Input bar
          Container(
            padding: const EdgeInsets.only(left: 8, right: 8, bottom: 12, top: 8),
            color: Colors.transparent,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Emoji toggle
                        IconButton(
                          icon: Icon(
                            _showEmojiPicker ? Icons.keyboard : Icons.emoji_emotions_outlined,
                            color: Colors.grey,
                          ),
                          onPressed: _toggleEmojiPicker,
                        ),
                        Expanded(
                          child: TextField(
                            controller: controller,
                            focusNode: _focusNode,
                            onChanged: _onTextChanged,
                            decoration: const InputDecoration(
                              hintText: 'Message',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 10),
                            ),
                            minLines: 1,
                            maxLines: 4,
                          ),
                        ),
                        // Attachment
                        IconButton(
                          icon: const Icon(Icons.attach_file, color: Colors.grey),
                          onPressed: _showAttachmentOptions,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFF00A884),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: () => sendMessage(),
                  ),
                ),
              ],
            ),
          ),

          // Emoji picker
          Offstage(
            offstage: !_showEmojiPicker,
            child: SizedBox(
              height: 280,
              child: EmojiPicker(
                textEditingController: controller,
                onEmojiSelected: (category, emoji) {
                  controller.text += emoji.emoji;
                  controller.selection = TextSelection.fromPosition(
                    TextPosition(offset: controller.text.length),
                  );
                },
                config: Config(
                  height: 280,
                  emojiViewConfig: const EmojiViewConfig(
                    emojiSizeMax: 28,
                    backgroundColor: Color(0xFFF5F5F5),
                  ),
                  categoryViewConfig: const CategoryViewConfig(
                    indicatorColor: Color(0xFF2E7D32),
                    iconColorSelected: Color(0xFF2E7D32),
                    backgroundColor: Colors.white,
                  ),
                  bottomActionBarConfig: const BottomActionBarConfig(
                    backgroundColor: Colors.white,
                    buttonColor: Color(0xFF2E7D32),
                  ),
                  searchViewConfig: const SearchViewConfig(
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildMessage(Map<String, dynamic> data, bool isMe, String time) {
    final text = data['text'] as String? ?? '';
    final imageUrl = data['imageUrl'] as String?;
    final fileUrl = data['fileUrl'] as String?;
    final fileName = data['fileName'] as String?;
    final senderName = data['senderName'] as String? ?? '';
    final status = data['status'] as String? ?? 'read';
    final replyToText = data['replyToText'] as String?;
    final replyToSender = data['replyToSender'] as String?;

    Widget bubble = Container(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 8, bottom: 4),
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFFE7FFDB) : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(12),
          topRight: const Radius.circular(12),
          bottomLeft: Radius.circular(isMe ? 12 : 0),
          bottomRight: Radius.circular(isMe ? 0 : 12),
        ),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 1, offset: const Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sender name
          if (!isMe && senderName.isNotEmpty) ...[
            Text(senderName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
            const SizedBox(height: 2),
          ],

          // Quoted reply block
          if (replyToText != null && replyToText.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.only(left: 8, top: 6, right: 8, bottom: 6),
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFFB2DFDB) : const Color(0xFFECEFF1),
                borderRadius: BorderRadius.circular(8),
                border: const Border(left: BorderSide(color: Color(0xFF2E7D32), width: 3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(replyToSender ?? 'Unknown', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                  const SizedBox(height: 2),
                  Text(replyToText, style: const TextStyle(fontSize: 12, color: Colors.black54), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],

          // Image
          if (imageUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(imageUrl, width: 220, fit: BoxFit.cover,
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : SizedBox(width: 220, height: 120,
                          child: Center(child: CircularProgressIndicator(value: progress.expectedTotalBytes != null
                              ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes! : null)))),
            ),
            const SizedBox(height: 4),
          ],

          // File
          if (fileUrl != null) ...[
            GestureDetector(
              onTap: () {
                // Could open URL launcher here
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.insert_drive_file, color: Color(0xFF2E7D32), size: 22),
                    const SizedBox(width: 8),
                    Flexible(child: Text(fileName ?? 'File', style: const TextStyle(fontSize: 13, color: Colors.black87),
                        overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
          ],

          // Text
          if (text.isNotEmpty) ...[
            Text(text, style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 2),
          ],

          // Time + status
          Align(
            alignment: Alignment.bottomRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(time, style: const TextStyle(fontSize: 10, color: Colors.black54)),
                if (isMe) ...[const SizedBox(width: 4), _buildStatusIcon(status)],
              ],
            ),
          ),
        ],
      ),
    );

    if (isMe) {
      return Align(
        alignment: Alignment.centerRight,
        child: Padding(padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8), child: bubble),
      );
    } else {
      final initial = senderName.isNotEmpty ? senderName[0].toUpperCase() : 'U';
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: Colors.primaries[senderName.hashCode % Colors.primaries.length],
              child: Text(initial, style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 6),
            Expanded(child: Align(alignment: Alignment.centerLeft, child: bubble)),
          ],
        ),
      );
    }
  }

  Widget _buildStatusIcon(String status) {
    if (status == 'sent') return const Icon(Icons.check, size: 14, color: Colors.grey);
    if (status == 'delivered') return const Icon(Icons.done_all, size: 14, color: Colors.grey);
    return const Icon(Icons.done_all, size: 14, color: Colors.blue);
  }

  bool _isSameDay(DateTime d1, DateTime d2) =>
      d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;

  Widget _buildDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final md = DateTime(date.year, date.month, date.day);

    String dateStr;
    if (md == today) dateStr = 'Today';
    else if (md == yesterday) dateStr = 'Yesterday';
    else dateStr = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE1F5FE),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2, offset: const Offset(0, 1))],
      ),
      child: Text(dateStr, style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w500)),
    );
  }
}