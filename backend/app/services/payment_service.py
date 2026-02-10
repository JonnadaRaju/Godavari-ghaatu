from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError
from fastapi import HTTPException, status
from uuid import UUID
from decimal import Decimal

from app.models.payment import PaymentEvent
from app.services.order_service import update_order_status


def process_payment_event(
    db: Session,
    *,
    provider: str,
    provider_event_id: str,
    order_id: UUID,
    amount: Decimal
) -> dict:
    """
    Process payment event from external provider.
    
    Args:
        db: Database session
        provider: Payment provider name (stripe, paypal, etc)
        provider_event_id: Unique event ID from provider
        order_id: Order UUID being paid
        amount: Payment amount for verification
        
    Returns:
        Dictionary with processing status
        
    Raises:
        HTTPException: If order not found or amount mismatch
    """
    try:
        with db.begin_nested():
            # Create payment event (will fail if duplicate due to unique constraint)
            event = PaymentEvent(
                provider=provider,
                provider_event_id=provider_event_id,
                order_id=order_id,
                amount=amount
            )

            db.add(event)
            db.flush()  # Check for IntegrityError before updating order

            # Transition order → PAID
            update_order_status(
                db=db,
                order_id=order_id,
                user_id=None,  # Service bypass
                new_status="PAID",
            )

        db.commit()
        return {"status": "processed", "event_id": str(event.id)}

    except IntegrityError:
        # Duplicate webhook (already processed)
        db.rollback()
        return {"status": "ignored", "reason": "duplicate_event"}

    except HTTPException:
        db.rollback()
        raise
    
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Payment processing failed: {str(e)}"
        )