from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel
from uuid import UUID

from app.core.security import create_access_token

router = APIRouter(prefix="/auth", tags=["Auth"])


class LoginRequest(BaseModel):
    user_id: UUID
    role: str  # USER or ADMIN


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"


@router.post("/login", response_model=TokenResponse)
def login(payload: LoginRequest):
    if payload.role not in {"USER", "ADMIN"}:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid role",
        )

    token = create_access_token(
        subject=str(payload.user_id),
        role=payload.role,
    )

    return {"access_token": token}
