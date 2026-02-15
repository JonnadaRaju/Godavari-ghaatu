from pydantic import BaseModel, Field
from uuid import UUID
from typing import Optional
from datetime import datetime


class ReviewCreate(BaseModel):
    rating: int = Field(..., ge=1, le=5, description="Rating from 1 to 5")
    comment: Optional[str] = Field(None, max_length=1000)


class ReviewUpdate(BaseModel):
    rating: Optional[int] = Field(None, ge=1, le=5)
    comment: Optional[str] = Field(None, max_length=1000)


class ReviewOut(BaseModel):
    id: UUID
    user_id: UUID
    product_id: UUID
    rating: int
    comment: Optional[str] = None
    reviewer_name: Optional[str] = None    
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class ProductRatingSummary(BaseModel):
    average_rating: float
    review_count: int