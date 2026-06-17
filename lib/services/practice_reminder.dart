import 'package:home_widget/home_widget.dart';

/// Bridges the "last practiced" timestamp to the Android home-screen widget.
///
/// The widget turns into an animated red reminder once 6 hours have passed
/// since the last recorded practice. We store the timestamp as a string (epoch
/// millis) so the native side can parse it unambiguously.
class PracticeReminder {
  PracticeReminder._();

  static const String _key = 'last_practice';
  static const String _androidProvider = 'PracticeWidgetProvider';

  /// Record that the user is practising now and refresh the widget.
  static Future<void> markPracticed() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await HomeWidget.saveWidgetData<String>(_key, now.toString());
    await _update();
  }

  /// Re-render the widget (e.g. on app launch) without changing the timestamp.
  static Future<void> refresh() => _update();

  static Future<void> _update() async {
    try {
      await HomeWidget.updateWidget(androidName: _androidProvider);
    } catch (_) {
      // No widget added yet, or platform without widget support — ignore.
    }
  }
}
