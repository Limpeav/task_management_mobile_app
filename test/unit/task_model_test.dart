import 'package:flutter_test/flutter_test.dart';
import 'package:task_management_app/core/constants/app_constants.dart';
import 'package:task_management_app/models/task_model.dart';
import 'package:task_management_app/models/user_model.dart';

void main() {
  group('TaskModel Tests', () {
    test('TaskModel serializes and deserializes correctly', () {
      final now = DateTime.now();
      final task = TaskModel(
        id: 'test_id',
        userId: 'user_1',
        title: 'Complete documentation',
        description: 'Detailing system architecture',
        priority: TaskPriority.urgent,
        category: TaskCategory.work,
        dueDate: now.add(const Duration(days: 2)),
        isCompleted: false,
        createdAt: now,
      );

      final map = task.toMap();
      final parsed = TaskModel.fromMap(map);

      expect(parsed.id, equals(task.id));
      expect(parsed.userId, equals(task.userId));
      expect(parsed.title, equals(task.title));
      expect(parsed.description, equals(task.description));
      expect(parsed.priority, equals(TaskPriority.urgent));
      expect(parsed.category, equals(TaskCategory.work));
      expect(parsed.isCompleted, isFalse);
    });

    test('isOverdue returns true for past due incomplete tasks', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 1));
      final overdueTask = TaskModel(
        id: '1',
        userId: 'u1',
        title: 'Past task',
        dueDate: pastDate,
        isCompleted: false,
        createdAt: pastDate,
      );

      expect(overdueTask.isOverdue, isTrue);

      final completedPastTask = overdueTask.copyWith(isCompleted: true);
      expect(completedPastTask.isOverdue, isFalse);
    });
  });

  group('UserModel Tests', () {
    test('AppUser serializes and deserializes properly', () {
      final user = AppUser(
        id: 'u123',
        email: 'test@example.com',
        displayName: 'Test User',
        bio: 'Tester',
        createdAt: DateTime.now(),
      );

      final map = user.toMap();
      final parsed = AppUser.fromMap(map);

      expect(parsed.id, equals('u123'));
      expect(parsed.email, equals('test@example.com'));
      expect(parsed.displayName, equals('Test User'));
      expect(parsed.bio, equals('Tester'));
    });
  });
}
