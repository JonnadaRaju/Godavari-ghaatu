from pydantic import BaseModel
from uuid import UUID
from datetime import datetime
from typing import Optional

from app.schemas.product import ProductListItem


class WishlistItemOut(BaseModel):
    id: UUID
    product_id: UUID
    created_at: datetime
    product: ProductListItem     

    class Config:
        from_attributes = True


class WishlistAddIn(BaseModel):
    product_id: UUID