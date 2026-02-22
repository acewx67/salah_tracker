import 'dart:convert';
import 'package:home_widget/home_widget.dart';
import 'package:salah_tracker/services/local_storage_service.dart';
import 'package:salah_tracker/models/prayer_log.dart';

/// Service to bridge prayer heatmap data to the native Android home screen widget.
///
/// Serializes the last ~16 weeks (112 days) of prayer log data into a JSON
/// string and saves it to SharedPreferences via [HomeWidget]. Then triggers
/// the native Android widget to re-render with the updated data.
class HomeScreenWidgetService {
  static const String _widgetProviderName = 'SalahWidgetProvider';
  static const String _heatmapDataKey = 'heatmap_data';
  static const int _daysToShow = 112; // 16 weeks

  /// Computes a color level (0–5) for a given prayer log.
  ///
  ///   0 = no data (empty/gray)
  ///   1 = 0 fardh completed (dark red)
  ///   2 = 1-2 fardh (red)
  ///   3 = 3-4 fardh (yellow)
  ///   4 = all 5 fardh (dark green)
  ///   5 = all 5 fardh + all sunnah (light green)
  static int _colorLevel(PrayerLog? log) {
    if (log == null) return 0;
    final fardh = log.fardhCompleted;
    if (fardh == 5 && log.allSunnahComplete) return 5;
    if (fardh == 5) return 4;
    if (fardh >= 3) return 3;
    if (fardh >= 1) return 2;
    return 1;
  }

  /// Serialize the heatmap data, save to SharedPreferences, and trigger widget update.
  static Future<void> updateWidget(LocalStorageService localStorage) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Build a map of date -> color level for the last _daysToShow days
    final Map<String, int> heatmap = {};
    for (int i = _daysToShow - 1; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final log = localStorage.getLog(date);
      final key =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      heatmap[key] = _colorLevel(log);
    }

    // Save heatmap JSON via home_widget
    final jsonStr = jsonEncode(heatmap);
    await HomeWidget.saveWidgetData<String>(_heatmapDataKey, jsonStr);

    // Trigger native widget refresh
    await HomeWidget.updateWidget(
      androidName: _widgetProviderName,
      qualifiedAndroidName:
          'com.salahtracker.salah_tracker.$_widgetProviderName',
    );
  }
}
