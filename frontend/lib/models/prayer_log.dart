import 'package:salah_tracker/config/constants.dart';

/// Represents a single day's prayer log.
class PrayerLog {
  final String? id;
  final String? userId;
  final DateTime date;

  // Fajr
  bool fajrFardh;
  int fajrSunnah;
  int fajrNafl;

  // Dhuhr
  bool dhuhrFardh;
  int dhuhrSunnah;
  int dhuhrNafl;

  // Asr
  bool asrFardh;
  int asrSunnah;
  int asrNafl;

  // Maghrib
  bool maghribFardh;
  int maghribSunnah;
  int maghribNafl;

  // Isha
  bool ishaFardh;
  int ishaSunnah;
  int ishaNafl;
  int ishaWitr;

  double dailyScore;
  bool isSynced;

  PrayerLog({
    this.id,
    this.userId,
    required this.date,
    this.fajrFardh = false,
    this.fajrSunnah = 0,
    this.fajrNafl = 0,
    this.dhuhrFardh = false,
    this.dhuhrSunnah = 0,
    this.dhuhrNafl = 0,
    this.asrFardh = false,
    this.asrSunnah = 0,
    this.asrNafl = 0,
    this.maghribFardh = false,
    this.maghribSunnah = 0,
    this.maghribNafl = 0,
    this.ishaFardh = false,
    this.ishaSunnah = 0,
    this.ishaNafl = 0,
    this.ishaWitr = 0,
    this.dailyScore = 0.0,
    this.isSynced = false,
  });

  // ─── Getters for individual prayer data ──────────────────────────

  bool getFardh(String prayer) {
    switch (prayer) {
      case 'fajr':
        return fajrFardh;
      case 'dhuhr':
        return dhuhrFardh;
      case 'asr':
        return asrFardh;
      case 'maghrib':
        return maghribFardh;
      case 'isha':
        return ishaFardh;
      default:
        return false;
    }
  }

  void setFardh(String prayer, bool value) {
    switch (prayer) {
      case 'fajr':
        fajrFardh = value;
        if (!value) {
          fajrSunnah = 0;
          fajrNafl = 0;
        }
        break;
      case 'dhuhr':
        dhuhrFardh = value;
        if (!value) {
          dhuhrSunnah = 0;
          dhuhrNafl = 0;
        }
        break;
      case 'asr':
        asrFardh = value;
        if (!value) {
          asrSunnah = 0;
          asrNafl = 0;
        }
        break;
      case 'maghrib':
        maghribFardh = value;
        if (!value) {
          maghribSunnah = 0;
          maghribNafl = 0;
        }
        break;
      case 'isha':
        ishaFardh = value;
        if (!value) {
          ishaSunnah = 0;
          ishaNafl = 0;
          ishaWitr = 0;
        }
        break;
    }
  }

  int getSunnah(String prayer) {
    switch (prayer) {
      case 'fajr':
        return fajrSunnah;
      case 'dhuhr':
        return dhuhrSunnah;
      case 'asr':
        return asrSunnah;
      case 'maghrib':
        return maghribSunnah;
      case 'isha':
        return ishaSunnah;
      default:
        return 0;
    }
  }

  void setSunnah(String prayer, int value) {
    switch (prayer) {
      case 'fajr':
        fajrSunnah = value;
        break;
      case 'dhuhr':
        dhuhrSunnah = value;
        break;
      case 'asr':
        asrSunnah = value;
        break;
      case 'maghrib':
        maghribSunnah = value;
        break;
      case 'isha':
        ishaSunnah = value;
        break;
    }
  }

  int getNafl(String prayer) {
    switch (prayer) {
      case 'fajr':
        return fajrNafl;
      case 'dhuhr':
        return dhuhrNafl;
      case 'asr':
        return asrNafl;
      case 'maghrib':
        return maghribNafl;
      case 'isha':
        return ishaNafl;
      default:
        return 0;
    }
  }

  void setNafl(String prayer, int value) {
    switch (prayer) {
      case 'fajr':
        fajrNafl = value;
        break;
      case 'dhuhr':
        dhuhrNafl = value;
        break;
      case 'asr':
        asrNafl = value;
        break;
      case 'maghrib':
        maghribNafl = value;
        break;
      case 'isha':
        ishaNafl = value;
        break;
    }
  }

  int getWitr(String prayer) {
    if (prayer == 'isha') return ishaWitr;
    return 0;
  }

  void setWitr(String prayer, int value) {
    if (prayer == 'isha') ishaWitr = value;
  }

  // ─── Scoring ─────────────────────────────────────────────────────

  int get fardhCompleted {
    int count = 0;
    if (fajrFardh) count++;
    if (dhuhrFardh) count++;
    if (asrFardh) count++;
    if (maghribFardh) count++;
    if (ishaFardh) count++;
    return count;
  }

  int get totalSunnah =>
      fajrSunnah +
      dhuhrSunnah +
      asrSunnah +
      maghribSunnah +
      ishaSunnah +
      ishaWitr; // witr scored same as sunnah

  int get totalNafl => fajrNafl + dhuhrNafl + asrNafl + maghribNafl + ishaNafl;

  bool get allSunnahComplete =>
      totalSunnah >= PrayerConstants.totalExpectedSunnah;

