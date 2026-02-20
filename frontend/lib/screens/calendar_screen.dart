import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:salah_tracker/config/theme.dart';
import 'package:salah_tracker/models/prayer_log.dart';
import 'package:salah_tracker/providers/providers.dart';

/// Calendar view — monthly grid with color-coded prayer completion.
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final logs = ref.watch(calendarLogsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: Column(
        children: [
          // ─── Calendar ────────────────────────────────────────
          TableCalendar(
            firstDay: DateTime(2020, 1, 1),
            lastDay: DateTime.now(),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
              ref.read(calendarMonthProvider.notifier).state = DateTime(
                focusedDay.year,
                focusedDay.month,
                1,
              );
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.primary, width: 2),
              ),
              todayTextStyle: const TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
              ),
              selectedDecoration: const BoxDecoration(
                color: AppTheme.primary,
                shape: BoxShape.circle,
              ),
              outsideDaysVisible: false,
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) =>
                  _buildCalendarDay(day, logs),
              selectedBuilder: (context, day, focusedDay) =>
                  _buildCalendarDay(day, logs, isSelected: true),
              todayBuilder: (context, day, focusedDay) =>
                  _buildCalendarDay(day, logs, isToday: true),
            ),
          ),

          const SizedBox(height: 16),

          // ─── Legend ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _legendItem(AppTheme.calendarLightGreen, 'All + Sunnah'),
                _legendItem(AppTheme.calendarDarkGreen, 'All Fardh'),
                _legendItem(AppTheme.calendarYellow, '3-4 Fardh'),
                _legendItem(AppTheme.calendarRed, '1-2 Fardh'),
                _legendItem(AppTheme.calendarDarkRed, '0 Fardh'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ─── Selected day details ────────────────────────────
          if (_selectedDay != null) _buildDayDetail(logs),
        ],
      ),
    );
  }

  Widget _buildDayDetail(Map<DateTime, PrayerLog> logs) {
    final key = DateTime(
      _selectedDay!.year,
      _selectedDay!.month,
      _selectedDay!.day,
    );
    final log = logs[key];

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('EEEE, d MMMM').format(_selectedDay!),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            if (log == null)
              const Expanded(
                child: Center(
                  child: Text(
                    'No prayers logged',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _prayerRow(
                        'Fajr',
                        log.fajrFardh,
                        log.fajrSunnah,
                        log.fajrNafl,
                      ),
                      _prayerRow(
                        'Dhuhr',
                        log.dhuhrFardh,
                        log.dhuhrSunnah,
                        log.dhuhrNafl,
                      ),
                      _prayerRow(
                        'Asr',
                        log.asrFardh,
                        log.asrSunnah,
                        log.asrNafl,
                      ),
                      _prayerRow(
                        'Maghrib',
                        log.maghribFardh,
                        log.maghribSunnah,
                        log.maghribNafl,
                      ),
                      _prayerRow(
                        'Isha',
                        log.ishaFardh,
                        log.ishaSunnah,
                        log.ishaNafl,
                        witr: log.ishaWitr,
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Daily Score',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '${log.dailyScore.toStringAsFixed(1)}/100',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _prayerRow(
    String name,
    bool fardh,
    int sunnah,
    int nafl, {
    int? witr,
  }) {
    final stats = witr != null
        ? 'S:$sunnah N:$nafl W:$witr'
        : 'S:$sunnah N:$nafl';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            fardh ? Icons.check_circle : Icons.cancel,
            color: fardh ? AppTheme.primaryLight : Colors.grey.shade400,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(name)),
          Text(
            stats,
            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildCalendarDay(
    DateTime day,
    Map<DateTime, PrayerLog> logs, {
    bool isSelected = false,
    bool isToday = false,
  }) {
    final key = DateTime(day.year, day.month, day.day);
    final log = logs[key];
    final color = _getDayColor(log);

    BoxBorder? border;
    if (isSelected) {
      border = Border.all(color: Colors.black87, width: 2);
    } else if (isToday) {
      border = Border.all(color: AppTheme.primary, width: 2);
    }

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: border,
      ),
      child: Center(
        child: Text(
          '${day.day}',
          style: TextStyle(
            color: color == AppTheme.calendarEmpty && !isSelected
                ? AppTheme.textPrimary
                : Colors.white,
            fontWeight: isSelected || isToday
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
    );
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
