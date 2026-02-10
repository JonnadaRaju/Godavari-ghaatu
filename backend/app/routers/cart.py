from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from uuid import UUID

from app.core.database import get_db
from app.core.dependencies import get_current_user, CurrentUser
from app.schemas.cart import CartOut, AddCartItemIn, UpdateCartItemIn
from app.services.cart_service import (
    get_or_create_cart,
    add_item_to_cart,
    update_cart_item_quantity,
    remove_cart_item,
    clear_cart,
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


@router.put("/items/{item_id}", response_model=CartOut)
def update_cart_item(
    item_id: UUID,
    payload: UpdateCartItemIn,
    db: Session = Depends(get_db),
    user: CurrentUser = Depends(get_current_user),
):
    cart = update_cart_item_quantity(
        db,
        user_id=user.user_id,
        cart_item_id=item_id,
        quantity=payload.quantity,
    )
    return build_cart_response(db, cart)


@router.delete("/items/{item_id}", response_model=CartOut)
def delete_cart_item(
    item_id: UUID,
    db: Session = Depends(get_db),
    user: CurrentUser = Depends(get_current_user),
):
    cart = remove_cart_item(
        db,
        user_id=user.user_id,
        cart_item_id=item_id,
    )
    return build_cart_response(db, cart)


@router.delete("", status_code=status.HTTP_204_NO_CONTENT)
def clear_cart_items(
    db: Session = Depends(get_db),
    user: CurrentUser = Depends(get_current_user),
):
    clear_cart(db, user.user_id)
    return None