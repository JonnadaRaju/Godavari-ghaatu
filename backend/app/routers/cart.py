from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.schemas.cart import CartOut
from app.services.cart_service import (
    get_or_create_cart,
    build_cart_response,
)

router = APIRouter(prefix="/cart", tags=["Cart"])


@router.get("", response_model=CartOut)
def get_cart(db: Session = Depends(get_db)):
    user_id = get_current_user_id()
    cart = get_or_create_cart(db, user_id)
    return build_cart_response(db, cart)
