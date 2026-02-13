from pydantic import BaseModel, EmailStr, Field, field_validator
from uuid import UUID
from typing import Optional
from datetime import datetime

class UserBase(BaseModel):
    
    email: EmailStr
    full_name: Optional[str] = None
    phone: Optional[str] = None

class UserCreate(UserBase):
    """Schema for user registration."""
    
    password: str = Field(..., min_length=8, max_length=72, description="8-72 characters")
    
    @field_validator('password')
    @classmethod
    def validate_password_length(cls, v):
        if len(v.encode('utf-8')) > 72:
            raise ValueError('Password too long (max 72 bytes)')
        return v
    
class UserUpdate(BaseModel):
    
    full_name: Optional[str] = None
    phone: Optional[str] = None


class UserOut(UserBase):
    
    id: UUID
    role: str
    is_active: bool
    created_at: datetime
    
    class Config:
        from_attributes = True


class UserLogin(BaseModel):
    
    email: EmailStr
    password: str


class PasswordChange(BaseModel):
    
    current_password: str
    new_password: str = Field(..., min_length=8, description="Minimum 8 characters")