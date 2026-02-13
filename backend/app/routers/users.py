from fastapi import APIRouter, HTTPException, status, Depends
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.core.security import hash_password, verify_password
from app.schemas.user import UserOut, UserUpdate, PasswordChange
from app.models.user import User
from app.repositories.user_repository import UserRepository

router = APIRouter(prefix="/users", tags=["Users"])


@router.get("/me", response_model=UserOut)
def get_current_user_profile(
    current_user: User = Depends(get_current_user)
):
    """Get current user's profile."""
    return current_user


@router.put("/me", response_model=UserOut)
def update_profile(
    user_update: UserUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Update current user's profile."""
    user_repo = UserRepository(db)
    
    # Update user fields
    if user_update.full_name is not None:
        current_user.full_name = user_update.full_name
    if user_update.phone is not None:
        current_user.phone = user_update.phone
    
    # Save changes using repository
    updated_user = user_repo.update(current_user)
    return updated_user


@router.post("/me/change-password", status_code=status.HTTP_200_OK)
def change_password(
    password_data: PasswordChange,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Change current user's password."""
    user_repo = UserRepository(db)
    
    # Verify current password
    if not verify_password(password_data.current_password, current_user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Current password is incorrect"
        )
    
    # Update password
    current_user.hashed_password = hash_password(password_data.new_password)
    user_repo.update(current_user)
    
    return {"message": "Password changed successfully"}