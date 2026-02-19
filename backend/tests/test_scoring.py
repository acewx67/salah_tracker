"""Tests for the scoring utility."""

import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from utils.scoring import compute_daily_score, TOTAL_EXPECTED_SUNNAH


def test_all_fardh_no_sunnah():
    """All 5 fardh completed, no sunnah → 85/100."""
    score = compute_daily_score(
        fajr_fardh=True, fajr_sunnah=0, fajr_nafl=0,
        dhuhr_fardh=True, dhuhr_sunnah=0, dhuhr_nafl=0,
        asr_fardh=True, asr_sunnah=0, asr_nafl=0,
        maghrib_fardh=True, maghrib_sunnah=0, maghrib_nafl=0,
        isha_fardh=True, isha_sunnah=0, isha_nafl=0,
    )
    assert score == 85.0


def test_all_fardh_all_sunnah():
    """All fardh + all expected sunnah → 100/100."""
    score = compute_daily_score(
        fajr_fardh=True, fajr_sunnah=2, fajr_nafl=0,
        dhuhr_fardh=True, dhuhr_sunnah=6, dhuhr_nafl=0,
        asr_fardh=True, asr_sunnah=0, asr_nafl=0,
        maghrib_fardh=True, maghrib_sunnah=2, maghrib_nafl=0,
        isha_fardh=True, isha_sunnah=4, isha_nafl=0,
    )
    assert score == 100.0


def test_no_prayers():
    """Nothing prayed → 0/100."""
    score = compute_daily_score(
        fajr_fardh=False, fajr_sunnah=0, fajr_nafl=0,
        dhuhr_fardh=False, dhuhr_sunnah=0, dhuhr_nafl=0,
        asr_fardh=False, asr_sunnah=0, asr_nafl=0,
        maghrib_fardh=False, maghrib_sunnah=0, maghrib_nafl=0,
        isha_fardh=False, isha_sunnah=0, isha_nafl=0,
    )
    assert score == 0.0


def test_partial_fardh():
    """3 out of 5 fardh → (3/5)*85 = 51.0."""
    score = compute_daily_score(
        fajr_fardh=True, fajr_sunnah=0, fajr_nafl=0,
        dhuhr_fardh=True, dhuhr_sunnah=0, dhuhr_nafl=0,
        asr_fardh=True, asr_sunnah=0, asr_nafl=0,
        maghrib_fardh=False, maghrib_sunnah=0, maghrib_nafl=0,
        isha_fardh=False, isha_sunnah=0, isha_nafl=0,
    )
    assert score == 51.0


def test_sunnah_capped_at_15():
    """Excess sunnah should be capped at 15 points."""
    score = compute_daily_score(
        fajr_fardh=True, fajr_sunnah=12, fajr_nafl=12,
        dhuhr_fardh=True, dhuhr_sunnah=12, dhuhr_nafl=12,
        asr_fardh=True, asr_sunnah=12, asr_nafl=12,
        maghrib_fardh=True, maghrib_sunnah=12, maghrib_nafl=12,
        isha_fardh=True, isha_sunnah=12, isha_nafl=12,
    )
    assert score == 100.0  # 85 + 15 capped


def test_nafl_contributes():
    """Nafl adds to the sunnah score bucket."""
    # All fardh + only nafl (no sunnah) = partial sunnah score
    score = compute_daily_score(
        fajr_fardh=True, fajr_sunnah=0, fajr_nafl=2,
        dhuhr_fardh=True, dhuhr_sunnah=0, dhuhr_nafl=6,
        asr_fardh=True, asr_sunnah=0, asr_nafl=0,
        maghrib_fardh=True, maghrib_sunnah=0, maghrib_nafl=2,
        isha_fardh=True, isha_sunnah=0, isha_nafl=4,
    )
    # Nafl total = 14, expected sunnah = 14, so (14/14)*15 = 15
    assert score == 100.0


def test_expected_sunnah_total():
    """Verify expected sunnah total is 14."""
    assert TOTAL_EXPECTED_SUNNAH == 14
