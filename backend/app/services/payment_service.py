from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError
from fastapi import HTTPException, status

from app.models.payment import PaymentEvent
from app.services.order_service import update_order_status


def process_payment_event(
    db: Session,
    *,
    provider: str,
    provider_event_id: str,
    order_id,
):
    try:
        with db.begin():

            event = PaymentEvent(
                provider=provider,
                provider_event_id=provider_event_id,
                order_id=order_id,
            )

            db.add(event)

            # 🔁 Transition order → PAID
            update_order_status(
                db=db,
                order_id=order_id,
                user_id=None,          # service bypass
                new_status="PAID",
            )

    except IntegrityError:
        # 🔁 Duplicate webhook (already processed)
        db.rollback()
        return {"status": "ignored"}

    except HTTPException:
        db.rollback()
        raise

    return {"status": "processed"}
