import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class PollingScreen extends StatefulWidget {
  const PollingScreen({super.key});

  @override
  State<PollingScreen> createState() => _PollingScreenState();
}

class _PollingScreenState extends State<PollingScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final List<_Poll> _polls = [
    _Poll(
      id: 'POL-001',
      question: 'Where should we build the new community well?',
      options: [
        _PollOption('Near the temple grounds', 42, 0.42),
        _PollOption('Behind the school', 31, 0.31),
        _PollOption('Near the western entrance', 18, 0.18),
        _PollOption('Market area', 9, 0.09),
      ],
      totalVotes: 100,
      deadline: 'Mar 10, 2026',
      status: 'Active',
      createdBy: 'Development Committee',
      hasVoted: false,
    ),
    _Poll(
      id: 'POL-002',
      question: 'What day works best for the village clean-up drive?',
      options: [
        _PollOption('Saturday, March 15', 55, 0.55),
        _PollOption('Sunday, March 16', 35, 0.35),
        _PollOption('Saturday, March 22', 10, 0.10),
      ],
      totalVotes: 78,
      deadline: 'Mar 8, 2026',
      status: 'Active',
      createdBy: 'Youth Committee',
      hasVoted: true,
      votedOption: 0,
    ),
    _Poll(
      id: 'POL-003',
      question: 'Should we organize a weekly farmer\'s market?',
      options: [
        _PollOption('Yes, every Saturday', 89, 0.65),
        _PollOption('Yes, every Sunday', 28, 0.20),
        _PollOption('No, not needed', 20, 0.15),
      ],
      totalVotes: 137,
      deadline: 'Feb 28, 2026',
      status: 'Closed',
      createdBy: 'Village Committee',
      hasVoted: true,
      votedOption: 0,
    ),
    _Poll(
      id: 'POL-004',
      question: 'Priority for next quarter\'s budget allocation?',
      options: [
        _PollOption('Road repairs', 65, 0.50),
        _PollOption('School improvements', 40, 0.31),
        _PollOption('Healthcare facilities', 25, 0.19),
      ],
      totalVotes: 130,
      deadline: 'Feb 15, 2026',
      status: 'Closed',
      createdBy: 'GN Officer',
      hasVoted: true,
      votedOption: 1,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<_Poll> _filteredPolls(int tab) {
    switch (tab) {
      case 0:
        return _polls.where((p) => p.status == 'Active').toList();
      case 1:
        return _polls.where((p) => p.status == 'Closed').toList();
      case 2:
        return _polls.where((p) => p.createdBy.contains('Committee')).toList();
      default:
        return _polls;
    }
  }

  void _showCreatePollDialog() {
    final optionControllers = [
      TextEditingController(),
      TextEditingController(),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          height: MediaQuery.of(ctx).size.height * 0.8,
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Text('Create Poll', style: AppTextStyles.h2),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Question', style: AppTextStyles.label),
                      const SizedBox(height: 8),
                      TextFormField(
                        maxLines: 2,
                        decoration: _inputDecoration('Enter your question...'),
                      ),
                      const SizedBox(height: 20),
                      Text('Options', style: AppTextStyles.label),
                      const SizedBox(height: 8),
                      ...List.generate(optionControllers.length, (i) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: optionControllers[i],
                                  decoration: _inputDecoration(
                                    'Option ${i + 1}',
                                  ),
                                ),
                              ),
                              if (optionControllers.length > 2)
                                IconButton(
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                    color: AppColors.error,
                                    size: 22,
                                  ),
                                  onPressed: () {
                                    setSheetState(() {
                                      optionControllers.removeAt(i);
                                    });
                                  },
                                ),
                            ],
                          ),
                        );
                      }),
                      TextButton.icon(
                        onPressed: () {
                          setSheetState(() {
                            optionControllers.add(TextEditingController());
                          });
                        },
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: const Text('Add option'),
                      ),
                      const SizedBox(height: 20),
                      Text('Duration', style: AppTextStyles.label),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceGrey,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: '7 Days',
                            items: ['3 Days', '7 Days', '14 Days', '30 Days']
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e),
                                  ),
                                )
                                .toList(),
                            onChanged: (_) {},
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Poll published successfully!'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.poll_rounded),
                          label: const Text('Publish Poll'),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.surfaceGrey,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Community Polls'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Results'),
            Tab(text: 'My Polls'),
          ],
          onTap: (_) => setState(() {}),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreatePollDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Create Poll'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBar: const _CommitteeBottomBar(activeIndex: 2),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(3, (tabIndex) {
          final items = _filteredPolls(tabIndex);
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.poll_rounded,
                    size: 64,
                    color: AppColors.primary.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No polls found',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            );
          }
          return AnimationLimiter(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              itemCount: items.length,
              itemBuilder: (context, index) {
                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 375),
                  child: SlideAnimation(
                    verticalOffset: 40,
                    child: FadeInAnimation(child: _buildPollCard(items[index])),
                  ),
                );
              },
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPollCard(_Poll poll) {
    final isActive = poll.status == 'Active';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.successLight
                      : AppColors.surfaceGrey,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  poll.status,
                  style: AppTextStyles.small.copyWith(
                    color: isActive ? AppColors.success : AppColors.textMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
              const Spacer(),
              Icon(Icons.people_rounded, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(
                '${poll.totalVotes} votes',
                style: AppTextStyles.small.copyWith(fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Question
          Text(
            poll.question,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'by ${poll.createdBy}',
            style: AppTextStyles.small.copyWith(fontSize: 11),
          ),
          const SizedBox(height: 16),

          // Options with bars
          ...List.generate(poll.options.length, (i) {
            final option = poll.options[i];
            final isVoted = poll.hasVoted && poll.votedOption == i;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (!poll.hasVoted && isActive)
                        Radio<int>(
                          value: i,
                          groupValue: null,
                          onChanged: (_) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Vote cast for "${option.text}"'),
                              ),
                            );
                          },
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      if (isVoted)
                        const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.primary,
                            size: 18,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          option.text,
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: isVoted
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isVoted
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (poll.hasVoted || !isActive)
                        Text(
                          '${(option.percentage * 100).toInt()}%',
                          style: AppTextStyles.captionMedium.copyWith(
                            color: isVoted
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                  if (poll.hasVoted || !isActive) ...[
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: option.percentage,
                        backgroundColor: AppColors.surfaceGrey,
                        color: isVoted
                            ? AppColors.primary
                            : AppColors.primary.withOpacity(0.3),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),

          const SizedBox(height: 8),
          // Footer
          Row(
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 14,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                isActive ? 'Ends ${poll.deadline}' : 'Ended ${poll.deadline}',
                style: AppTextStyles.small.copyWith(
                  fontSize: 11,
                  color: isActive ? AppColors.warning : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PollOption {
  final String text;
  final int votes;
  final double percentage;
  const _PollOption(this.text, this.votes, this.percentage);
}

class _CommitteeBottomBar extends StatelessWidget {
  const _CommitteeBottomBar({required this.activeIndex});

  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.surfaceWarmSand)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            children: [
              _CommitteeNavItem(
                icon: Icons.task_alt_outlined,
                label: 'Tasks',
                active: activeIndex == 0,
                onTap: () => context.go('/committee/tasks'),
              ),
              _CommitteeNavItem(
                icon: Icons.event_outlined,
                label: 'Meetings',
                active: activeIndex == 1,
                onTap: () => context.go('/committee/meetings'),
              ),
              _CommitteeNavItem(
                icon: Icons.how_to_vote_outlined,
                label: 'Polls',
                active: activeIndex == 2,
                onTap: () => context.go('/committee/polls'),
              ),
              _CommitteeNavItem(
                icon: Icons.verified_user_outlined,
                label: 'Moderate',
                active: activeIndex == 3,
                onTap: () => context.go('/community/moderation'),
              ),
              _CommitteeNavItem(
                icon: Icons.person_outline,
                label: 'Profile',
                active: activeIndex == 4,
                onTap: () => context.push('/profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommitteeNavItem extends StatelessWidget {
  const _CommitteeNavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.active,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: active ? AppColors.brandGreen : AppColors.inkLight,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: (active ? AppTextStyles.tab : AppTextStyles.tabInactive)
                  .copyWith(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _Poll {
  final String id;
  final String question;
  final List<_PollOption> options;
  final int totalVotes;
  final String deadline;
  final String status;
  final String createdBy;
  final bool hasVoted;
  final int? votedOption;
  const _Poll({
    required this.id,
    required this.question,
    required this.options,
    required this.totalVotes,
    required this.deadline,
    required this.status,
    required this.createdBy,
    required this.hasVoted,
    this.votedOption,
  });
}
