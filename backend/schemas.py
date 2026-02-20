"""Pydantic schemas for request/response validation."""

from pydantic import BaseModel, Field
from typing import Optional
from datetime import date, datetime


# ─── Auth ───────────────────────────────────────────────────────────────

class GoogleLoginRequest(BaseModel):
    id_token: str


class UserResponse(BaseModel):
    id: str
    google_id: str
    email: Optional[str] = None
    display_name: Optional[str] = None
    performance_start_date: Optional[date] = None
    created_at: datetime

    class Config:
        from_attributes = True


class UpdatePerformanceStartDate(BaseModel):
    performance_start_date: date


# ─── Prayer Logs ────────────────────────────────────────────────────────

class PrayerLogCreate(BaseModel):
    date: date

    fajr_fardh: bool = False
    fajr_sunnah: int = Field(default=0, ge=0)
    fajr_nafl: int = Field(default=0, ge=0)

    dhuhr_fardh: bool = False
    dhuhr_sunnah: int = Field(default=0, ge=0)
    dhuhr_nafl: int = Field(default=0, ge=0)

    asr_fardh: bool = False
    asr_sunnah: int = Field(default=0, ge=0)
    asr_nafl: int = Field(default=0, ge=0)

    maghrib_fardh: bool = False
    maghrib_sunnah: int = Field(default=0, ge=0)
    maghrib_nafl: int = Field(default=0, ge=0)

    isha_fardh: bool = False
    isha_sunnah: int = Field(default=0, ge=0)
    isha_nafl: int = Field(default=0, ge=0)
    isha_witr: int = Field(default=0, ge=0, le=3)


class PrayerLogUpdate(PrayerLogCreate):
    pass


class PrayerLogResponse(BaseModel):
    id: str
    user_id: str
    date: date

    fajr_fardh: bool
    fajr_sunnah: int
    fajr_nafl: int

    dhuhr_fardh: bool
    dhuhr_sunnah: int
    dhuhr_nafl: int

    asr_fardh: bool
    asr_sunnah: int
    asr_nafl: int

    maghrib_fardh: bool
    maghrib_sunnah: int
    maghrib_nafl: int

    isha_fardh: bool
    isha_sunnah: int
    isha_nafl: int
    isha_witr: int

    daily_score: float
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


# ─── Performance ────────────────────────────────────────────────────────

class PerformanceResponse(BaseModel):
    start_date: date
    end_date: date
    total_days: int
    logged_days: int
    average_score: float
    total_fardh_completed: int
    total_possible_fardh: int


# ─── Sync (batch) ───────────────────────────────────────────────────────

class BatchSyncRequest(BaseModel):
    logs: list[PrayerLogCreate]


class BatchSyncResponse(BaseModel):
    synced_count: int
    logs: list[PrayerLogResponse]
