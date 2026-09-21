import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/task/task_bloc.dart';
import '../../blocs/task/task_event.dart';
import '../../blocs/task/task_state.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/task_card.dart';
import '../tasks/task_detail_screen.dart';
import '../tasks/task_form_sheet.dart';

class DashboardScreen extends StatelessWidget {
  final ValueChanged<int>? onNavigateToTab;

  const DashboardScreen({super.key, this.onNavigateToTab});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final todayStr = DateFormat('EEEE, MMMM d').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_task_rounded),
            tooltip: 'Create Task',
            onPressed: () => TaskFormSheet.show(context),
          ),
        ],
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          final user = authState is Authenticated ? authState.user : null;
          final displayName = user?.displayName.split(' ').first ?? 'Friend';

          return BlocBuilder<TaskBloc, TaskState>(
            builder: (context, taskState) {
              final total = taskState.totalCount;
              final completed = taskState.completedCount;
              final pending = taskState.pendingCount;
              final overdue = taskState.overdueCount;
              final completionRate = taskState.completionRate;
              final urgentTasks = taskState.urgentTasks;

              return RefreshIndicator(
                onRefresh: () async {
                  if (user != null) {
                    context.read<TaskBloc>().add(LoadTasksRequested(user.id));
                  }
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Greeting Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              todayStr,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Hello, $displayName 👋',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              overdue > 0
                                  ? 'You have $overdue overdue tasks requiring immediate attention.'
                                  : pending > 0
                                      ? 'You have $pending pending tasks to accomplish today.'
                                      : 'All caught up! Excellent work keeping things organized.',
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.4,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Section Title
                      Text(
                        'Overview',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 2x2 Grid of KPI Cards
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.4,
                        children: [
                          StatCard(
                            title: 'Total Tasks',
                            value: '$total',
                            icon: Icons.format_list_bulleted_rounded,
                            color: const Color(0xFF6366F1),
                            onTap: () {
                              context.read<TaskBloc>().add(
                                    const StatusFilterChanged(TaskStatusFilter.all),
                                  );
                              onNavigateToTab?.call(1);
                            },
                          ),
                          StatCard(
                            title: 'Completed',
                            value: '$completed',
                            icon: Icons.check_circle_rounded,
                            color: const Color(0xFF10B981),
                            subtitle: total > 0 ? '${(completionRate * 100).round()}%' : null,
                            onTap: () {
                              context.read<TaskBloc>().add(
                                    const StatusFilterChanged(TaskStatusFilter.completed),
                                  );
                              onNavigateToTab?.call(1);
                            },
                          ),
                          StatCard(
                            title: 'Pending',
                            value: '$pending',
                            icon: Icons.pending_actions_rounded,
                            color: const Color(0xFFF59E0B),
                            onTap: () {
                              context.read<TaskBloc>().add(
                                    const StatusFilterChanged(TaskStatusFilter.pending),
                                  );
                              onNavigateToTab?.call(1);
                            },
                          ),
                          StatCard(
                            title: 'Overdue',
                            value: '$overdue',
                            icon: Icons.warning_amber_rounded,
                            color: const Color(0xFFEF4444),
                            subtitle: overdue > 0 ? 'Urgent' : null,
                            onTap: () {
                              context.read<TaskBloc>().add(
                                    const StatusFilterChanged(TaskStatusFilter.overdue),
                                  );
                              onNavigateToTab?.call(1);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Progress Card
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 64,
                                  height: 64,
                                  child: CircularProgressIndicator(
                                    value: total == 0 ? 0.0 : completionRate,
                                    strokeWidth: 6,
                                    backgroundColor: isDark
                                        ? const Color(0xFF334155)
                                        : const Color(0xFFE2E8F0),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      completionRate >= 0.8
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFF6366F1),
                                    ),
                                  ),
                                ),
                                Text(
                                  total == 0
                                      ? '0%'
                                      : '${(completionRate * 100).round()}%',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Productivity Progress',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    total == 0
                                        ? 'No tasks created yet.'
                                        : '$completed of $total tasks completed.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.65),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: total == 0 ? 0.0 : completionRate,
                                      minHeight: 6,
                                      backgroundColor: isDark
                                          ? const Color(0xFF334155)
                                          : const Color(0xFFE2E8F0),
                                      valueColor: const AlwaysStoppedAnimation(
                                        Color(0xFF6366F1),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Urgent Tasks Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'High Priority & Urgent',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextButton(
                            onPressed: () => onNavigateToTab?.call(1),
                            child: const Text('View All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      if (urgentTasks.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E293B).withValues(alpha: 0.6)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.celebration_rounded,
                                  color: Color(0xFF10B981),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'No urgent pending tasks',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'You are on top of your highest priority items!',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ...urgentTasks.take(4).map(
                              (task) => TaskCard(
                                task: task,
                                onToggleCompletion: (_) {
                                  context
                                      .read<TaskBloc>()
                                      .add(ToggleTaskCompletionRequested(task));
                                },
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          TaskDetailScreen(task: task),
                                    ),
                                  );
                                },
                                onEdit: () {
                                  TaskFormSheet.show(context, existingTask: task);
                                },
                              ),
                            ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
