from datetime import datetime, timedelta
from typing import Dict

from jose import jwt, JWTError
from fastapi import HTTPException, status

from app.core.config import settings


def create_access_token(
    subject: str,
    role: str,
) -> str:
    payload: Dict = {
        "sub": subject,
        "role": role,
        "exp": datetime.utcnow()
        + timedelta(minutes=settings.JWT_EXPIRE_MINUTES),
    }

    return jwt.encode(
        payload,
        settings.JWT_SECRET_KEY,
        algorithm=settings.JWT_ALGORITHM,
    )


def decode_access_token(token: str) -> Dict:
    try:
        return jwt.decode(
            token,
            settings.JWT_SECRET_KEY,
            algorithms=[settings.JWT_ALGORITHM],
        )
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
        )
