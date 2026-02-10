from pydantic import BaseModel
from uuid import UUID


class PaymentWebhookIn(BaseModel):
    provider: str
    provider_event_id: str
    order_id: UUID
