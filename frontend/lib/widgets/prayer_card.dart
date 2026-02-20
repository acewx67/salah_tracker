import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salah_tracker/config/theme.dart';
import 'package:salah_tracker/config/constants.dart';
import 'package:salah_tracker/providers/providers.dart';
import 'package:salah_tracker/widgets/rakat_selector.dart';

/// A prayer card with Fardh toggle + Sunnah/Nafl scroll selectors.
class PrayerCard extends ConsumerWidget {
  final String prayerKey;
  final String prayerName;

  const PrayerCard({
    super.key,
    required this.prayerKey,
    required this.prayerName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final log = ref.watch(prayerLogProvider);
    final notifier = ref.read(prayerLogProvider.notifier);

    final isFardhDone = log.getFardh(prayerKey);
    final sunnahValue = log.getSunnah(prayerKey);
    final naflValue = log.getNafl(prayerKey);
    final fardhRakats = PrayerConstants.fardhRakats[prayerKey] ?? 0;

    // Per-prayer option lists
    final sunnahOpts = PrayerConstants.sunnahOptions[prayerKey] ?? [0, 2];
    final naflOpts = PrayerConstants.naflOptions[prayerKey] ?? [0];
    final hasNafl = PrayerConstants.showNafl(prayerKey);
    final witrValue = log.getWitr(prayerKey);
    final hasWitr = prayerKey == 'isha';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Prayer header ─────────────────────────────────
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isFardhDone
                        ? AppTheme.primary.withOpacity(0.1)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isFardhDone
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: isFardhDone ? AppTheme.primary : Colors.grey,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prayerName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        '$fardhRakats Fardh Rakats',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ─── Fardh toggle ──────────────────────────────────
            GestureDetector(
              onTap: () => notifier.toggleFardh(prayerKey),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: isFardhDone ? AppTheme.primary : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isFardhDone
                      ? [
                          BoxShadow(
                            color: AppTheme.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isFardhDone ? Icons.check_rounded : Icons.circle_outlined,
                      color: isFardhDone ? Colors.white : Colors.grey.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isFardhDone ? 'Fardh Completed ✓' : 'Tap to Mark Fardh',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isFardhDone
                            ? Colors.white
                            : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ─── Sunnah selector ───────────────────────────────
            RakatSelector(
              label: 'Sunnah Rakats',
              selectedValue: sunnahValue,
              options: sunnahOpts,
              onChanged: (val) => notifier.setSunnah(prayerKey, val),
            ),

            // ─── Nafl selector (hidden for Fajr & Asr) ─────────
            if (hasNafl) ...[
              const SizedBox(height: 12),
              RakatSelector(
                label: 'Nafl Rakats',
                selectedValue: naflValue,
                options: naflOpts,
                onChanged: (val) => notifier.setNafl(prayerKey, val),
              ),
            ],

            // ─── Witr selector (Isha only) ──────────────────────
            if (hasWitr) ...[
              const SizedBox(height: 12),
              RakatSelector(
                label: 'Witr Rakats',
                selectedValue: witrValue,
                options: PrayerConstants.witrOptions,
                onChanged: (val) => notifier.setWitr(prayerKey, val),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
