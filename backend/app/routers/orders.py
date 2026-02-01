from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from uuid import UUID

from app.core.database import get_db
from app.core.dependencies import (
    get_current_user,
    require_role,
    CurrentUser,
)
from app.schemas.order import OrderOut
from app.services.order_service import (
    create_order_from_cart,
    update_order_status,
)

router = APIRouter(prefix="/orders", tags=["Orders"])


@router.post("", response_model=OrderOut, status_code=status.HTTP_201_CREATED)
def create_order(
    db: Session = Depends(get_db),
    user: CurrentUser = Depends(get_current_user),
):
    return create_order_from_cart(db, user.user_id)


@router.patch("/{order_id}/cancel", response_model=OrderOut)
def cancel_order(
    order_id: UUID,
    db: Session = Depends(get_db),
    user: CurrentUser = Depends(get_current_user),
):
    return update_order_status(
        db,
        order_id,
        user.user_id,
        "CANCELLED",
    )


@router.patch("/{order_id}/ship", response_model=OrderOut)
def ship_order(
    order_id: UUID,
    db: Session = Depends(get_db),
    admin: CurrentUser = Depends(require_role("ADMIN")),
):
    return update_order_status(
        db,
        order_id,
        user_id=None,
        new_status="SHIPPED",
    )
