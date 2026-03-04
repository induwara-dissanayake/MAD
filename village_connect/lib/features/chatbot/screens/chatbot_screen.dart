import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen>
    with TickerProviderStateMixin {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  String _selectedLanguage = 'English';
  bool _isTyping = false;
  bool _showScrollToBottom = false;
  bool _hasInputText = false;

  final List<_ChatMessage> _messages = [
    _ChatMessage(
      text:
          "Hello! I'm your Village Connect AI Assistant. I can help you with:\n\n\u2022 Applying for documents\n\u2022 Tracking applications\n\u2022 Finding office hours & contacts\n\u2022 Understanding village services\n\nHow can I help you today?",
      isBot: true,
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    _ChatMessage(
      text: 'How do I apply for a character certificate?',
      isBot: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
    ),
    _ChatMessage(
      text:
          "Great question! Here's how to apply for a character certificate:\n\n1. Go to **Home** \u2192 **Apply for Document**\n2. Select **Character Certificate**\n3. Fill in your personal details\n4. Upload a clear copy of your NIC (front & back)\n5. Review and submit\n\nProcessing usually takes 3-5 working days. You'll receive a notification when it's ready for collection at the GN Office.",
      isBot: true,
      timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
    ),
  ];

  final List<String> _suggestions = [
    'Track my application',
    'GN Office hours',
    'Upload documents',
    'Report an issue',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _messageController.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final isAtBottom = _scrollController.offset >=
        _scrollController.position.maxScrollExtent - 80;
    if (_showScrollToBottom == isAtBottom) {
      setState(() => _showScrollToBottom = !isAtBottom);
    }
  }

  void _onInputChanged() {
    final hasText = _messageController.text.trim().isNotEmpty;
    if (hasText != _hasInputText) {
      setState(() => _hasInputText = hasText);
    }
  }

  void _clearChat() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Clear Chat',
          style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Are you sure you want to clear the conversation? This cannot be undone.',
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(),
            child: Text(
              'Cancel',
              style: AppTextStyles.button.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              ctx.pop();
              setState(() {
                _messages.clear();
                _messages.add(
                  _ChatMessage(
                    text:
                        "Hello! I'm your Village Connect AI Assistant. I can help you with:\n\n\u2022 Applying for documents\n\u2022 Tracking applications\n\u2022 Finding office hours & contacts\n\u2022 Understanding village services\n\nHow can I help you today?",
                    isBot: true,
                    timestamp: DateTime.now(),
                  ),
                );
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error.withOpacity(0.1),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Clear',
              style: AppTextStyles.button.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages
          .add(_ChatMessage(text: text, isBot: false, timestamp: DateTime.now()));
      _messageController.clear();
      _isTyping = true;
    });

    _scrollToBottom();

    // Simulate bot response
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(
            _ChatMessage(
              text:
                  "Thank you for your question. I'm processing your request. In the meantime, you can visit the GN Office during working hours (8:30 AM \u2013 4:30 PM, Mon-Fri) for in-person assistance.",
              isBot: true,
              timestamp: DateTime.now(),
            ),
          );
        });
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _copyMessage(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Text('Message copied', style: AppTextStyles.small.copyWith(color: Colors.white)),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final hour12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$hour12:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(child: _buildMessagesList()),
              if (_isTyping) _buildTypingIndicator(),
              _buildSuggestions(),
              _buildInputArea(),
            ],
          ),
          // Scroll to bottom FAB
          if (_showScrollToBottom)
            Positioned(
              right: 16,
              bottom: 140,
              child: _buildScrollToBottomButton(),
            ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.card,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceGrey.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.textPrimary,
              size: 20,
            ),
          ),
          onPressed: () => context.pop(),
        ),
      ),
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.info],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Assistant',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.success.withOpacity(0.5),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isTyping ? 'Typing...' : 'Online',
                    style: AppTextStyles.small.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      centerTitle: false,
      actions: [
        _buildLanguageDropdown(),
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.delete_sweep_rounded,
              color: AppColors.error,
              size: 20,
            ),
          ),
          tooltip: 'Clear chat',
          onPressed: _clearChat,
        ),
        const SizedBox(width: 8),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          decoration: BoxDecoration(
            color: AppColors.border.withOpacity(0.3),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowLight.withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageDropdown() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceGrey.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedLanguage,
          isDense: true,
          icon: const Padding(
            padding: EdgeInsets.only(left: 4.0),
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ),
          style: AppTextStyles.small.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          items: [
            'English',
            '\u0DC3\u0DD2\u0D82\u0DC4\u0DBD',
            '\u0BA4\u0BAE\u0BBF\u0BB4\u0BCD',
          ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) =>
              setState(() => _selectedLanguage = v ?? 'English'),
        ),
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final showDateSeparator = index == 0 ||
            !_isSameDay(
                _messages[index - 1].timestamp, message.timestamp);

        return Column(
          children: [
            if (showDateSeparator) _buildDateSeparator(message.timestamp),
            _MessageBubbleAnimated(
              key: ValueKey('msg_${message.timestamp.millisecondsSinceEpoch}_$index'),
              message: message,
              timeLabel: _formatTime(message.timestamp),
              onLongPress: () => _copyMessage(message.text),
            ),
          ],
        );
      },
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _buildDateSeparator(DateTime date) {
    final now = DateTime.now();
    String label;
    if (_isSameDay(date, now)) {
      label = 'Today';
    } else if (_isSameDay(date, now.subtract(const Duration(days: 1)))) {
      label = 'Yesterday';
    } else {
      label =
          '${date.day}/${date.month}/${date.year}';
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(height: 1, color: AppColors.border.withOpacity(0.4)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              label,
              style: AppTextStyles.small.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Container(height: 1, color: AppColors.border.withOpacity(0.4)),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 12, bottom: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.info],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(20),
                ),
                border: Border.all(color: AppColors.border.withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowLight.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const _TypingDots(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestions() {
    // Hide suggestions while typing input or when bot is responding
    if (_hasInputText || _isTyping) return const SizedBox.shrink();

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _suggestions.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _messageController.text = _suggestions[index];
                    _sendMessage();
                  },
                  borderRadius: BorderRadius.circular(22),
                  splashColor: AppColors.primary.withOpacity(0.12),
                  highlightColor: AppColors.primary.withOpacity(0.06),
                  child: Ink(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(22),
                      border:
                          Border.all(color: AppColors.primary.withOpacity(0.18)),
                    ),
                    child: Center(
                      child: Text(
                        _suggestions[index],
                        style: AppTextStyles.small.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: _hasInputText
              ? AppColors.primary.withOpacity(0.4)
              : AppColors.border.withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.add_circle_outline_rounded,
                  color: AppColors.textMuted,
                ),
                onPressed: () {},
                tooltip: 'Attach file',
              ),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 4,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Ask the assistant...',
                    hintStyle: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textMuted,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.only(bottom: 4, right: 4),
                decoration: BoxDecoration(
                  gradient: _hasInputText
                      ? const LinearGradient(
                          colors: [AppColors.primary, AppColors.info],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : LinearGradient(
                          colors: [
                            AppColors.surfaceGrey,
                            AppColors.surfaceGrey,
                          ],
                        ),
                  shape: BoxShape.circle,
                  boxShadow: _hasInputText
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _hasInputText ? _sendMessage : null,
                    borderRadius: BorderRadius.circular(24),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Icon(
                        Icons.send_rounded,
                        color: _hasInputText ? Colors.white : AppColors.textMuted,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScrollToBottomButton() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Material(
        color: AppColors.card,
        shape: const CircleBorder(),
        elevation: 4,
        shadowColor: AppColors.shadowLight,
        child: InkWell(
          onTap: _scrollToBottom,
          customBorder: const CircleBorder(),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border.withOpacity(0.5)),
            ),
            child: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.textSecondary,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Animated Message Bubble ────────────────────────────────────────────────

class _MessageBubbleAnimated extends StatefulWidget {
  final _ChatMessage message;
  final String timeLabel;
  final VoidCallback onLongPress;

  const _MessageBubbleAnimated({
    super.key,
    required this.message,
    required this.timeLabel,
    required this.onLongPress,
  });

  @override
  State<_MessageBubbleAnimated> createState() => _MessageBubbleAnimatedState();
}

class _MessageBubbleAnimatedState extends State<_MessageBubbleAnimated>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.message;

    return SlideTransition(
      position: _slideAnim,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: 6,
            left: message.isBot ? 0 : 48,
            right: message.isBot ? 48 : 0,
          ),
          child: Column(
            crossAxisAlignment: message.isBot
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.end,
            children: [
              GestureDetector(
                onLongPress: () {
                  HapticFeedback.mediumImpact();
                  widget.onLongPress();
                },
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: message.isBot
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.end,
                  children: [
                    if (message.isBot) ...[
                      Container(
                        width: 32,
                        height: 32,
                        margin: const EdgeInsets.only(right: 12, bottom: 4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.info],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.smart_toy_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ],
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 14),
                        decoration: BoxDecoration(
                          color:
                              message.isBot ? AppColors.card : AppColors.primary,
                          gradient: message.isBot
                              ? null
                              : const LinearGradient(
                                  colors: [
                                    Color(0xFF2563EB),
                                    Color(0xFF1D4ED8)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(20),
                            topRight: const Radius.circular(20),
                            bottomLeft:
                                Radius.circular(message.isBot ? 4 : 20),
                            bottomRight:
                                Radius.circular(message.isBot ? 20 : 4),
                          ),
                          border: message.isBot
                              ? Border.all(
                                  color: AppColors.border.withOpacity(0.5))
                              : null,
                          boxShadow: [
                            BoxShadow(
                              color: (message.isBot
                                      ? AppColors.shadowLight
                                      : AppColors.primary)
                                  .withOpacity(0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          message.text,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: message.isBot
                                ? AppColors.textPrimary
                                : Colors.white,
                            height: 1.5,
                            fontWeight:
                                message.isBot ? FontWeight.w500 : FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  top: 4,
                  left: message.isBot ? 44 : 0,
                  right: message.isBot ? 0 : 0,
                  bottom: 10,
                ),
                child: Text(
                  widget.timeLabel,
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Typing Dots Animation ──────────────────────────────────────────────────

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i * 0.2;
            final t = (_controller.value - delay).clamp(0.0, 1.0);
            // Bounce up and down
            final y = -3.0 * (1 - (2 * t - 1) * (2 * t - 1));
            return Container(
              margin: EdgeInsets.only(right: i < 2 ? 5 : 0),
              child: Transform.translate(
                offset: Offset(0, y),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withOpacity(0.5 + 0.5 * (1 - t)),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

// ─── Chat Message Model ─────────────────────────────────────────────────────

class _ChatMessage {
  final String text;
  final bool isBot;
  final DateTime timestamp;

  const _ChatMessage({
    required this.text,
    required this.isBot,
    required this.timestamp,
  });
}
