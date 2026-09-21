import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/task_model.dart';
import '../core/constants/app_constants.dart';

class StorageService {
  static const String _keyCurrentUser = 'app_current_user';
  static const String _keyUsers = 'app_registered_users';
  static const String _keyTasksPrefix = 'app_tasks_';
  static const String _keyDarkMode = 'app_is_dark_mode';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    final service = StorageService(prefs);
    await service._seedInitialDataIfNeeded();
    return service;
  }

  // --- Theme ---
  bool isDarkMode() {
    return _prefs.getBool(_keyDarkMode) ?? false;
  }

  Future<void> setDarkMode(bool isDark) async {
    await _prefs.setBool(_keyDarkMode, isDark);
  }

  // --- User Session ---
  AppUser? getCurrentUser() {
    final raw = _prefs.getString(_keyCurrentUser);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return AppUser.fromMap(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> setCurrentUser(AppUser? user) async {
    if (user == null) {
      await _prefs.remove(_keyCurrentUser);
    } else {
      await _prefs.setString(_keyCurrentUser, jsonEncode(user.toMap()));
    }
  }

  // --- Local User Database (Offline/Fallback) ---
  List<Map<String, dynamic>> getAllUsers() {
    final raw = _prefs.getString(_keyUsers);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveUser(AppUser user, {String? password}) async {
    final users = getAllUsers();
    final index = users.indexWhere((u) => u['id'] == user.id || u['email'] == user.email);
    final userMap = user.toMap();
    if (password != null) {
      userMap['password'] = password;
    }

    if (index >= 0) {
      if (password == null && users[index].containsKey('password')) {
        userMap['password'] = users[index]['password'];
      }
      users[index] = userMap;
    } else {
      users.add(userMap);
    }
    await _prefs.setString(_keyUsers, jsonEncode(users));
  }

  // --- Tasks Storage ---
  List<TaskModel> getTasks(String userId) {
    final raw = _prefs.getString('$_keyTasksPrefix$userId');
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((item) => TaskModel.fromMap(Map<String, dynamic>.from(item as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveTasks(String userId, List<TaskModel> tasks) async {
    final list = tasks.map((t) => t.toMap()).toList();
    await _prefs.setString('$_keyTasksPrefix$userId', jsonEncode(list));
  }

  Future<void> _seedInitialDataIfNeeded() async {
    final users = getAllUsers();
    if (users.isEmpty) {
      // Seed Demo User
      final demoUser = AppUser(
        id: 'demo_user_001',
        email: 'alex@example.com',
        displayName: 'Alex Morgan',
        bio: 'Productivity enthusiast & software engineer.',
        photoUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      );
      await saveUser(demoUser, password: 'password123');

      // Seed Initial Demo Tasks
      final now = DateTime.now();
      final demoTasks = [
        TaskModel(
          id: 'task_1',
          userId: 'demo_user_001',
          title: 'Complete Mobile App Wireframes',
          description: 'Design UX mockups in Figma for client review including dark mode variants.',
          priority: TaskPriority.urgent,
          category: TaskCategory.work,
          dueDate: now.add(const Duration(hours: 4)),
          isCompleted: false,
          createdAt: now.subtract(const Duration(days: 2)),
        ),
        TaskModel(
          id: 'task_2',
          userId: 'demo_user_001',
          title: 'Weekly Team Sync & Sprint Planning',
          description: 'Discuss sprint backlog, upcoming feature milestones, and bug triage.',
          priority: TaskPriority.high,
          category: TaskCategory.work,
          dueDate: now.add(const Duration(days: 1)),
          isCompleted: true,
          createdAt: now.subtract(const Duration(days: 3)),
        ),
        TaskModel(
          id: 'task_3',
          userId: 'demo_user_001',
          title: 'Read 2 Chapters of Clean Architecture',
          description: 'Study dependency inversion principles and entity boundary separation.',
          priority: TaskPriority.medium,
          category: TaskCategory.study,
          dueDate: now.add(const Duration(days: 2)),
          isCompleted: false,
          createdAt: now.subtract(const Duration(days: 1)),
        ),
        TaskModel(
          id: 'task_4',
          userId: 'demo_user_001',
          title: '45-Min Morning Cardio & Workout',
          description: 'Jogging 5km followed by core strength exercises.',
          priority: TaskPriority.low,
          category: TaskCategory.health,
          dueDate: now.subtract(const Duration(days: 1)), // Overdue demo
          isCompleted: false,
          createdAt: now.subtract(const Duration(days: 2)),
        ),
        TaskModel(
          id: 'task_5',
          userId: 'demo_user_001',
          title: 'Review Monthly Budget & Savings',
          description: 'Analyze subscription costs and allocate quarterly emergency fund.',
          priority: TaskPriority.medium,
          category: TaskCategory.finance,
          dueDate: now.add(const Duration(days: 4)),
          isCompleted: true,
          createdAt: now.subtract(const Duration(days: 4)),
        ),
      ];
      await saveTasks('demo_user_001', demoTasks);
    }
  }
}
