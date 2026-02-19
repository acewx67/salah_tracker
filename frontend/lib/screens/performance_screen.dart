import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:salah_tracker/config/theme.dart';
import 'package:salah_tracker/models/prayer_log.dart';
import 'package:salah_tracker/providers/providers.dart';
import 'package:salah_tracker/widgets/performance_gauge.dart';

/// Performance screen — radial gauge showing average score over selected range.
class PerformanceScreen extends ConsumerWidget {
  const PerformanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startDate = ref.watch(performanceStartDateProvider);
    final score = ref.watch(performanceScoreProvider);
    final localStorage = ref.read(localStorageProvider);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final totalDays = startDate != null ? today.difference(startDate).inDays + 1 : 0;

    // Get detailed stats
    final logs = startDate != null
        ? localStorage.getLogsRange(startDate, today)
        : <PrayerLog>[];
    final totalFardh = logs.fold<int>(0, (int sum, log) => sum + log.fardhCompleted);
    final totalPossibleFardh = totalDays * 5;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ─── Start date card ───────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: AppTheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tracking Since',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          Text(
                            startDate != null
                                ? DateFormat('d MMMM yyyy').format(startDate)
                                : 'Not set',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => _pickStartDate(context, ref),
                      child: Text(startDate != null ? 'Change' : 'Set Date'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ─── Gauge ─────────────────────────────────────────
            if (startDate != null) ...[
              PerformanceGauge(score: score),

              const SizedBox(height: 24),

              // ─── Stats cards ──────────────────────────────────
              Row(
                children: [
                  _statCard(
                    context,
                    icon: Icons.calendar_view_day,
                    label: 'Days Tracked',
                    value: '$totalDays',
                  ),
                  const SizedBox(width: 12),
                  _statCard(
                    context,
                    icon: Icons.check_circle_outline,
                    label: 'Fardh Completed',
                    value: '$totalFardh / $totalPossibleFardh',
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  _statCard(
                    context,
                    icon: Icons.trending_up,
                    label: 'Avg Score',
                    value: '${score.toStringAsFixed(1)} / 100',
                  ),
                  const SizedBox(width: 12),
                  _statCard(
                    context,
                    icon: Icons.today,
                    label: 'Days Logged',
                    value: '${logs.length} / $totalDays',
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 60),
              Icon(Icons.bar_chart, size: 80, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                'Set a start date to begin\ntracking your performance',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _pickStartDate(context, ref),
                icon: const Icon(Icons.date_range),
                label: const Text('Set Start Date'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statCard(BuildContext context,
      {required IconData icon, required String label, required String value}) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 22, color: AppTheme.primary),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickStartDate(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: ref.read(performanceStartDateProvider) ?? now,
      firstDate: DateTime(2020),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppTheme.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      ref.read(performanceStartDateProvider.notifier).state = picked;
      ref.read(localStorageProvider).setPerformanceStartDate(picked);
    }
  }
}
