"""Scoring logic for prayer performance.

Weighting:
  - Fardh prayers = 85% of daily score
  - Sunnah + Nafl = 15% of daily score

Daily Score = (fardh_completed / 5) * 85 + min((sunnah_prayed / expected_sunnah) * 15, 15)
"""

# Expected Sunnah rakats per prayer (typical recommendation)
EXPECTED_SUNNAH = {
    "fajr": 2,
    "dhuhr": 6,   # 4 before + 2 after
    "asr": 0,     # Optional
    "maghrib": 2,
    "isha": 4,    # 2 + 2
}

TOTAL_EXPECTED_SUNNAH = sum(EXPECTED_SUNNAH.values())  # 14

FARDH_WEIGHT = 85.0
SUNNAH_WEIGHT = 15.0


def compute_daily_score(
    fajr_fardh: bool,
    fajr_sunnah: int,
    fajr_nafl: int,
    dhuhr_fardh: bool,
    dhuhr_sunnah: int,
    dhuhr_nafl: int,
    asr_fardh: bool,
    asr_sunnah: int,
    asr_nafl: int,
    maghrib_fardh: bool,
    maghrib_sunnah: int,
    maghrib_nafl: int,
    isha_fardh: bool,
    isha_sunnah: int,
    isha_nafl: int,
) -> float:
    """Compute the weighted daily score (0–100).

    Fardh completed count drives 85% of the score.
    Sunnah + Nafl rakats (capped) drive the remaining 15%.
    """
    # Count fardh completed
    fardh_completed = sum([
        fajr_fardh, dhuhr_fardh, asr_fardh, maghrib_fardh, isha_fardh
    ])
    fardh_score = (fardh_completed / 5) * FARDH_WEIGHT

    # Sum sunnah rakats prayed
    total_sunnah = (
        fajr_sunnah + dhuhr_sunnah + asr_sunnah +
        maghrib_sunnah + isha_sunnah
    )

    # Sum nafl rakats prayed (nafl contributes to sunnah weight bucket)
    total_nafl = (
        fajr_nafl + dhuhr_nafl + asr_nafl +
        maghrib_nafl + isha_nafl
    )

    # Sunnah score: (total sunnah + nafl prayed / expected sunnah) * 15, capped at 15
    if TOTAL_EXPECTED_SUNNAH > 0:
        sunnah_score = min(
            ((total_sunnah + total_nafl) / TOTAL_EXPECTED_SUNNAH) * SUNNAH_WEIGHT,
            SUNNAH_WEIGHT
        )
    else:
        sunnah_score = 0.0

    daily_score = round(fardh_score + sunnah_score, 2)
    return min(daily_score, 100.0)


def compute_score_from_log(log) -> float:
    """Compute score from a PrayerLog ORM object or dict."""
    if hasattr(log, "__dict__"):
        # ORM object
        return compute_daily_score(
            fajr_fardh=log.fajr_fardh,
            fajr_sunnah=log.fajr_sunnah,
            fajr_nafl=log.fajr_nafl,
            dhuhr_fardh=log.dhuhr_fardh,
            dhuhr_sunnah=log.dhuhr_sunnah,
            dhuhr_nafl=log.dhuhr_nafl,
            asr_fardh=log.asr_fardh,
            asr_sunnah=log.asr_sunnah,
            asr_nafl=log.asr_nafl,
            maghrib_fardh=log.maghrib_fardh,
            maghrib_sunnah=log.maghrib_sunnah,
            maghrib_nafl=log.maghrib_nafl,
            isha_fardh=log.isha_fardh,
            isha_sunnah=log.isha_sunnah,
            isha_nafl=log.isha_nafl,
        )
    else:
        # Dict-like
        return compute_daily_score(**log)
