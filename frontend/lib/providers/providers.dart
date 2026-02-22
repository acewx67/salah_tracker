import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salah_tracker/models/prayer_log.dart';
import 'package:salah_tracker/services/local_storage_service.dart';
import 'package:salah_tracker/services/api_service.dart';
import 'package:salah_tracker/services/auth_service.dart';
import 'package:salah_tracker/services/home_screen_widget.dart';
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
  final DateTime? lastSyncAt;

  AuthState({this.user, this.token, this.isLoading = false, this.lastSyncAt});

  AuthState copyWith({
    AppUser? user,
    String? token,
    bool? isLoading,
    DateTime? lastSyncAt,
  }) {
    return AuthState(
      user: user ?? this.user,
      token: token ?? this.token,
      isLoading: isLoading ?? this.isLoading,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  final apiService = ref.watch(apiServiceProvider);
  final localStorage = ref.watch(localStorageProvider);
  return AuthNotifier(authService, apiService, localStorage);
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final ApiService _apiService;
  final LocalStorageService _localStorage;

  AuthNotifier(this._authService, this._apiService, this._localStorage)
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

          // If a different account signed in, clear local data first
          final storedUserId = _localStorage.userId;
          if (storedUserId != null && storedUserId != firebaseUser.uid) {
            print('Different user detected — clearing local data');
            await _localStorage.clearAll();
          }
          await _localStorage.setUserId(firebaseUser.uid);

          final appUser = await _apiService.getMe();
          state = AuthState(user: appUser, token: token, isLoading: false);

          // Auto-pull remote data on login and update state to trigger UI rebuild
          _pullRemoteLogs()
              .then((_) {
                state = state.copyWith(lastSyncAt: DateTime.now());
                // Push latest heatmap data to home screen widget
                HomeScreenWidgetService.updateWidget(_localStorage);
              })
              .catchError((Object e) {
                print('Auto-pull error: $e');
                // Still push local data to widget even if pull fails
                HomeScreenWidgetService.updateWidget(_localStorage);
              });
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
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  Future<void> _pullRemoteLogs() async {
    final now = DateTime.now();
    final oneYearAgo = DateTime(now.year - 1, now.month, now.day);
    print('[SYNC] Pulling remote logs from $oneYearAgo to $now');
    try {
      final remoteLogs = await _apiService.getLogsRange(oneYearAgo, now);
      print('[SYNC] Got ${remoteLogs.length} remote logs');
      for (final log in remoteLogs) {
        final existing = _localStorage.getLog(log.date);
        if (existing == null || existing.isSynced) {
          await _localStorage.saveLog(log);
          print('[SYNC] Saved log for ${log.date}');
        }
      }
      print('[SYNC] Pull complete');
    } catch (e, st) {
      print('[SYNC] Pull failed: $e\n$st');
    }
  }

  Future<void> syncLogs(WidgetRef ref) async {
    try {
      // Step 1: Push unsynced local logs to the backend
      final unsynced = _localStorage.getUnsyncedLogs();
      if (unsynced.isNotEmpty) {
        final synced = await _apiService.batchSync(unsynced);
        for (final log in synced) {
          await _localStorage.markSynced(log.date);
        }
      }

      // Step 2: Pull all logs from the backend and merge into local storage
      await _pullRemoteLogs();

      // Trigger UI rebuild in all watching providers
      state = state.copyWith(lastSyncAt: DateTime.now());

      // Update home screen widget with latest heatmap data
      HomeScreenWidgetService.updateWidget(_localStorage);
    } catch (e) {
      print('Sync error: $e');
      rethrow;
    }
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
  final apiService = ref.watch(apiServiceProvider);
  final selectedDate = ref.watch(selectedDateProvider);
  // Rebuild when user changes (immediate) or when sync completes (data update)
  ref.watch(authProvider.select((s) => s.user?.id));
  ref.watch(authProvider.select((s) => s.lastSyncAt));
  return PrayerLogNotifier(localStorage, apiService, selectedDate);
});

class PrayerLogNotifier extends StateNotifier<PrayerLog> {
  final LocalStorageService _localStorage;
  final ApiService _apiService;
  Timer? _debounceTimer;

  PrayerLogNotifier(this._localStorage, this._apiService, DateTime date)
    : super(_localStorage.getLog(date) ?? PrayerLog(date: date));

  void _saveAndSync() {
    state.computeScore();
    state.isSynced = false;
    _localStorage.saveLog(state);
    state = state.copyWith();

    // Update home screen widget with latest heatmap data
    HomeScreenWidgetService.updateWidget(_localStorage);

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 1000), () async {
      try {
        final unsyncedInfo = _localStorage.getUnsyncedLogs();
        if (unsyncedInfo.isEmpty) return;

        // Sync any unsynced local logs including the current one
        final synced = await _apiService.batchSync(unsyncedInfo);
        for (final log in synced) {
          await _localStorage.markSynced(log.date);
        }

        // Only trigger UI update if the current date was just synced
        if (mounted && synced.any((l) => l.date == state.date)) {
          final updatedLog = _localStorage.getLog(state.date);
          if (updatedLog != null) state = updatedLog;
        }
      } catch (e) {
        print("Debounce sync failed: $e");
      }
    });
  }

  void toggleFardh(String prayer) {
    state.setFardh(prayer, !state.getFardh(prayer));
    _saveAndSync();
  }

  void setSunnah(String prayer, int value) {
    state.setSunnah(prayer, value);
    _saveAndSync();
  }

  void setNafl(String prayer, int value) {
    state.setNafl(prayer, value);
    _saveAndSync();
  }

  void setWitr(String prayer, int value) {
    state.setWitr(prayer, value);
    _saveAndSync();
  }

  void refresh() {
    final log = _localStorage.getLog(state.date) ?? PrayerLog(date: state.date);
    state = log;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
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
  // Rebuild when user changes (immediate) or when sync completes (data update)
  ref.watch(authProvider.select((s) => s.user?.id));
  ref.watch(authProvider.select((s) => s.lastSyncAt));
  // Rebuild when the currently selected log changes locally
  ref.watch(prayerLogProvider);

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

  // Rebuild when user changes, sync completes, or current log changes locally
  ref.watch(authProvider.select((s) => s.user?.id));
  ref.watch(authProvider.select((s) => s.lastSyncAt));
  ref.watch(prayerLogProvider);

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
