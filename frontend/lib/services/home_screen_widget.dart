import 'package:home_widget/home_widget.dart';
import 'package:salah_tracker/services/local_storage_service.dart';
import 'package:salah_tracker/models/prayer_log.dart';
import 'package:salah_tracker/widgets/calendar_widget_view.dart';
import 'package:flutter/material.dart';

/// Service to bridge prayer progress to the native Android home screen widget.
///
/// Renders a monthly calendar view using [CalendarWidgetView] and saves it
/// as an image via [HomeWidget.renderFlutterWidget]. Then triggers the
/// native Android widget to display the generated image.
class HomeScreenWidgetService {
  static const String _widgetProviderName = 'SalahWidgetProvider';
  static const String _calendarImageKey = 'calendar_image';

  /// Render the calendar, save the image, and trigger widget update.
  static Future<void> updateWidget(LocalStorageService localStorage) async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);

    // Fetch logs for the current month
    final logsList = localStorage.getLogsRange(monthStart, monthEnd);
    final Map<DateTime, PrayerLog> logsMap = {
      for (var log in logsList)
        DateTime(log.date.year, log.date.month, log.date.day): log,
    };

    // Render the Flutter widget to an image
    await HomeWidget.renderFlutterWidget(
      CalendarWidgetView(logs: logsMap, month: DateTime(now.year, now.month)),
      key: _calendarImageKey,
      logicalSize: const Size(320, 280), // Matches new CalendarWidgetView size
      pixelRatio: 3.0, // Higher density for extra crispness
    );

    // Trigger native widget refresh
    await HomeWidget.updateWidget(
      qualifiedAndroidName:
          'com.salahtracker.salah_tracker.$_widgetProviderName',
    );
  }
}
