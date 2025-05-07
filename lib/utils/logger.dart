/// A simple logger utility to replace print statements.
class AppLogger {
  /// Log a message with optional level
  static void log(String message, {String level = 'info'}) {
    final timestamp = DateTime.now().toIso8601String();
    final formattedMessage = '[$timestamp][$level] $message';

    // In production, this could be replaced with a proper logging package
    // like 'logger' or integrate with a crash reporting service
    print(formattedMessage);
  }
}
