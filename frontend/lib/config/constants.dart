/// App-wide constants for prayer names, expected rakats, etc.

class PrayerConstants {
  static const List<String> prayerNames = [
    'fajr',
    'dhuhr',
    'asr',
    'maghrib',
    'isha',
  ];

  static const List<String> prayerDisplayNames = [
    'Fajr',
    'Dhuhr',
    'Asr',
    'Maghrib',
    'Isha',
  ];

  /// Expected Fardh rakats per prayer
  static const Map<String, int> fardhRakats = {
    'fajr': 2,
    'dhuhr': 4,
    'asr': 4,
    'maghrib': 3,
    'isha': 4,
  };

  /// Expected Sunnah rakats per prayer (typical recommendation)
  static const Map<String, int> expectedSunnah = {
    'fajr': 2,
    'dhuhr': 6, // 4 before + 2 after
    'asr': 0,
    'maghrib': 2,
    'isha': 4, // 2 + 2
  };

  static int get totalExpectedSunnah =>
      expectedSunnah.values.fold(0, (sum, v) => sum + v);

  /// Rakat options for scroll selector
  static const List<int> rakatOptions = [0, 2, 4, 6, 8, 10, 12];

  /// Scoring weights
  static const double fardhWeight = 85.0;
  static const double sunnahWeight = 15.0;
}

class ApiConstants {
  static const String baseUrl = 'http://10.0.2.2:8000'; // Android emulator → localhost
  static const String iosBaseUrl = 'http://localhost:8000';
}
