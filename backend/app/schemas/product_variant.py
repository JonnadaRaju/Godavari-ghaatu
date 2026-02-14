from pydantic import BaseModel, Field
from uuid import UUID
from typing import Optional


class ProductVariantCreate(BaseModel):

    label: str = Field(..., min_length=1, max_length=100, description="e.g. '250g', 'Pack of 6'")
    price: float = Field(..., gt=0, description="Must be greater than 0")
    stock_quantity: int = Field(..., ge=0, description="Must be 0 or greater")
    is_active: bool = True


class ProductVariantUpdate(BaseModel):

    label: Optional[str] = Field(None, min_length=1, max_length=100)
    price: Optional[float] = Field(None, gt=0)
    stock_quantity: Optional[int] = Field(None, ge=0)
    is_active: Optional[bool] = None


class ProductVariantOut(BaseModel):
    
    id: UUID
    product_id: UUID
    label: str
    price: float
    stock_quantity: int
    is_active: bool

    class Config:
        from_attributes = True
