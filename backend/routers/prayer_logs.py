"""Prayer logs router — CRUD operations for daily prayer entries."""

from datetime import date, datetime
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from sqlalchemy import and_
from database import get_db
from models import User, PrayerLog
from schemas import (
    PrayerLogCreate,
    PrayerLogUpdate,
    PrayerLogResponse,
    BatchSyncRequest,
    BatchSyncResponse,
)
from utils.firebase_auth import get_current_user
from utils.scoring import compute_score_from_log

router = APIRouter(prefix="/logs", tags=["Prayer Logs"])


def _upsert_log(db: Session, user: User, data: PrayerLogCreate) -> PrayerLog:
    """Create or update a prayer log for a given date."""
    existing = db.query(PrayerLog).filter(
        and_(PrayerLog.user_id == user.id, PrayerLog.date == data.date)
    ).first()

    log_data = data.model_dump()
    log_data.pop("date")

    if existing:
        # Update existing
        for key, value in log_data.items():
            setattr(existing, key, value)
        existing.updated_at = datetime.utcnow()
        # Recompute score
        existing.daily_score = compute_score_from_log(existing)
        db.commit()
        db.refresh(existing)
        return existing
    else:
        # Create new
        log = PrayerLog(
            user_id=user.id,
            date=data.date,
            **log_data,
        )
        log.daily_score = compute_score_from_log(log)
        db.add(log)
        db.commit()
        db.refresh(log)
        return log


@router.get("/{log_date}", response_model=PrayerLogResponse)
async def get_log(
    log_date: date,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get prayer log for a specific date."""
    log = db.query(PrayerLog).filter(
        and_(PrayerLog.user_id == current_user.id, PrayerLog.date == log_date)
    ).first()

    if not log:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"No prayer log found for {log_date}"
        )
    return log


@router.post("/", response_model=PrayerLogResponse, status_code=status.HTTP_201_CREATED)
async def create_log(
    data: PrayerLogCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Create or upsert a prayer log. If a log exists for the date, it will be overwritten."""
    return _upsert_log(db, current_user, data)


@router.put("/{log_date}", response_model=PrayerLogResponse)
async def update_log(
    log_date: date,
    data: PrayerLogUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Update an existing prayer log for a specific date."""
    # Override the date in data with the URL param
    data.date = log_date
    return _upsert_log(db, current_user, data)


@router.get("/range/", response_model=list[PrayerLogResponse])
async def get_logs_range(
    start: date = Query(..., description="Start date (inclusive)"),
    end: date = Query(..., description="End date (inclusive)"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get all prayer logs within a date range."""
    logs = db.query(PrayerLog).filter(
        and_(
            PrayerLog.user_id == current_user.id,
            PrayerLog.date >= start,
            PrayerLog.date <= end,
        )
    ).order_by(PrayerLog.date).all()

    return logs


@router.post("/sync", response_model=BatchSyncResponse)
async def batch_sync(
    data: BatchSyncRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Batch sync multiple prayer logs (used by mobile app for offline sync)."""
    synced_logs = []
    for log_data in data.logs:
        log = _upsert_log(db, current_user, log_data)
        synced_logs.append(log)

    return BatchSyncResponse(
        synced_count=len(synced_logs),
        logs=synced_logs,
    )
