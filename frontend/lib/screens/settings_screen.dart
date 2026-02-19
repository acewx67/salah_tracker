import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:salah_tracker/config/theme.dart';
import 'package:salah_tracker/providers/providers.dart';

/// Settings screen — performance start date, notifications, logout.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localStorage = ref.read(localStorageProvider);
    final startDate = ref.watch(performanceStartDateProvider);
    final notificationsEnabled = localStorage.notificationsEnabled;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ─── Account Section ─────────────────────────────────
          _sectionHeader('Account'),
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppTheme.primary,
                child: Icon(Icons.person, color: Colors.white),
              ),
              title: Text(localStorage.userName ?? 'Guest User'),
              subtitle: Text(localStorage.userEmail ?? 'Not signed in'),
            ),
          ),

          const SizedBox(height: 24),

          // ─── Performance Section ─────────────────────────────
          _sectionHeader('Performance'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_today, color: AppTheme.primary),
              title: const Text('Performance Start Date'),
              subtitle: Text(
                startDate != null
                    ? DateFormat('d MMMM yyyy').format(startDate)
                    : 'Not set',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _pickStartDate(context, ref),
            ),
          ),

          const SizedBox(height: 24),

          // ─── Notifications Section ───────────────────────────
          _sectionHeader('Notifications'),
          Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.notifications_outlined, color: AppTheme.primary),
              title: const Text('Daily Reminders'),
              subtitle: const Text('9 PM logging reminder & 5 AM missed prayer alert'),
              value: notificationsEnabled,
              activeColor: AppTheme.primary,
              onChanged: (value) {
                localStorage.setNotificationsEnabled(value);
                // Trigger rebuild
                ref.invalidate(localStorageProvider);
              },
            ),
          ),

          const SizedBox(height: 24),

          // ─── Sync Section ────────────────────────────────────
          _sectionHeader('Data'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.sync, color: AppTheme.primary),
                  title: const Text('Sync Status'),
                  subtitle: Text(
                    '${localStorage.getUnsyncedLogs().length} unsynced entries',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.sync),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Sync requires backend connection'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.delete_outline, color: Colors.red.shade400),
                  title: const Text('Clear Local Data'),
                  subtitle: const Text('Remove all locally stored prayer logs'),
                  onTap: () => _confirmClearData(context, ref),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ─── About ───────────────────────────────────────────
          _sectionHeader('About'),
          Card(
            child: const ListTile(
              leading: Icon(Icons.info_outline, color: AppTheme.primary),
              title: Text('Salah Tracker'),
              subtitle: Text('Version 1.0.0'),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppTheme.textSecondary,
          letterSpacing: 0.5,
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

  Future<void> _confirmClearData(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will remove all locally stored prayer logs. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(localStorageProvider).clearAll();
      ref.invalidate(prayerLogProvider);
      ref.invalidate(calendarLogsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Local data cleared')),
        );
      }
    }
  }
}
