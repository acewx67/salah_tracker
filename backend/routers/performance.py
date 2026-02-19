"""Performance router — compute weighted prayer performance over a date range."""

from datetime import date
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from sqlalchemy import and_
from database import get_db
from models import User, PrayerLog
from schemas import PerformanceResponse
from utils.firebase_auth import get_current_user

router = APIRouter(prefix="/performance", tags=["Performance"])


@router.get("/", response_model=PerformanceResponse)
async def get_performance(
    start: date = Query(..., description="Start date (inclusive)"),
    end: date = Query(..., description="End date (inclusive)"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Calculate weighted average performance score between start and end dates.

    Score weighting:
      - Fardh (5 per day) = 85% weight
      - Sunnah + Nafl = 15% weight
    """
    logs = db.query(PrayerLog).filter(
        and_(
            PrayerLog.user_id == current_user.id,
            PrayerLog.date >= start,
            PrayerLog.date <= end,
        )
    ).order_by(PrayerLog.date).all()

    total_days = (end - start).days + 1
    logged_days = len(logs)

    if logged_days == 0:
        return PerformanceResponse(
            start_date=start,
            end_date=end,
            total_days=total_days,
            logged_days=0,
            average_score=0.0,
            total_fardh_completed=0,
            total_possible_fardh=total_days * 5,
        )

    # Sum scores and fardh counts
    total_score = sum(log.daily_score for log in logs)
    total_fardh = sum(
        sum([
            log.fajr_fardh, log.dhuhr_fardh, log.asr_fardh,
            log.maghrib_fardh, log.isha_fardh
        ]) for log in logs
    )

    # Average over TOTAL days (including unlogged = 0 score)
    average_score = round(total_score / total_days, 2)

    return PerformanceResponse(
        start_date=start,
        end_date=end,
        total_days=total_days,
        logged_days=logged_days,
        average_score=average_score,
        total_fardh_completed=total_fardh,
        total_possible_fardh=total_days * 5,
    )
