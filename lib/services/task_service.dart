import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/task_model.dart';
import 'storage_service.dart';

class TaskService {
  final StorageService _storage;
  final Uuid _uuid = const Uuid();

  TaskService(this._storage);

  bool get _isFirebaseConfigured => Firebase.apps.isNotEmpty;
  FirebaseFirestore? get _firestore =>
      _isFirebaseConfigured ? FirebaseFirestore.instance : null;

  CollectionReference<Map<String, dynamic>>? _tasksRef(String userId) {
    if (_firestore == null) return null;
    return _firestore!.collection('users').doc(userId).collection('tasks');
  }

  Future<List<TaskModel>> getTasks(String userId) async {
    // 1. If Firestore is active, try to fetch
    if (_firestore != null) {
      try {
        final ref = _tasksRef(userId);
        if (ref != null) {
          final snapshot = await ref.orderBy('createdAt', descending: true).get();
          if (snapshot.docs.isNotEmpty) {
            final tasks = snapshot.docs
                .map((doc) => TaskModel.fromMap(doc.data()))
                .toList();
            await _storage.saveTasks(userId, tasks);
            return tasks;
          }
        }
      } catch (e) {
        debugPrint('Firestore fetch error: $e, falling back to local');
      }
    }

    // 2. Local tasks from storage
    return _storage.getTasks(userId);
  }

  Future<TaskModel> createTask({
    required String userId,
    required String title,
    String description = '',
    required dynamic priority,
    required dynamic category,
    DateTime? dueDate,
  }) async {
    final now = DateTime.now();
    final taskId = _uuid.v4();
    final newTask = TaskModel(
      id: taskId,
      userId: userId,
      title: title.trim(),
      description: description.trim(),
      priority: priority,
      category: category,
      dueDate: dueDate,
      isCompleted: false,
      createdAt: now,
      updatedAt: now,
    );

    // Save locally
    final currentTasks = _storage.getTasks(userId);
    currentTasks.insert(0, newTask);
    await _storage.saveTasks(userId, currentTasks);

    // Sync to Firestore if available
    if (_firestore != null) {
      try {
        await _tasksRef(userId)?.doc(taskId).set(newTask.toMap());
      } catch (e) {
        debugPrint('Firestore createTask error: $e');
      }
    }

    return newTask;
  }

  Future<TaskModel> updateTask(TaskModel task) async {
    final updated = task.copyWith(updatedAt: DateTime.now());

    // Update locally
    final currentTasks = _storage.getTasks(task.userId);
    final index = currentTasks.indexWhere((t) => t.id == task.id);
    if (index >= 0) {
      currentTasks[index] = updated;
      await _storage.saveTasks(task.userId, currentTasks);
    }

    // Sync to Firestore
    if (_firestore != null) {
      try {
        await _tasksRef(task.userId)?.doc(task.id).update(updated.toMap());
      } catch (e) {
        debugPrint('Firestore updateTask error: $e');
      }
    }

    return updated;
  }

  Future<TaskModel> toggleTaskCompletion(TaskModel task) async {
    return updateTask(task.copyWith(isCompleted: !task.isCompleted));
  }

  Future<void> deleteTask(String userId, String taskId) async {
    // Delete locally
    final currentTasks = _storage.getTasks(userId);
    currentTasks.removeWhere((t) => t.id == taskId);
    await _storage.saveTasks(userId, currentTasks);

    // Delete in Firestore
    if (_firestore != null) {
      try {
        await _tasksRef(userId)?.doc(taskId).delete();
      } catch (e) {
        debugPrint('Firestore deleteTask error: $e');
      }
    }
  }
}
