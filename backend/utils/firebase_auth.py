"""Firebase Authentication utilities.

Verifies Firebase ID tokens and extracts user information.
Falls back to a mock mode for local development without Firebase.
"""

import os
import logging
from typing import Optional
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from database import get_db
from models import User

logger = logging.getLogger(__name__)

security = HTTPBearer(auto_error=False)

# Try to initialize Firebase Admin SDK
_firebase_initialized = False
try:
    import firebase_admin
    from firebase_admin import auth as firebase_auth, credentials

    cred_path = os.getenv("FIREBASE_CREDENTIALS_PATH")
    if cred_path and os.path.exists(cred_path):
        cred = credentials.Certificate(cred_path)
        firebase_admin.initialize_app(cred)
        _firebase_initialized = True
        logger.info("Firebase Admin SDK initialized successfully.")
    else:
        logger.warning(
            "Firebase credentials not found. Running in MOCK auth mode. "
            "Set FIREBASE_CREDENTIALS_PATH to enable real auth."
        )
except Exception as e:
    logger.warning(f"Firebase initialization failed: {e}. Running in MOCK auth mode.")


def verify_firebase_token(id_token: str) -> dict:
    """Verify a Firebase ID token and return decoded claims.

    In mock mode, returns a fake user for development.
    """
    if _firebase_initialized:
        try:
            decoded = firebase_auth.verify_id_token(id_token)
            return {
                "uid": decoded["uid"],
                "email": decoded.get("email"),
                "name": decoded.get("name"),
            }
        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail=f"Invalid Firebase token: {str(e)}"
            )
    else:
        # Mock mode for development
        return {
            "uid": "mock_google_id_12345",
            "email": "dev@salahtracker.test",
            "name": "Dev User",
        }


async def get_current_user(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(security),
    db: Session = Depends(get_db),
) -> User:
    """FastAPI dependency: extract and verify the current user from the Authorization header.

    In mock mode (no Firebase), returns/creates a default dev user.
    """
    if credentials:
        token = credentials.credentials
        user_info = verify_firebase_token(token)
    elif not _firebase_initialized:
        # Mock mode: no token required
        user_info = verify_firebase_token("")
    else:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authorization header required"
        )

    # Find or create user
    user = db.query(User).filter(User.google_id == user_info["uid"]).first()
    if not user:
        user = User(
            google_id=user_info["uid"],
            email=user_info.get("email"),
            display_name=user_info.get("name"),
        )
        db.add(user)
        db.commit()
        db.refresh(user)

    return user
