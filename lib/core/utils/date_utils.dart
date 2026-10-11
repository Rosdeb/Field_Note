class AppDateUtils {
  static String formatIsoDate(DateTime dateTime) {
    return dateTime.toIso8601String();
  }

  static String formatReadableDate(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
  }
}