  void computeScore() {
    final fardhScore = (fardhCompleted / 5) * PrayerConstants.fardhWeight;
    final sunnahTotal = totalSunnah + totalNafl;
    final expectedSunnah = PrayerConstants.totalExpectedSunnah;
    double sunnahScore = 0.0;
    if (expectedSunnah > 0) {
      sunnahScore =
          (sunnahTotal / expectedSunnah) * PrayerConstants.sunnahWeight;
      if (sunnahScore > PrayerConstants.sunnahWeight) {
        sunnahScore = PrayerConstants.sunnahWeight;
      }
    }
    dailyScore = double.parse((fardhScore + sunnahScore).toStringAsFixed(2));
    if (dailyScore > 100) dailyScore = 100;
  }

  // ─── JSON serialization ──────────────────────────────────────────

  Map<String, dynamic> toJson() {
    return {
      'date':
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      'fajr_fardh': fajrFardh,
      'fajr_sunnah': fajrSunnah,
      'fajr_nafl': fajrNafl,
      'dhuhr_fardh': dhuhrFardh,
      'dhuhr_sunnah': dhuhrSunnah,
      'dhuhr_nafl': dhuhrNafl,
      'asr_fardh': asrFardh,
      'asr_sunnah': asrSunnah,
      'asr_nafl': asrNafl,
      'maghrib_fardh': maghribFardh,
      'maghrib_sunnah': maghribSunnah,
      'maghrib_nafl': maghribNafl,
      'isha_fardh': ishaFardh,
      'isha_sunnah': ishaSunnah,
      'isha_nafl': ishaNafl,
      'isha_witr': ishaWitr,
    };
  }

  factory PrayerLog.fromJson(Map<String, dynamic> json) {
    return PrayerLog(
      id: json['id'],
      userId: json['user_id'],
      date: DateTime.parse(json['date']),
      fajrFardh: json['fajr_fardh'] ?? false,
      fajrSunnah: json['fajr_sunnah'] ?? 0,
      fajrNafl: json['fajr_nafl'] ?? 0,
      dhuhrFardh: json['dhuhr_fardh'] ?? false,
      dhuhrSunnah: json['dhuhr_sunnah'] ?? 0,
      dhuhrNafl: json['dhuhr_nafl'] ?? 0,
      asrFardh: json['asr_fardh'] ?? false,
      asrSunnah: json['asr_sunnah'] ?? 0,
      asrNafl: json['asr_nafl'] ?? 0,
      maghribFardh: json['maghrib_fardh'] ?? false,
      maghribSunnah: json['maghrib_sunnah'] ?? 0,
      maghribNafl: json['maghrib_nafl'] ?? 0,
      ishaFardh: json['isha_fardh'] ?? false,
      ishaSunnah: json['isha_sunnah'] ?? 0,
      ishaNafl: json['isha_nafl'] ?? 0,
      ishaWitr: json['isha_witr'] ?? 0,
      dailyScore: (json['daily_score'] ?? 0.0).toDouble(),
      isSynced: true,
    );
  }

  /// Convert to Hive-compatible map
  Map<String, dynamic> toHiveMap() {
    final m = toJson();
    m['id'] = id;
    m['user_id'] = userId;
    m['daily_score'] = dailyScore;
    m['is_synced'] = isSynced;
    return m;
  }

  factory PrayerLog.fromHiveMap(Map<dynamic, dynamic> map) {
    return PrayerLog(
      id: map['id'],
      userId: map['user_id'],
      date: DateTime.parse(map['date']),
      fajrFardh: map['fajr_fardh'] ?? false,
      fajrSunnah: map['fajr_sunnah'] ?? 0,
      fajrNafl: map['fajr_nafl'] ?? 0,
      dhuhrFardh: map['dhuhr_fardh'] ?? false,
      dhuhrSunnah: map['dhuhr_sunnah'] ?? 0,
      dhuhrNafl: map['dhuhr_nafl'] ?? 0,
      asrFardh: map['asr_fardh'] ?? false,
      asrSunnah: map['asr_sunnah'] ?? 0,
      asrNafl: map['asr_nafl'] ?? 0,
      maghribFardh: map['maghrib_fardh'] ?? false,
      maghribSunnah: map['maghrib_sunnah'] ?? 0,
      maghribNafl: map['maghrib_nafl'] ?? 0,
      ishaFardh: map['isha_fardh'] ?? false,
      ishaSunnah: map['isha_sunnah'] ?? 0,
      ishaNafl: map['isha_nafl'] ?? 0,
      ishaWitr: map['isha_witr'] ?? 0,
      dailyScore: (map['daily_score'] ?? 0.0).toDouble(),
      isSynced: map['is_synced'] ?? false,
    );
  }

  PrayerLog copyWith() {
    return PrayerLog(
      id: id,
      userId: userId,
      date: date,
      fajrFardh: fajrFardh,
      fajrSunnah: fajrSunnah,
      fajrNafl: fajrNafl,
      dhuhrFardh: dhuhrFardh,
      dhuhrSunnah: dhuhrSunnah,
      dhuhrNafl: dhuhrNafl,
      asrFardh: asrFardh,
      asrSunnah: asrSunnah,
      asrNafl: asrNafl,
      maghribFardh: maghribFardh,
      maghribSunnah: maghribSunnah,
      maghribNafl: maghribNafl,
      ishaFardh: ishaFardh,
      ishaSunnah: ishaSunnah,
      ishaNafl: ishaNafl,
      ishaWitr: ishaWitr,
      dailyScore: dailyScore,
      isSynced: isSynced,
    );
  }
}
