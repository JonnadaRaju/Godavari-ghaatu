from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from uuid import UUID

from app.core.database import get_db
from app.core.dependencies import get_current_user, CurrentUser
from app.models.review import Review
from app.models.product import Product
from app.schemas.review import ReviewCreate, ReviewOut

router = APIRouter(prefix="/products", tags=["Reviews"])


@router.post("/{product_id}/reviews", response_model=ReviewOut, status_code=status.HTTP_201_CREATED)
def create_review(
    product_id: UUID,
    payload: ReviewCreate,
    db: Session = Depends(get_db),
    user: CurrentUser = Depends(get_current_user),
):
    product = db.query(Product).filter(
        Product.id == product_id,
        Product.is_active == True
    ).first()
    if not product:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product not found")

    existing = db.query(Review).filter(
        Review.user_id == user.user_id,
        Review.product_id == product_id
    ).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="You have already reviewed this product"
        )

    review = Review(
        user_id=user.user_id,
        product_id=product_id,
        rating=payload.rating,
        comment=payload.comment,
    )
    db.add(review)
    db.commit()
    db.refresh(review)

    return ReviewOut(
        id=review.id,
        user_id=review.user_id,
        product_id=review.product_id,
        rating=review.rating,
        comment=review.comment,
        reviewer_name=review.user.full_name if review.user else None,
        created_at=review.created_at,
        updated_at=review.updated_at,
    )