from pydantic import BaseModel
from uuid import UUID
from typing import List


class OrderItemOut(BaseModel):
    product_id: UUID
    quantity: int
    unit_price: float
    line_total: float


class OrderOut(BaseModel):
    id: UUID
    status: str
    total_amount: float
    items: List[OrderItemOut]

    class Config:
        from_attributes = True
