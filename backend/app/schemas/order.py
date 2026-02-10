from pydantic import BaseModel
from uuid import UUID
from typing import List
from datetime import datetime

class OrderItemOut(BaseModel):
    id: UUID
    product_id: UUID
    quantity: int
    unit_price: float
    line_total: float

    class Config:
        from_attributes = True

class OrderOut(BaseModel):
    id: UUID
    user_id: UUID
    status: str
    total_amount: float
    items: List[OrderItemOut]
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
        
class OrderListOut(BaseModel):
    id: UUID
    status: str
    total_amount: float
    created_at: datetime
    class Config:
        from_attributes = True
