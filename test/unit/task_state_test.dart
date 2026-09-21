import 'package:flutter_test/flutter_test.dart';
import 'package:task_management_app/blocs/task/task_state.dart';
import 'package:task_management_app/core/constants/app_constants.dart';
import 'package:task_management_app/models/task_model.dart';

void main() {
  group('TaskState Calculation and Filter Tests', () {
    final now = DateTime.now();
    final tasks = [
      TaskModel(
        id: '1',
        userId: 'u1',
        title: 'Work Project Alpha',
        description: 'Prepare presentation',
        priority: TaskPriority.urgent,
        category: TaskCategory.work,
        dueDate: now.add(const Duration(days: 1)),
        isCompleted: false,
        createdAt: now,
      ),
      TaskModel(
        id: '2',
        userId: 'u1',
        title: 'Study Flutter Architecture',
        description: 'Read Bloc guide',
        priority: TaskPriority.high,
        category: TaskCategory.study,
        dueDate: now.add(const Duration(days: 2)),
        isCompleted: true,
        createdAt: now,
      ),
      TaskModel(
        id: '3',
        userId: 'u1',
        title: 'Buy Groceries',
        description: 'Milk, eggs, fruit',
        priority: TaskPriority.low,
        category: TaskCategory.personal,
        dueDate: now.subtract(const Duration(days: 2)), // Overdue
        isCompleted: false,
        createdAt: now,
      ),
    ];

    test('Computes metrics accurately', () {
      final state = TaskState(tasks: tasks);

      expect(state.totalCount, equals(3));
      expect(state.completedCount, equals(1));
      expect(state.pendingCount, equals(2));
      expect(state.overdueCount, equals(1));
      expect(state.completionPercentage, equals(33));
    });

    test('Filters by search query', () {
      final state = TaskState(tasks: tasks, searchQuery: 'Groceries');
      expect(state.filteredTasks.length, equals(1));
      expect(state.filteredTasks.first.title, equals('Buy Groceries'));
    });

    test('Filters by status filter', () {
      final pendingState = TaskState(
        tasks: tasks,
        statusFilter: TaskStatusFilter.pending,
      );
      expect(pendingState.filteredTasks.length, equals(2));

      final completedState = TaskState(
        tasks: tasks,
        statusFilter: TaskStatusFilter.completed,
      );
      expect(completedState.filteredTasks.length, equals(1));

      final overdueState = TaskState(
        tasks: tasks,
        statusFilter: TaskStatusFilter.overdue,
      );
      expect(overdueState.filteredTasks.length, equals(1));
      expect(overdueState.filteredTasks.first.id, equals('3'));
    });

    test('Filters by Category and Priority', () {
      final workState = TaskState(
        tasks: tasks,
        selectedCategory: TaskCategory.work,
      );
      expect(workState.filteredTasks.length, equals(1));
      expect(workState.filteredTasks.first.category, equals(TaskCategory.work));

      final urgentState = TaskState(
        tasks: tasks,
        selectedPriority: TaskPriority.urgent,
      );
      expect(urgentState.filteredTasks.length, equals(1));
      expect(urgentState.filteredTasks.first.priority, equals(TaskPriority.urgent));
    });
  });
}
