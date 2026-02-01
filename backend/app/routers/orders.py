from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.schemas.order import OrderOut
from app.services.order_service import create_order_from_cart

router = APIRouter(prefix="/orders", tags=["Orders"])


def get_current_user_id():
    return "00000000-0000-0000-0000-000000000001"


@router.post(
    "",
    response_model=OrderOut,
    status_code=status.HTTP_201_CREATED,
)
def create_order(db: Session = Depends(get_db)):
    user_id = get_current_user_id()
    return create_order_from_cart(db, user_id)
