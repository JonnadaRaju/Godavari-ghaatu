from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.schemas.cart import CartOut, AddCartItemIn
from app.services.cart_service import (
    add_item_to_cart,
    get_or_create_cart,
)

router = APIRouter(prefix="/cart", tags=["Cart"])


def get_current_user_id():
    # TEMP stub — replace with JWT later
    return "00000000-0000-0000-0000-000000000001"


@router.get("", response_model=CartOut)
def get_cart(db: Session = Depends(get_db)):
    user_id = get_current_user_id()
    cart = get_or_create_cart(db, user_id)
    return cart


@router.post(
    "/items",
    response_model=CartOut,
    status_code=status.HTTP_201_CREATED,
)
def add_cart_item(
    payload: AddCartItemIn,
    db: Session = Depends(get_db),
):
    user_id = get_current_user_id()
    return add_item_to_cart(
        db=db,
        user_id=user_id,
        product_id=payload.product_id,
        quantity=payload.quantity,
    )
