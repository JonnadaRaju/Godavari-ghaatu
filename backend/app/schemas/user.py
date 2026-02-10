from pydantic import BaseModel, EmailStr, Field
from uuid import UUID
from typing import Optional
from datetime import datetime


class UserBase(BaseModel):
    
    email: EmailStr
    full_name: Optional[str] = None
    phone: Optional[str] = None


class UserCreate(UserBase):
    
    password: str = Field(..., min_length=8, description="Minimum 8 characters")


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
    
    old_password: str
    new_password: str = Field(..., min_length=8, description="Minimum 8 characters")