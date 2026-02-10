from pydantic import BaseModel, Field
from uuid import UUID
from typing import List


class CartItemOut(BaseModel):
    id: UUID
    product_id: UUID
    quantity: int
    unit_price: float
    line_total: float
    
    class Config:
        from_attributes = True
        

class CartOut(BaseModel):
    id: UUID
    items: List[CartItemOut]
    total_amount: float
    
    class Config:
        from_attributes = True
        
class AddCartItemIn(BaseModel):
    product_id: UUID
    quantity: int = Field(..., gt=0, description="Quantity must be greater than 0")
    
class UpdateCartItemIn(BaseModel):
    quantity: int = Field(..., gt=0, description="Quantity must be greater than 0")