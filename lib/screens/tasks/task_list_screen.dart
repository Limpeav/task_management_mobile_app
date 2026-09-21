import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/task/task_bloc.dart';
import '../../blocs/task/task_event.dart';
import '../../blocs/task/task_state.dart';
import '../../core/constants/app_constants.dart';
import '../../models/task_model.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/task_card.dart';
import 'task_detail_screen.dart';
import 'task_form_sheet.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _confirmDeleteTask(BuildContext context, TaskModel task) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Task?'),
        content: Text('Delete "${task.title}" permanently?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            onPressed: () {
              final authState = context.read<AuthBloc>().state;
              if (authState is Authenticated) {
                context.read<TaskBloc>().add(
                      DeleteTaskRequested(
                        userId: authState.user.id,
                        taskId: task.id,
                      ),
                    );
              }
              Navigator.pop(dialogContext);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_task_rounded),
            tooltip: 'New Task',
            onPressed: () => TaskFormSheet.show(context),
          ),
        ],
      ),
      body: BlocConsumer<TaskBloc, TaskState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: const Color(0xFFEF4444),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          final filteredTasks = state.filteredTasks;

          return Column(
            children: [
              // Search Bar & Filter Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    context.read<TaskBloc>().add(SearchQueryChanged(val));
                  },
                  decoration: InputDecoration(
                    hintText: 'Search tasks by title or keyword...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              context.read<TaskBloc>().add(const SearchQueryChanged(''));
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),

              // Status Filter Segmented Control
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: TaskStatusFilter.values.map((filter) {
                    final isSelected = state.statusFilter == filter;
                    int count = 0;
                    switch (filter) {
                      case TaskStatusFilter.all:
                        count = state.totalCount;
                        break;
                      case TaskStatusFilter.pending:
                        count = state.pendingCount;
                        break;
                      case TaskStatusFilter.completed:
                        count = state.completedCount;
                        break;
                      case TaskStatusFilter.overdue:
                        count = state.overdueCount;
                        break;
                    }

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(filter.label),
                            const SizedBox(width: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.3)
                                    : (isDark
                                        ? Colors.white.withValues(alpha: 0.1)
                                        : Colors.black.withValues(alpha: 0.06)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$count',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? Colors.white
                                      : theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                        selected: isSelected,
                        selectedColor: filter == TaskStatusFilter.overdue
                            ? const Color(0xFFEF4444)
                            : theme.colorScheme.primary,
                        backgroundColor: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF1F5F9),
                        labelStyle: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : theme.colorScheme.onSurface,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide.none,
                        ),
                        onSelected: (_) {
                          context
                              .read<TaskBloc>()
                              .add(StatusFilterChanged(filter));
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Category & Priority Filter Bar
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    // Category Filter Dropdown/Chips
                    ...TaskCategory.values.map((cat) {
                      final isSelected = state.selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          avatar: Icon(
                            cat.icon,
                            size: 14,
                            color: isSelected ? Colors.white : cat.color,
                          ),
                          label: Text(cat.label),
                          selected: isSelected,
                          selectedColor: cat.color,
                          backgroundColor: isDark
                              ? const Color(0xFF1E293B)
                              : Colors.white,
                          labelStyle: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : theme.colorScheme.onSurface,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: isSelected
                                  ? cat.color
                                  : (isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFE2E8F0)),
                            ),
                          ),
                          onSelected: (_) {
                            context
                                .read<TaskBloc>()
                                .add(CategoryFilterChanged(cat));
                          },
                        ),
                      );
                    }),

                    // Priority Filter Chips
                    ...TaskPriority.values.map((priority) {
                      final isSelected = state.selectedPriority == priority;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          avatar: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white : priority.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          label: Text(priority.label),
                          selected: isSelected,
                          selectedColor: priority.color,
                          backgroundColor: isDark
                              ? const Color(0xFF1E293B)
                              : Colors.white,
                          labelStyle: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : theme.colorScheme.onSurface,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: isSelected
                                  ? priority.color
                                  : (isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFE2E8F0)),
                            ),
                          ),
                          onSelected: (_) {
                            context
                                .read<TaskBloc>()
                                .add(PriorityFilterChanged(priority));
                          },
                        ),
                      );
                    }),

                    // Reset Filters Button
                    if (state.hasActiveFilters)
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: ActionChip(
                          avatar: const Icon(Icons.refresh_rounded, size: 14),
                          label: const Text('Reset'),
                          onPressed: () {
                            _searchController.clear();
                            context
                                .read<TaskBloc>()
                                .add(const ClearFiltersRequested());
                          },
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Task List Content
              Expanded(
                child: state.isLoading && state.tasks.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : filteredTasks.isEmpty
                        ? EmptyState(
                            icon: state.hasActiveFilters
                                ? Icons.filter_alt_off_rounded
                                : Icons.task_alt_rounded,
                            title: state.hasActiveFilters
                                ? 'No matching tasks'
                                : 'No tasks yet',
                            message: state.hasActiveFilters
                                ? 'Try adjusting or clearing your active search or filters.'
                                : 'Stay productive by adding your first task now!',
                            actionLabel:
                                state.hasActiveFilters ? 'Clear Filters' : 'Create Task',
                            onAction: () {
                              if (state.hasActiveFilters) {
                                _searchController.clear();
                                context
                                    .read<TaskBloc>()
                                    .add(const ClearFiltersRequested());
                              } else {
                                TaskFormSheet.show(context);
                              }
                            },
                          )
                        : RefreshIndicator(
                            onRefresh: () async {
                              final authState = context.read<AuthBloc>().state;
                              if (authState is Authenticated) {
                                context.read<TaskBloc>().add(
                                      LoadTasksRequested(authState.user.id),
                                    );
                              }
                            },
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                              itemCount: filteredTasks.length,
                              itemBuilder: (context, index) {
                                final task = filteredTasks[index];
                                return TaskCard(
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
                                    TaskFormSheet.show(context,
                                        existingTask: task);
                                  },
                                  onDelete: () =>
                                      _confirmDeleteTask(context, task),
                                );
                              },
                            ),
                          ),
              ),
            ],
          );
        },
      ),
    );
  }
}
