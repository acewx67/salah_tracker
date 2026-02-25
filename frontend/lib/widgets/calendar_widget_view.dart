import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:salah_tracker/config/theme.dart';
import 'package:salah_tracker/models/prayer_log.dart';

class CalendarWidgetView extends StatelessWidget {
  final Map<DateTime, PrayerLog> logs;
  final DateTime month;

  const CalendarWidgetView({
    super.key,
    required this.logs,
    required this.month,
  });

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final firstWeekday = firstDayOfMonth.weekday; // 1 = Monday, 7 = Sunday

    // Adjust to 0-indexed where 0 = Monday
    final prefixDays = firstWeekday - 1;

    // Create a 6x7 grid of children
    final List<Widget> rows = [];

    // Day labels row
    rows.add(
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
              .map(
                (d) => SizedBox(
                  width: 30,
                  child: Center(
                    child: Text(
                      d,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );

    rows.add(const Divider(color: Colors.white12, height: 8));

    // Calendar grid rows
    for (int week = 0; week < 6; week++) {
      final List<Widget> weekDays = [];
      for (int day = 0; day < 7; day++) {
        final index = week * 7 + day;
        final dayNumber = index - prefixDays + 1;

        if (dayNumber < 1 || dayNumber > daysInMonth) {
          weekDays.add(const Expanded(child: SizedBox.shrink()));
        } else {
          final date = DateTime(month.year, month.month, dayNumber);
          final log = logs[date];
          final color = _getDayColor(log);
          final isToday = _isToday(date);

          weekDays.add(
            Expanded(
              child: Center(
                child: Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isToday ? Colors.white : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$dayNumber',
                      style: TextStyle(
                        color: color == AppTheme.calendarEmpty
                            ? Colors.black87
                            : Colors.white,
                        fontSize: 10,
                        fontWeight: isToday
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }
      }
      rows.add(Row(children: weekDays));
    }

    return Container(
      width: 320, // Slightly smaller width for better widget fitting
      height: 280, // Taller to accommodate 6 rows comfortably
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('MMMM yyyy').format(month),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Removed redundant Salah Tracker title
            ],
          ),
          const SizedBox(height: 4),
          ...rows,
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  Color _getDayColor(PrayerLog? log) {
    if (log == null) return AppTheme.calendarEmpty;
    final fardh = log.fardhCompleted;
    if (fardh == 5 && log.allSunnahComplete) return AppTheme.calendarLightGreen;
    if (fardh == 5) return AppTheme.calendarDarkGreen;
    if (fardh >= 3) return AppTheme.calendarYellow;
    if (fardh >= 1) return AppTheme.calendarRed;
    return AppTheme.calendarDarkRed;
  }
}
