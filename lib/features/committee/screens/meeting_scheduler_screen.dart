import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class MeetingSchedulerScreen extends StatefulWidget {
  const MeetingSchedulerScreen({super.key});

  @override
  State<MeetingSchedulerScreen> createState() => _MeetingSchedulerScreenState();
}

class _MeetingSchedulerScreenState extends State<MeetingSchedulerScreen> {
  DateTime _focusedMonth = DateTime(2026, 3);
  int _selectedDay = 3;

  final List<_Meeting> _meetings = [
    _Meeting(
      title: 'Monthly Committee Review',
      date: 'Mar 5, 2026',
      time: '10:00 AM – 12:00 PM',
      location: 'Community Hall',
      attendees: 8,
      agenda:
          'Review monthly progress, discuss budget allocation, plan community clean-up drive.',
      status: 'Upcoming',
    ),
    _Meeting(
      title: 'Water Supply Discussion',
      date: 'Mar 10, 2026',
      time: '2:00 PM – 3:30 PM',
      location: 'GN Office',
      attendees: 5,
      agenda:
          'Address water supply disruptions in eastern sector, coordinate with Water Board.',
      status: 'Upcoming',
    ),
    _Meeting(
      title: 'Youth Committee Planning',
      date: 'Mar 15, 2026',
      time: '4:00 PM – 5:30 PM',
      location: 'School Auditorium',
      attendees: 12,
      agenda:
          'Plan New Year festival events, assign responsibilities to youth volunteers.',
      status: 'Upcoming',
    ),
    _Meeting(
      title: 'Emergency Preparedness Training',
      date: 'Mar 20, 2026',
      time: '9:00 AM – 11:00 AM',
      location: 'Community Ground',
      attendees: 25,
      agenda:
          'Flood and fire safety training session for village committee members and volunteers.',
      status: 'Upcoming',
    ),
    _Meeting(
      title: 'Road Repair Follow-up',
      date: 'Feb 28, 2026',
      time: '3:00 PM – 4:00 PM',
      location: 'GN Office',
      attendees: 4,
      agenda:
          'Review progress of road repair on Kandy Road, discuss remaining budget.',
      status: 'Past',
    ),
  ];

  // Days in March 2026 that have meetings
  final Set<int> _meetingDays = {5, 10, 15, 20};

