"""SQLAlchemy ORM models for User and PrayerLog."""

import uuid
from datetime import datetime, date
from sqlalchemy import String, Boolean, Integer, Float, Date, DateTime, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship
from database import Base


def generate_uuid() -> str:
    return str(uuid.uuid4())


class User(Base):
    __tablename__ = "users"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=generate_uuid)
    google_id: Mapped[str] = mapped_column(String(255), unique=True, index=True)
    email: Mapped[str] = mapped_column(String(255), nullable=True)
    display_name: Mapped[str] = mapped_column(String(255), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    performance_start_date: Mapped[date] = mapped_column(Date, nullable=True)

    # Relationships
    prayer_logs: Mapped[list["PrayerLog"]] = relationship(
        "PrayerLog", back_populates="user", cascade="all, delete-orphan"
    )


class PrayerLog(Base):
    __tablename__ = "prayer_logs"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=generate_uuid)
    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id"), index=True)
    date: Mapped[date] = mapped_column(Date, index=True)

    # Fajr
    fajr_fardh: Mapped[bool] = mapped_column(Boolean, default=False)
    fajr_sunnah: Mapped[int] = mapped_column(Integer, default=0)
    fajr_nafl: Mapped[int] = mapped_column(Integer, default=0)

    # Dhuhr
    dhuhr_fardh: Mapped[bool] = mapped_column(Boolean, default=False)
    dhuhr_sunnah: Mapped[int] = mapped_column(Integer, default=0)
    dhuhr_nafl: Mapped[int] = mapped_column(Integer, default=0)

    # Asr
    asr_fardh: Mapped[bool] = mapped_column(Boolean, default=False)
    asr_sunnah: Mapped[int] = mapped_column(Integer, default=0)
    asr_nafl: Mapped[int] = mapped_column(Integer, default=0)

    # Maghrib
    maghrib_fardh: Mapped[bool] = mapped_column(Boolean, default=False)
    maghrib_sunnah: Mapped[int] = mapped_column(Integer, default=0)
    maghrib_nafl: Mapped[int] = mapped_column(Integer, default=0)

    # Isha
    isha_fardh: Mapped[bool] = mapped_column(Boolean, default=False)
    isha_sunnah: Mapped[int] = mapped_column(Integer, default=0)
    isha_nafl: Mapped[int] = mapped_column(Integer, default=0)

    # Computed score
    daily_score: Mapped[float] = mapped_column(Float, default=0.0)

    # Timestamps
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow
    )

    # Relationships
    user: Mapped["User"] = relationship("User", back_populates="prayer_logs")

    # Unique constraint: one log per user per date
    __table_args__ = (
        {"sqlite_autoincrement": False},
    )
