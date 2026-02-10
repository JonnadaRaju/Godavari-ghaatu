from pydantic import BaseModel, Field
from uuid import UUID
from typing import Optional
from datetime import datetime


class ProductBase(BaseModel):
    
    name: str = Field(..., min_length=1, max_length=255)
    description: Optional[str] = None
    price: float = Field(..., gt=0, description="Must be greater than 0")
    stock_quantity: int = Field(..., ge=0, description="Must be 0 or greater")
    is_active: bool = True


class ProductCreate(ProductBase):
    pass


class ProductUpdate(BaseModel):
    
    name: Optional[str] = Field(None, min_length=1, max_length=255)
    description: Optional[str] = None
    price: Optional[float] = Field(None, gt=0)
    stock_quantity: Optional[int] = Field(None, ge=0)
    is_active: Optional[bool] = None


class ProductOut(ProductBase):
    
    id: UUID
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True


class ProductListOut(BaseModel):
    
    id: UUID
    name: str
    price: float
    stock_quantity: int
    is_active: bool
    
    class Config:
        from_attributes = True