import 'package:intl/intl.dart';

class DateFormatter {
  static final DateFormat _dateFormat = DateFormat('MMM d, yyyy');
  static final DateFormat _timeFormat = DateFormat('h:mm a');
  static final DateFormat _fullFormat = DateFormat('MMM d, yyyy • h:mm a');

  static String formatDate(DateTime? date) {
    if (date == null) return 'No due date';
    return _dateFormat.format(date);
  }

  static String formatTime(DateTime? date) {
    if (date == null) return '';
    return _timeFormat.format(date);
  }

  static String formatDateTime(DateTime? date) {
    if (date == null) return 'No due date';
    return _fullFormat.format(date);
  }

  static String formatRelativeDate(DateTime? date) {
    if (date == null) return 'No due date';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final difference = target.difference(today).inDays;

    if (difference == 0) {
      return 'Today, ${_timeFormat.format(date)}';
    } else if (difference == 1) {
      return 'Tomorrow, ${_timeFormat.format(date)}';
    } else if (difference == -1) {
      return 'Yesterday, ${_timeFormat.format(date)}';
    } else if (difference < -1) {
      return '${-difference}d overdue';
    } else if (difference < 7) {
      return DateFormat('EEEE • h:mm a').format(date);
    } else {
      return _fullFormat.format(date);
    }
  }

  static bool isDueToday(DateTime? date) {
    if (date == null) return false;
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  static bool isOverdue(DateTime? date, {bool isCompleted = false}) {
    if (date == null || isCompleted) return false;
    return date.isBefore(DateTime.now());
  }
}
