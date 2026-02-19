import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salah_tracker/models/prayer_log.dart';
import 'package:salah_tracker/services/local_storage_service.dart';
import 'package:salah_tracker/services/api_service.dart';

// ─── Service Providers ──────────────────────────────────────────────

final localStorageProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageService();
});

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

// ─── Prayer Log Provider ────────────────────────────────────────────

final selectedDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

final prayerLogProvider =
    StateNotifierProvider<PrayerLogNotifier, PrayerLog>((ref) {
  final localStorage = ref.watch(localStorageProvider);
  final selectedDate = ref.watch(selectedDateProvider);
  return PrayerLogNotifier(localStorage, selectedDate);
});

class PrayerLogNotifier extends StateNotifier<PrayerLog> {
  final LocalStorageService _localStorage;

  PrayerLogNotifier(this._localStorage, DateTime date)
      : super(_localStorage.getLog(date) ?? PrayerLog(date: date));

  void toggleFardh(String prayer) {
    state.setFardh(prayer, !state.getFardh(prayer));
    state.computeScore();
    _localStorage.saveLog(state);
    state = state.copyWith();
  }

  void setSunnah(String prayer, int value) {
    state.setSunnah(prayer, value);
    state.computeScore();
    _localStorage.saveLog(state);
    state = state.copyWith();
  }

  void setNafl(String prayer, int value) {
    state.setNafl(prayer, value);
    state.computeScore();
    _localStorage.saveLog(state);
    state = state.copyWith();
  }

  void refresh() {
    final log = _localStorage.getLog(state.date) ?? PrayerLog(date: state.date);
    state = log;
  }
}

// ─── Calendar Provider ──────────────────────────────────────────────

final calendarMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, 1);
});

final calendarLogsProvider = Provider<Map<DateTime, PrayerLog>>((ref) {
  final localStorage = ref.watch(localStorageProvider);
  final month = ref.watch(calendarMonthProvider);
  final start = DateTime(month.year, month.month, 1);
  final end = DateTime(month.year, month.month + 1, 0);
  final logs = localStorage.getLogsRange(start, end);

  final map = <DateTime, PrayerLog>{};
  for (final log in logs) {
    final key = DateTime(log.date.year, log.date.month, log.date.day);
    map[key] = log;
  }
  return map;
});

// ─── Performance Provider ───────────────────────────────────────────

final performanceStartDateProvider = StateProvider<DateTime?>((ref) {
  final localStorage = ref.watch(localStorageProvider);
  return localStorage.performanceStartDate;
});

final performanceScoreProvider = Provider<double>((ref) {
  final localStorage = ref.watch(localStorageProvider);
  final startDate = ref.watch(performanceStartDateProvider);
  if (startDate == null) return 0.0;

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final logs = localStorage.getLogsRange(startDate, today);
  final totalDays = today.difference(startDate).inDays + 1;

  if (totalDays <= 0) return 0.0;

  final totalScore = logs.fold<double>(0.0, (sum, log) => sum + log.dailyScore);
  return double.parse((totalScore / totalDays).toStringAsFixed(1));
});

// ─── Bottom Nav Provider ────────────────────────────────────────────

final bottomNavIndexProvider = StateProvider<int>((ref) => 0);
