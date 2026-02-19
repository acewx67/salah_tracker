import 'package:hive_flutter/hive_flutter.dart';
import 'package:salah_tracker/models/prayer_log.dart';

/// Local storage service using Hive for offline-first data persistence.
class LocalStorageService {
  static const String _prayerLogsBox = 'prayer_logs';
  static const String _settingsBox = 'settings';

  late Box<Map> _logsBox;
  late Box _settingsBoxInstance;

  Future<void> init() async {
    await Hive.initFlutter();
    _logsBox = await Hive.openBox<Map>(_prayerLogsBox);
    _settingsBoxInstance = await Hive.openBox(_settingsBox);
  }

  // ─── Prayer Logs ──────────────────────────────────────────────────

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Future<void> saveLog(PrayerLog log) async {
    await _logsBox.put(_dateKey(log.date), log.toHiveMap());
  }

  PrayerLog? getLog(DateTime date) {
    final map = _logsBox.get(_dateKey(date));
    if (map == null) return null;
    return PrayerLog.fromHiveMap(map);
  }

  List<PrayerLog> getLogsRange(DateTime start, DateTime end) {
    final logs = <PrayerLog>[];
    DateTime current = start;
    while (!current.isAfter(end)) {
      final log = getLog(current);
      if (log != null) logs.add(log);
      current = current.add(const Duration(days: 1));
    }
    return logs;
  }

  List<PrayerLog> getUnsyncedLogs() {
    return _logsBox.values
        .map((map) => PrayerLog.fromHiveMap(map))
        .where((log) => !log.isSynced)
        .toList();
  }

  Future<void> markSynced(DateTime date) async {
    final map = _logsBox.get(_dateKey(date));
    if (map != null) {
      map['is_synced'] = true;
      await _logsBox.put(_dateKey(date), map);
    }
  }

  // ─── Settings ─────────────────────────────────────────────────────

  DateTime? get performanceStartDate {
    final str = _settingsBoxInstance.get('performance_start_date');
    if (str == null) return null;
    return DateTime.parse(str);
  }

  Future<void> setPerformanceStartDate(DateTime date) async {
    await _settingsBoxInstance.put(
      'performance_start_date',
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
    );
  }

  bool get notificationsEnabled =>
      _settingsBoxInstance.get('notifications_enabled', defaultValue: true);

  Future<void> setNotificationsEnabled(bool enabled) async {
    await _settingsBoxInstance.put('notifications_enabled', enabled);
  }

  String? get userId => _settingsBoxInstance.get('user_id');

  Future<void> setUserId(String id) async {
    await _settingsBoxInstance.put('user_id', id);
  }

  String? get userEmail => _settingsBoxInstance.get('user_email');

  Future<void> setUserEmail(String email) async {
    await _settingsBoxInstance.put('user_email', email);
  }

  String? get userName => _settingsBoxInstance.get('user_name');

  Future<void> setUserName(String name) async {
    await _settingsBoxInstance.put('user_name', name);
  }

  Future<void> clearAll() async {
    await _logsBox.clear();
    await _settingsBoxInstance.clear();
  }
}
