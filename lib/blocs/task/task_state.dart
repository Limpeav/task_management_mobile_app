import 'package:flutter/foundation.dart';
import '../../core/constants/app_constants.dart';
import '../../models/task_model.dart';

@immutable
class TaskState {
  final List<TaskModel> tasks;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;
  final String searchQuery;
  final TaskStatusFilter statusFilter;
  final TaskCategory? selectedCategory;
  final TaskPriority? selectedPriority;

  const TaskState({
    this.tasks = const [],
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
    this.searchQuery = '',
    this.statusFilter = TaskStatusFilter.all,
    this.selectedCategory,
    this.selectedPriority,
  });

  // Filtered tasks based on active filters & search query
  List<TaskModel> get filteredTasks {
    return tasks.where((task) {
      // 1. Search Query Filter
      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        final matchTitle = task.title.toLowerCase().contains(q);
        final matchDesc = task.description.toLowerCase().contains(q);
        if (!matchTitle && !matchDesc) return false;
      }

      // 2. Status Filter
      switch (statusFilter) {
        case TaskStatusFilter.all:
          break;
        case TaskStatusFilter.pending:
          if (task.isCompleted) return false;
          break;
        case TaskStatusFilter.completed:
          if (!task.isCompleted) return false;
          break;
        case TaskStatusFilter.overdue:
          if (!task.isOverdue) return false;
          break;
      }

      // 3. Category Filter
      if (selectedCategory != null && task.category != selectedCategory) {
        return false;
      }

      // 4. Priority Filter
      if (selectedPriority != null && task.priority != selectedPriority) {
        return false;
      }

      return true;
    }).toList();
  }

  // Dashboard Metrics
  int get totalCount => tasks.length;
  int get completedCount => tasks.where((t) => t.isCompleted).length;
  int get pendingCount => tasks.where((t) => !t.isCompleted).length;
  int get overdueCount => tasks.where((t) => t.isOverdue).length;

  double get completionRate =>
      totalCount == 0 ? 0.0 : (completedCount / totalCount);

  int get completionPercentage => (completionRate * 100).round();

  List<TaskModel> get urgentTasks => tasks
      .where((t) =>
          !t.isCompleted &&
          (t.priority == TaskPriority.urgent || t.priority == TaskPriority.high))
      .toList();

  List<TaskModel> get upcomingTasks => tasks
      .where((t) => !t.isCompleted && t.dueDate != null && !t.isOverdue)
      .toList()
    ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));

  bool get hasActiveFilters =>
      searchQuery.isNotEmpty ||
      statusFilter != TaskStatusFilter.all ||
      selectedCategory != null ||
      selectedPriority != null;

  TaskState copyWith({
    List<TaskModel>? tasks,
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    String? searchQuery,
    TaskStatusFilter? statusFilter,
    TaskCategory? selectedCategory,
    bool clearCategory = false,
    TaskPriority? selectedPriority,
    bool clearPriority = false,
  }) {
    return TaskState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      successMessage: successMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
      selectedCategory:
          clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      selectedPriority:
          clearPriority ? null : (selectedPriority ?? this.selectedPriority),
    );
  }
}
