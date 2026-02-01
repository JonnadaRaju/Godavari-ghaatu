from pydantic import BaseModel, Field
from uuid import UUID
from typing import List


class CartItemOut(BaseModel):
    id: UUID
    product_id: UUID
    quantity: int
    
    class Config:
        from_attributes = True
        

class CartOut(BaseModel):
    id: UUID
    items: List[CartItemOut]
    total_amount: float = Field(..., ge=0)
    
    class config:
        from_attributes = True
        
class AddCartItemIn(BaseModel):
    product_id: UUID
    quantity: int = Field(..., gt=0)