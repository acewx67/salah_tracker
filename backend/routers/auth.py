"""Authentication router — Google Sign-In via Firebase."""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from database import get_db
from models import User
from schemas import GoogleLoginRequest, UserResponse, UpdatePerformanceStartDate
from utils.firebase_auth import verify_firebase_token, get_current_user

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post("/google-login", response_model=UserResponse)
async def google_login(request: GoogleLoginRequest, db: Session = Depends(get_db)):
    """Verify Firebase ID token and create/return user."""
    user_info = verify_firebase_token(request.id_token)

    # Find existing user
    user = db.query(User).filter(User.google_id == user_info["uid"]).first()

    if not user:
        # Create new user
        user = User(
            google_id=user_info["uid"],
            email=user_info.get("email"),
            display_name=user_info.get("name"),
        )
        db.add(user)
        db.commit()
        db.refresh(user)

    return user


@router.get("/me", response_model=UserResponse)
async def get_me(current_user: User = Depends(get_current_user)):
    """Get current authenticated user."""
    return current_user


@router.put("/performance-start-date", response_model=UserResponse)
async def update_performance_start_date(
    data: UpdatePerformanceStartDate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Update the user's performance tracking start date."""
    current_user.performance_start_date = data.performance_start_date
    db.commit()
    db.refresh(current_user)
    return current_user
