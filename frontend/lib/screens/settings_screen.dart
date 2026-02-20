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
    final authState = ref.watch(authProvider);
    final notificationsEnabled = localStorage.notificationsEnabled;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
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
              title: Text(authState.user?.displayName ?? 'Guest User'),
              subtitle: Text(authState.user?.email ?? 'Not signed in'),
            ),
          ),

          const SizedBox(height: 24),

          // ─── Performance Section ─────────────────────────────
          _sectionHeader('Performance'),
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.calendar_today,
                color: AppTheme.primary,
              ),
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
              secondary: const Icon(
                Icons.notifications_outlined,
                color: AppTheme.primary,
              ),
              title: const Text('Daily Reminders'),
              subtitle: const Text(
                '9 PM logging reminder & 5 AM missed prayer alert',
              ),
              value: notificationsEnabled,
              activeThumbColor: AppTheme.primary,
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
                  trailing: authState.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          icon: const Icon(Icons.sync),
                          onPressed: () async {
                            if (authState.user == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please sign in to sync'),
                                ),
                              );
                              return;
                            }
                            try {
                              await ref
                                  .read(authProvider.notifier)
                                  .syncLogs(ref);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Sync successful'),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Sync failed: $e',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.delete_outline,
                    color: Colors.red.shade400,
                  ),
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

          // ─── Logout ──────────────────────────────────────────
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ElevatedButton.icon(
              onPressed: () => _confirmLogout(context, ref),
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade50,
                foregroundColor: Colors.red,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Local data cleared')));
      }
    }
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout?'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authProvider.notifier).signOut();
    }
  }
}
