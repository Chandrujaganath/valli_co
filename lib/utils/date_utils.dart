// lib/utils/date_utils.dart
import 'package:intl/intl.dart';

class DateUtils {
  static String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  static bool isNonSkippableDate(DateTime selectedDate, DateTime lastEntryDate) {
    // Ensure the selected date is the day after the last entry date
    return selectedDate.isAtSameMomentAs(lastEntryDate.add(Duration(days: 1)));
  }

  static bool isToday(DateTime date) {
    final today = DateTime.now();
    return date.year == today.year && date.month == today.month && date.day == today.day;
  }

  static DateTime parseDate(String date) {
    return DateFormat('yyyy-MM-dd').parse(date);
  }
}
