from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session, joinedload
from uuid import UUID
from typing import List

from app.core.database import get_db
from app.core.dependencies import get_current_user, CurrentUser
from app.models.wishlist import Wishlist
from app.models.product import Product
from app.schemas.wishlist import WishlistItemOut, WishlistAddIn

router = APIRouter(prefix="/wishlist", tags=["Wishlist"])


@router.get("", response_model=List[WishlistItemOut])
def get_wishlist(
    db: Session = Depends(get_db),
    user: CurrentUser = Depends(get_current_user),
):
    items = (
        db.query(Wishlist)
        .options(joinedload(Wishlist.product))
        .filter(Wishlist.user_id == user.user_id)
        .order_by(Wishlist.created_at.desc())
        .all()
    )
    return items


@router.post("", response_model=WishlistItemOut, status_code=status.HTTP_201_CREATED)
def add_to_wishlist(
    payload: WishlistAddIn,
    db: Session = Depends(get_db),
    user: CurrentUser = Depends(get_current_user),
):
    product = db.query(Product).filter(
        Product.id == payload.product_id,
        Product.is_active == True
    ).first()
    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Product not found or inactive"
        )

    existing = db.query(Wishlist).filter(
        Wishlist.user_id == user.user_id,
        Wishlist.product_id == payload.product_id
    ).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Product already in wishlist"
        )

    item = Wishlist(user_id=user.user_id, product_id=payload.product_id)
    db.add(item)
    db.commit()

    db.refresh(item)
    item = (
        db.query(Wishlist)
        .options(joinedload(Wishlist.product))
        .filter(Wishlist.id == item.id)
        .first()
    )
    return item


@router.delete("/{product_id}", status_code=status.HTTP_204_NO_CONTENT)
def remove_from_wishlist(
    product_id: UUID,
    db: Session = Depends(get_db),
    user: CurrentUser = Depends(get_current_user),
):
    item = db.query(Wishlist).filter(
        Wishlist.user_id == user.user_id,
        Wishlist.product_id == product_id
    ).first()
    if not item:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Product not in wishlist"
        )

    db.delete(item)
    db.commit()
    return None