  void _showCreateMeetingDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.85,
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
                  Text('Schedule Meeting', style: AppTextStyles.h2),
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
                    _formLabel('Meeting Title'),
                    const SizedBox(height: 8),
                    _formTextField('Enter meeting title'),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _formLabel('Date'),
                              const SizedBox(height: 8),
                              _datePickerField(
                                Icons.calendar_today_rounded,
                                'Select date',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _formLabel('Time'),
                              const SizedBox(height: 8),
                              _datePickerField(
                                Icons.access_time_rounded,
                                'Select time',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _formLabel('Location'),
                    const SizedBox(height: 8),
                    _formTextField('Enter meeting location'),
                    const SizedBox(height: 20),
                    _formLabel('Agenda'),
                    const SizedBox(height: 8),
                    _formTextField(
                      'Meeting agenda and discussion points...',
                      maxLines: 4,
                    ),
                    const SizedBox(height: 20),
                    _formLabel('Invite Members'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _memberChip('Nihal P.', true),
                        _memberChip('Priya S.', true),
                        _memberChip('Kasun F.', false),
                        _memberChip('Amaya D.', true),
                        _memberChip('Ranjith K.', false),
                        _memberChip('+ Add', false, isAdd: true),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Icon(
                          Icons.notifications_active_rounded,
                          size: 20,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Send reminder notification',
                          style: AppTextStyles.bodyMedium,
                        ),
                        const Spacer(),
                        Switch(
                          value: true,
                          onChanged: (_) {},
                          activeThumbColor: AppColors.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Meeting scheduled successfully!'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.event_available_rounded),
                        label: const Text('Schedule Meeting'),
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
    );
  }

  Widget _memberChip(String name, bool selected, {bool isAdd = false}) {
    return FilterChip(
      label: Text(name),
      selected: selected,
      onSelected: (_) {},
      avatar: isAdd ? const Icon(Icons.add_rounded, size: 18) : null,
      backgroundColor: isAdd ? AppColors.primaryLight : null,
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isAdd
            ? AppColors.primary
            : selected
            ? Colors.white
            : AppColors.textPrimary,
        fontWeight: FontWeight.w500,
        fontSize: 13,
      ),
      checkmarkColor: Colors.white,
    );
  }

  Widget _formLabel(String text) => Text(text, style: AppTextStyles.label);

  Widget _formTextField(String hint, {int maxLines = 1}) {
    return TextFormField(
      maxLines: maxLines,
      decoration: InputDecoration(
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
      ),
    );
  }

  Widget _datePickerField(IconData icon, String hint) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceGrey,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.textMuted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                hint,
                style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMeetingDetail(_Meeting meeting) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.55,
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
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: meeting.status == 'Past'
                                ? AppColors.surfaceGrey
                                : AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            meeting.status,
                            style: AppTextStyles.small.copyWith(
                              color: meeting.status == 'Past'
                                  ? AppColors.textMuted
                                  : AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(meeting.title, style: AppTextStyles.h2),
                    const SizedBox(height: 20),
                    _meetingDetailRow(
                      Icons.calendar_today_rounded,
                      'Date',
                      meeting.date,
                    ),
                    _meetingDetailRow(
                      Icons.access_time_rounded,
                      'Time',
                      meeting.time,
                    ),
                    _meetingDetailRow(
                      Icons.location_on_rounded,
                      'Location',
                      meeting.location,
                    ),
                    _meetingDetailRow(
                      Icons.people_rounded,
                      'Attendees',
                      '${meeting.attendees} members',
                    ),
                    const SizedBox(height: 12),
                    Text('Agenda', style: AppTextStyles.label),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceGrey,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        meeting.agenda,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (meeting.status != 'Past')
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.pop(ctx),
                              icon: const Icon(Icons.edit_rounded, size: 18),
                              label: const Text('Edit'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.pop(ctx),
                              icon: const Icon(
                                Icons.notification_add_rounded,
                                size: 18,
                              ),
                              label: const Text('Remind'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _meetingDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textMuted),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
            ),
          ),
          Expanded(child: Text(value, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Meeting Scheduler')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateMeetingDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Schedule'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBar: const _CommitteeBottomBar(activeIndex: 1),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Calendar Header
            _buildCalendar(),
            const SizedBox(height: 8),
            // Upcoming Meetings
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text('Upcoming Meetings', style: AppTextStyles.h3),
            ),
            AnimationLimiter(
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                itemCount: _meetings.length,
                itemBuilder: (context, index) {
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 375),
                    child: SlideAnimation(
                      verticalOffset: 40,
                      child: FadeInAnimation(
                        child: _buildMeetingCard(_meetings[index]),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    final daysInMonth = 31; // March 2026
    final firstWeekday = 6; // March 1, 2026 is a Sunday (0=Mon so 6=Sun)

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
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
        children: [
          // Month navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: () {},
                color: AppColors.textSecondary,
              ),
              Text(
                'March 2026',
                style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w600),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: () {},
                color: AppColors.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Day headers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                .map(
                  (d) => SizedBox(
                    width: 36,
                    child: Center(
                      child: Text(
                        d,
                        style: AppTextStyles.small.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          // Day cells
          ...List.generate(5, (weekRow) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(7, (col) {
                  final dayNum = weekRow * 7 + col - firstWeekday + 1;
                  if (dayNum < 1 || dayNum > daysInMonth) {
                    return const SizedBox(width: 36, height: 36);
                  }
                  final isSelected = dayNum == _selectedDay;
                  final hasMeeting = _meetingDays.contains(dayNum);
                  final isToday = dayNum == 3;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedDay = dayNum),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : isToday
                            ? AppColors.primaryLight
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            '$dayNum',
                            style: AppTextStyles.captionMedium.copyWith(
                              color: isSelected
                                  ? Colors.white
                                  : isToday
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                              fontWeight: isSelected || isToday
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                          if (hasMeeting && !isSelected)
                            Positioned(
                              bottom: 3,
                              child: Container(
                                width: 5,
                                height: 5,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMeetingCard(_Meeting meeting) {
    final isPast = meeting.status == 'Past';
    return GestureDetector(
      onTap: () => _showMeetingDetail(meeting),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isPast ? AppColors.surfaceGrey : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPast
                ? AppColors.border.withOpacity(0.4)
                : AppColors.border.withOpacity(0.6),
          ),
          boxShadow: isPast
              ? null
              : [
                  BoxShadow(
                    color: AppColors.shadowLight.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          children: [
            // Date block
            Container(
              width: 52,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isPast
                    ? AppColors.border.withOpacity(0.5)
                    : AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    meeting.date.split(' ')[0], // Day number
                    style: AppTextStyles.h2.copyWith(
                      color: isPast ? AppColors.textMuted : AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    meeting.date.split(' ')[1].replaceAll(',', ''),
                    style: AppTextStyles.small.copyWith(
                      color: isPast ? AppColors.textMuted : AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meeting.title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isPast ? AppColors.textMuted : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: isPast
                            ? AppColors.disabled
                            : AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          meeting.time,
                          style: AppTextStyles.small.copyWith(
                            fontSize: 11,
                            color: isPast ? AppColors.disabled : null,
                          ),
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 14,
                        color: isPast
                            ? AppColors.disabled
                            : AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        meeting.location,
                        style: AppTextStyles.small.copyWith(
                          fontSize: 11,
                          color: isPast ? AppColors.disabled : null,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.people_rounded,
                        size: 14,
                        color: isPast
                            ? AppColors.disabled
                            : AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${meeting.attendees}',
                        style: AppTextStyles.small.copyWith(
                          fontSize: 11,
                          color: isPast ? AppColors.disabled : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isPast ? AppColors.disabled : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _Meeting {
  final String title;
  final String date;
  final String time;
  final String location;
  final int attendees;
  final String agenda;
  final String status;
  const _Meeting({
    required this.title,
    required this.date,
    required this.time,
    required this.location,
    required this.attendees,
    required this.agenda,
    required this.status,
  });
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
