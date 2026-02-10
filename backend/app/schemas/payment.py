from pydantic import BaseModel, Field
from uuid import UUID


class PaymentWebhookIn(BaseModel):
        
    provider: str = Field(..., description="Payment provider name (stripe, paypal, etc)")
    provider_event_id: str = Field(..., description="Unique event ID from provider")
    order_id: UUID = Field(..., description="Order ID being paid")
    amount: float = Field(..., gt=0, description="Payment amount for verification")


class PaymentOut(BaseModel):
    
    id: UUID
    provider: str
    order_id: UUID
    amount: float
    
    class Config:
        from_attributes = True