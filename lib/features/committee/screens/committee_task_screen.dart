import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class CommitteeTaskScreen extends StatefulWidget {
  const CommitteeTaskScreen({super.key});

  @override
  State<CommitteeTaskScreen> createState() => _CommitteeTaskScreenState();
}

class _CommitteeTaskScreenState extends State<CommitteeTaskScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final List<_Task> _tasks = [
    _Task(
      id: 'TSK-001',
      title: 'Repair school playground fence',
      description: 'The wooden fence around the school playground is broken in multiple places and needs repair.',
      assignee: 'Nihal Perera',
      assigneeAvatar: 'NP',
      dueDate: 'Mar 10, 2026',
      priority: 'High',
      status: 'In Progress',
      category: 'Infrastructure',
    ),
    _Task(
      id: 'TSK-002',
      title: 'Organize community clean-up drive',
      description: 'Plan and execute a village-wide clean-up drive for the coming weekend.',
      assignee: 'Priya Silva',
      assigneeAvatar: 'PS',
      dueDate: 'Mar 15, 2026',
      priority: 'Medium',
      status: 'Open',
      category: 'Community',
    ),
    _Task(
      id: 'TSK-003',
      title: 'Install new notice board at junction',
      description: 'Purchase and install a new weather-proof notice board at the main junction.',
      assignee: 'Kasun Fernando',
      assigneeAvatar: 'KF',
      dueDate: 'Mar 08, 2026',
      priority: 'Low',
      status: 'Open',
      category: 'Infrastructure',
    ),
    _Task(
      id: 'TSK-004',
      title: 'Follow up on water supply complaint',
      description: 'Contact Water Board regarding the disruption reported by eastern sector residents.',
      assignee: 'Amaya Dias',
      assigneeAvatar: 'AD',
      dueDate: 'Mar 05, 2026',
      priority: 'High',
      status: 'In Progress',
      category: 'Utilities',
    ),
    _Task(
      id: 'TSK-005',
      title: 'Distribute relief supplies',
      description: 'Distribute donated relief supplies to flood-affected families.',
      assignee: 'Ranjith Kumara',
      assigneeAvatar: 'RK',
      dueDate: 'Feb 28, 2026',
      priority: 'High',
      status: 'Completed',
      category: 'Welfare',
    ),
    _Task(
      id: 'TSK-006',
      title: 'Update village resource inventory',
      description: 'Conduct inventory of shared village resources and update the records.',
      assignee: 'Lakmini Jayawardena',
      assigneeAvatar: 'LJ',
      dueDate: 'Feb 25, 2026',
      priority: 'Medium',
      status: 'Completed',
      category: 'Administration',
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

  List<_Task> _filteredTasks(int tab) {
    switch (tab) {
      case 0: // My Tasks (simulate all open/in progress)
        return _tasks.where((t) => t.status != 'Completed').toList();
      case 1: // All Tasks
        return _tasks;
      case 2: // Completed
        return _tasks.where((t) => t.status == 'Completed').toList();
      default:
        return _tasks;
    }
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'High':
        return AppColors.error;
      case 'Medium':
        return AppColors.warning;
      case 'Low':
        return AppColors.success;
      default:
        return AppColors.textMuted;
    }
  }

  void _showCreateTaskDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
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
                  Text('Create New Task', style: AppTextStyles.h2),
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
                    _formLabel('Task Title'),
                    const SizedBox(height: 8),
                    _formTextField('Enter task title'),
                    const SizedBox(height: 20),
                    _formLabel('Description'),
                    const SizedBox(height: 8),
                    _formTextField('Describe the task...', maxLines: 3),
                    const SizedBox(height: 20),
                    _formLabel('Assign To'),
                    const SizedBox(height: 8),
                    _formDropdown(
                        ['Nihal Perera', 'Priya Silva', 'Kasun Fernando', 'Amaya Dias']),
                    const SizedBox(height: 20),
                    _formLabel('Priority'),
                    const SizedBox(height: 8),
                    _formDropdown(['High', 'Medium', 'Low']),
                    const SizedBox(height: 20),
                    _formLabel('Due Date'),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceGrey,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded,
                                size: 18, color: AppColors.textMuted),
                            const SizedBox(width: 12),
                            Text('Select due date',
                                style: AppTextStyles.body
                                    .copyWith(color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Task created successfully!')),
                          );
                        },
                        child: const Text('Create Task'),
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

  Widget _formLabel(String text) =>
      Text(text, style: AppTextStyles.label);

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

  Widget _formDropdown(List<String> items) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceGrey,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: Text('Select',
              style: AppTextStyles.body.copyWith(color: AppColors.textMuted)),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (_) {},
        ),
      ),
    );
  }

  void _showTaskDetail(_Task task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.6,
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
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _priorityColor(task.priority)
                                .withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            task.priority,
                            style: AppTextStyles.small.copyWith(
                              color: _priorityColor(task.priority),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: task.status == 'Completed'
                                ? AppColors.successLight
                                : AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            task.status,
                            style: AppTextStyles.small.copyWith(
                              color: task.status == 'Completed'
                                  ? AppColors.success
                                  : AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(task.id,
                            style: AppTextStyles.small
                                .copyWith(color: AppColors.textMuted)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(task.title, style: AppTextStyles.h2),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceGrey,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        task.description,
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _taskDetailRow(
                        Icons.person_rounded, 'Assignee', task.assignee),
                    _taskDetailRow(
                        Icons.calendar_today_rounded, 'Due Date', task.dueDate),
                    _taskDetailRow(
                        Icons.category_rounded, 'Category', task.category),
                    const SizedBox(height: 24),
                    if (task.status != 'Completed')
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(ctx),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.check_circle_rounded),
                          label: const Text('Mark as Complete'),
                        ),
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

  Widget _taskDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textMuted),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(label,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textMuted)),
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
      appBar: AppBar(
        title: const Text('Task Manager'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'My Tasks'),
            Tab(text: 'All Tasks'),
            Tab(text: 'Completed'),
          ],
          onTap: (_) => setState(() {}),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateTaskDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Task'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(3, (tabIndex) {
          final items = _filteredTasks(tabIndex);
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.task_alt_rounded,
                      size: 64, color: AppColors.success.withOpacity(0.4)),
                  const SizedBox(height: 16),
                  Text('No tasks found',
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.textMuted)),
                ],
              ),
            );
          }
          return AnimationLimiter(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final task = items[index];
                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 375),
                  child: SlideAnimation(
                    verticalOffset: 40,
                    child: FadeInAnimation(
                      child: _buildTaskCard(task),
                    ),
                  ),
                );
              },
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTaskCard(_Task task) {
    final priorityColor = _priorityColor(task.priority);
    return GestureDetector(
      onTap: () => _showTaskDetail(task),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
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
            Row(
              children: [
                // Avatar
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      task.assigneeAvatar,
                      style: AppTextStyles.captionMedium
                          .copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: AppTextStyles.bodyMedium
                            .copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        task.assignee,
                        style: AppTextStyles.small,
                      ),
                    ],
                  ),
                ),
                if (task.status == 'Completed')
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.success, size: 22),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    task.priority,
                    style: AppTextStyles.small.copyWith(
                      color: priorityColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceGrey,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    task.category,
                    style: AppTextStyles.small.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(Icons.calendar_today_rounded,
                    size: 13, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(task.dueDate,
                    style: AppTextStyles.small.copyWith(fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Task {
  final String id;
  final String title;
  final String description;
  final String assignee;
  final String assigneeAvatar;
  final String dueDate;
  final String priority;
  final String status;
  final String category;
  const _Task({
    required this.id,
    required this.title,
    required this.description,
    required this.assignee,
    required this.assigneeAvatar,
    required this.dueDate,
    required this.priority,
    required this.status,
    required this.category,
  });
}
