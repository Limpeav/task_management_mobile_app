import 'package:flutter/foundation.dart';
import '../../core/constants/app_constants.dart';
import '../../models/task_model.dart';

@immutable
abstract class TaskEvent {
  const TaskEvent();
}

class LoadTasksRequested extends TaskEvent {
  final String userId;
  const LoadTasksRequested(this.userId);
}

class CreateTaskRequested extends TaskEvent {
  final String userId;
  final String title;
  final String description;
  final TaskPriority priority;
  final TaskCategory category;
  final DateTime? dueDate;

  const CreateTaskRequested({
    required this.userId,
    required this.title,
    required this.description,
    required this.priority,
    required this.category,
    this.dueDate,
  });
}

class UpdateTaskRequested extends TaskEvent {
  final TaskModel task;
  const UpdateTaskRequested(this.task);
}

class ToggleTaskCompletionRequested extends TaskEvent {
  final TaskModel task;
  const ToggleTaskCompletionRequested(this.task);
}

class DeleteTaskRequested extends TaskEvent {
  final String userId;
  final String taskId;
  const DeleteTaskRequested({required this.userId, required this.taskId});
}

class SearchQueryChanged extends TaskEvent {
  final String query;
  const SearchQueryChanged(this.query);
}

class StatusFilterChanged extends TaskEvent {
  final TaskStatusFilter filter;
  const StatusFilterChanged(this.filter);
}

class CategoryFilterChanged extends TaskEvent {
  final TaskCategory? category;
  const CategoryFilterChanged(this.category);
}

class PriorityFilterChanged extends TaskEvent {
  final TaskPriority? priority;
  const PriorityFilterChanged(this.priority);
}

class ClearFiltersRequested extends TaskEvent {
  const ClearFiltersRequested();
}
