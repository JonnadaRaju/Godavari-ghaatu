from fastapi import APIRouter, HTTPException, status, Depends
from sqlalchemy.orm import Session
from pydantic import BaseModel

from app.core.database import get_db
from app.core.security import create_access_token, hash_password, verify_password
from app.schemas.user import UserCreate, UserLogin, UserOut
from app.models.user import User
from app.repositories.user_repository import UserRepository

router = APIRouter(prefix="/auth", tags=["Authentication"])


class TokenResponse(BaseModel):
    """Response schema for login endpoint."""
    access_token: str
    token_type: str = "bearer"


@router.post("/register", response_model=UserOut, status_code=status.HTTP_201_CREATED)
def register(
    user_data: UserCreate,
    db: Session = Depends(get_db)
):
    """Register a new user."""
    user_repo = UserRepository(db)
    
    # Check if email already exists
    existing_user = user_repo.get_by_email(user_data.email)
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Email already registered"
        )
    
    # Create new user
    user = User(
        email=user_data.email,
        hashed_password=hash_password(user_data.password),
        full_name=user_data.full_name,
        phone=user_data.phone,
        role="customer",
        is_active=True
    )
    
    created_user = user_repo.create(user)
    return created_user


@router.post("/login", response_model=TokenResponse)
def login(
    credentials: UserLogin,
    db: Session = Depends(get_db)
):
    """Login and get access token."""
    user_repo = UserRepository(db)
    
    # Get user by email
    user = user_repo.get_by_email(credentials.email)
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Verify password
    if not verify_password(credentials.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Check if user is active
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Account is inactive"
        )
    
    # Create access token
    token = create_access_token(subject=str(user.id), role=user.role) 
       
    return {"access_token": token, "token_type": "bearer"}