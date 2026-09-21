import 'package:flutter/material.dart';

enum TaskPriority {
  low('Low', Color(0xFF10B981), Color(0xFFE6F7F0), 1),
  medium('Medium', Color(0xFFF59E0B), Color(0xFFFEF3C7), 2),
  high('High', Color(0xFFF97316), Color(0xFFFFEDD5), 3),
  urgent('Urgent', Color(0xFFEF4444), Color(0xFFFEE2E2), 4);

  final String label;
  final Color color;
  final Color backgroundColor;
  final int level;

  const TaskPriority(this.label, this.color, this.backgroundColor, this.level);

  static TaskPriority fromString(String? value) {
    if (value == null) return TaskPriority.medium;
    return TaskPriority.values.firstWhere(
      (p) => p.name.toLowerCase() == value.toLowerCase(),
      orElse: () => TaskPriority.medium,
    );
  }
}

enum TaskCategory {
  work('Work', Icons.work_outline_rounded, Color(0xFF6366F1)),
  personal('Personal', Icons.person_outline_rounded, Color(0xFF10B981)),
  study('Study', Icons.school_outlined, Color(0xFF06B6D4)),
  health('Health', Icons.favorite_border_rounded, Color(0xFFF43F5E)),
  finance('Finance', Icons.account_balance_wallet_outlined, Color(0xFF8B5CF6)),
  other('Other', Icons.bookmark_border_rounded, Color(0xFF64748B));

  final String label;
  final IconData icon;
  final Color color;

  const TaskCategory(this.label, this.icon, this.color);

  static TaskCategory fromString(String? value) {
    if (value == null) return TaskCategory.work;
    return TaskCategory.values.firstWhere(
      (c) => c.name.toLowerCase() == value.toLowerCase(),
      orElse: () => TaskCategory.work,
    );
  }
}

enum TaskStatusFilter {
  all('All'),
  pending('Pending'),
  completed('Completed'),
  overdue('Overdue');

  final String label;
  const TaskStatusFilter(this.label);
}
