from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import require_role
from app.schemas.payment import PaymentWebhookIn
from app.services.payment_service import process_payment_event

router = APIRouter(prefix="/payments", tags=["Payments"])


@router.post(
    "/webhook",
    status_code=status.HTTP_200_OK,
    dependencies=[Depends(require_role("service"))],
)
def payment_webhook(
    payload: PaymentWebhookIn,
    db: Session = Depends(get_db),
):
   
    return process_payment_event(
        db,
        provider=payload.provider,
        provider_event_id=payload.provider_event_id,
        order_id=payload.order_id,
        amount=payload.amount,
    )