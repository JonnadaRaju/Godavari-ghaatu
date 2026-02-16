from fastapi import APIRouter, Depends, status, Query
from sqlalchemy.orm import Session
from uuid import UUID
from typing import List

from app.core.database import get_db
from app.core.dependencies import (
    get_current_user,
    require_role,
    CurrentUser,
)
from app.schemas.order import OrderOut, OrderListOut
from app.services.order_service import (
    create_order_from_cart,
    update_order_status,
    get_user_orders,
    get_all_orders,
    get_order_by_id,
)

router = APIRouter(prefix="/orders", tags=["Orders"])


@router.post("", response_model=OrderOut, status_code=status.HTTP_201_CREATED)
def create_order(
    db: Session = Depends(get_db),
    user: CurrentUser = Depends(get_current_user),
):
    return create_order_from_cart(db, user.user_id)


@router.get("", response_model=List[OrderListOut])
def list_orders(
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=200),
    db: Session = Depends(get_db),
    user: CurrentUser = Depends(get_current_user),
):
    # Admin gets ALL orders; regular users get only their own
    if user.role == "admin":
        return get_all_orders(db, skip, limit)
    return get_user_orders(db, user.user_id, skip, limit)


@router.get("/{order_id}", response_model=OrderOut)
def get_order(
    order_id: UUID,
    db: Session = Depends(get_db),
    user: CurrentUser = Depends(get_current_user),
):
    # Admin can view any order; users can only view their own
    user_id = None if user.role == "admin" else user.user_id
    return get_order_by_id(db, order_id, user_id)


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


@router.patch("/{order_id}/pack", response_model=OrderOut)
def pack_order(
    order_id: UUID,
    db: Session = Depends(get_db),
    admin: CurrentUser = Depends(require_role("admin")),
):
    return update_order_status(
        db,
        order_id,
        user_id=None,
        new_status="PACKED",
    )


@router.patch("/{order_id}/ship", response_model=OrderOut)
def ship_order(
    order_id: UUID,
    db: Session = Depends(get_db),
    admin: CurrentUser = Depends(require_role("admin")),
):
    return update_order_status(
        db,
        order_id,
        user_id=None,
        new_status="SHIPPED",
    )


@router.patch("/{order_id}/deliver", response_model=OrderOut)
def deliver_order(
    order_id: UUID,
    db: Session = Depends(get_db),
    admin: CurrentUser = Depends(require_role("admin")),
):
    return update_order_status(
        db,
        order_id,
        user_id=None,
        new_status="DELIVERED",
    )