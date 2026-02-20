/// App-wide constants for prayer names, expected rakats, etc.
library;

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
    'isha': 4, // 2 after + 2 optional before
  };

  static int get totalExpectedSunnah =>
      expectedSunnah.values.fold(0, (sum, v) => sum + v);

  // ─── Per-prayer Sunnah rakat options ────────────────────────────────
  //
  // Fajr    : 2 rakats sunnah muakkadah (before fardh only)
  // Dhuhr   : 4 before + 2 after = up to 6 sunnah
  // Asr     : 4 ghair muakkadah (non-obligatory) before fardh
  // Maghrib : 2 sunnah muakkadah after fardh
  // Isha    : 2 sunnah muakkadah after fardh (+ 2 optional ghair muakkadah)
  static const Map<String, List<int>> sunnahOptions = {
    'fajr': [0, 2], // 2 muakkadah before fardh
    'dhuhr': [0, 2, 4, 6], // 4 before + 2 after (total up to 6)
    'asr': [0, 4], // 4 ghair muakkadah before fardh
    'maghrib': [0, 2], // 2 muakkadah after fardh
    'isha': [0, 2, 4, 6], // 4 before + 2 after (total up to 6)
  };

  // ─── Per-prayer Nafl rakat options ──────────────────────────────────
  //
  // Fajr    : No nafl recommended after/before (salah al-duha is separate)
  // Dhuhr   : Up to 4 nafl after sunnah
  // Asr     : No nafl after Asr (forbidden time)
  // Maghrib : Up to 6 nafl (awwabin)
  // Isha    : 2 nafl after sunnah (before witr); witr tracked separately
  static const Map<String, List<int>> naflOptions = {
    'fajr': [0], // no nafl for Fajr
    'dhuhr': [0, 2], // most do 2 nafl after
    'asr': [0], // forbidden time after Asr
    'maghrib': [0, 2], // most do 2 nafl (awwabin)
    'isha': [0, 2], // 2 nafl after witr
  };

  /// Whether to show the Nafl selector for a given prayer.
  /// Hidden when only [0] is available (no practical nafl for that prayer).
  static bool showNafl(String prayer) {
    final opts = naflOptions[prayer] ?? [0];
    return opts.length > 1;
  }

  /// Witr options — only [0] or [3] (Isha only, wajib in Hanafi school).
  static const List<int> witrOptions = [0, 3];

  /// Scoring weights
  static const double fardhWeight = 85.0;
  static const double sunnahWeight = 15.0;
}

class ApiConstants {
  static const String baseUrl =
      'http://192.168.29.13:8000'; // Physical device IP
  static const String iosBaseUrl = 'http://localhost:8000';
}
