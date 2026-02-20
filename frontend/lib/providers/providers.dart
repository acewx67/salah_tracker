import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salah_tracker/models/prayer_log.dart';
import 'package:salah_tracker/services/local_storage_service.dart';
import 'package:salah_tracker/services/api_service.dart';
import 'package:salah_tracker/services/auth_service.dart';
import 'package:salah_tracker/models/user.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

// ─── Service Providers ──────────────────────────────────────────────

final localStorageProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageService();
});

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// ─── Authentication Provider ──────────────────────────────────────────

class AuthState {
  final AppUser? user;
  final String? token;
  final bool isLoading;

  AuthState({this.user, this.token, this.isLoading = false});

  AuthState copyWith({AppUser? user, String? token, bool? isLoading}) {
    return AuthState(
      user: user ?? this.user,
      token: token ?? this.token,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  final apiService = ref.watch(apiServiceProvider);
  return AuthNotifier(authService, apiService);
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final ApiService _apiService;

  AuthNotifier(this._authService, this._apiService)
    : super(AuthState(isLoading: true)) {
    _init();
  }

  void _init() {
    _authService.authStateChanges.listen((
      firebase_auth.User? firebaseUser,
    ) async {
      if (firebaseUser == null) {
        _apiService.setAuthToken('');
        state = AuthState(user: null, token: null, isLoading: false);
      } else {
        try {
          final token = await firebaseUser.getIdToken();
          if (token != null) {
            _apiService.setAuthToken(token);
          }
          final appUser = await _apiService.getMe();
          state = AuthState(user: appUser, token: token, isLoading: false);
        } catch (e) {
          print('Error loading user profile: $e');
          state = AuthState(user: null, token: null, isLoading: false);
        }
      }
    });
  }

  Future<void> signIn() async {
    state = state.copyWith(isLoading: true);
    try {
      final token = await _authService.signInWithGoogle();
      if (token == null) {
        state = state.copyWith(isLoading: false);
        return;
      }
      // The listener in _init will handle the state update upon successful Firebase sign-in.
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    // The listener in _init will handle the state update.
  }
}

// ─── Prayer Log Provider ────────────────────────────────────────────

final selectedDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

final prayerLogProvider = StateNotifierProvider<PrayerLogNotifier, PrayerLog>((
  ref,
) {
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
