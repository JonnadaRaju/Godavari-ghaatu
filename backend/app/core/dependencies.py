from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from uuid import UUID

from app.core.security import decode_access_token
from app.core.database import get_db
from app.models.user import User
from sqlalchemy.orm import Session

security = HTTPBearer()


class CurrentUser:
    def __init__(self, user_id: UUID, role: str):
        self.user_id = user_id
        self.role = role


def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security),) -> CurrentUser:
    payload = decode_access_token(credentials.credentials)

    return CurrentUser(user_id=UUID(payload["sub"]), role=payload["role"],)


def get_current_user_with_db(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: Session = Depends(get_db)
) -> User:
    payload = decode_access_token(credentials.credentials)
    user_id = UUID(payload["sub"])
    
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    return user


def require_role(*allowed_roles: str):
    def checker(user: CurrentUser = Depends(get_current_user)):
        if user.role not in allowed_roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Insufficient permissions",
            )
        return user

    return checker
