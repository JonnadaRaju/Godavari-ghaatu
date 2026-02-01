from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user, CurrentUser
from app.schemas.cart import CartOut, AddCartItemIn
from app.services.cart_service import (
    get_or_create_cart,
    add_item_to_cart,
    build_cart_response,
)

router = APIRouter(prefix="/cart", tags=["Cart"])


@router.get("", response_model=CartOut)
def get_cart(
    db: Session = Depends(get_db),
    user: CurrentUser = Depends(get_current_user),
):
    cart = get_or_create_cart(db, user.user_id)
    return build_cart_response(db, cart)


@router.post(
    "/items",
    response_model=CartOut,
    status_code=status.HTTP_201_CREATED,
)
def add_cart_item(
    payload: AddCartItemIn,
    db: Session = Depends(get_db),
    user: CurrentUser = Depends(get_current_user),
):
    cart = add_item_to_cart(
        db,
        user_id=user.user_id,
        product_id=payload.product_id,
        quantity=payload.quantity,
    )
    return build_cart_response(db, cart)
