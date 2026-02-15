from pydantic import BaseModel, Field
from typing import Optional
from uuid import UUID
from datetime import datetime


class ProductBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=255)
    description: Optional[str] = None
    price: float = Field(..., gt=0, description="Must be greater than 0")
    stock_quantity: int = Field(..., ge=0, description="Must be 0 or greater")
    
    image_url: Optional[str] = Field(None, max_length=500, description="Product image URL")
    category: str = Field(
        ..., 
        description="Product category",
        pattern="^(pickle|spice|laddu|combo)$"
    )
    is_veg: bool = Field(default=True, description="True for vegetarian products")
    is_bestseller: bool = Field(default=False, description="Featured on homepage")
    is_new_arrival: bool = Field(default=False, description="New product badge")
    
    is_active: bool = True


class ProductCreate(ProductBase):
    pass


class ProductUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=255)
    description: Optional[str] = None
    price: Optional[float] = Field(None, gt=0)
    stock_quantity: Optional[int] = Field(None, ge=0)
    
    image_url: Optional[str] = Field(None, max_length=500)
    category: Optional[str] = Field(None, pattern="^(pickle|spice|laddu|combo)$")
    is_veg: Optional[bool] = None
    is_bestseller: Optional[bool] = None
    is_new_arrival: Optional[bool] = None
    
    is_active: Optional[bool] = None


class ProductResponse(ProductBase):
    id: UUID
    created_at: datetime
    updated_at: datetime
    average_rating: Optional[float] = None
    review_count: int = 0
    
    class Config:
        from_attributes = True


class ProductListItem(BaseModel):
    id: UUID
    name: str
    price: float
    image_url: Optional[str]
    category: str
    is_veg: bool
    is_bestseller: bool
    is_new_arrival: bool
    is_active: bool
    average_rating: Optional[float] = None
    review_count: int = 0
    
    class Config:
        from_attributes = True