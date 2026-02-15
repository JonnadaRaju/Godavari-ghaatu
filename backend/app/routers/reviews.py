from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import func
from uuid import UUID
from typing import List


from app.core.database import get_db
from app.core.dependencies import get_current_user, CurrentUser
from app.models.review import Review
from app.models.product import Product
from app.schemas.review import ReviewCreate, ReviewOut, ReviewUpdate, ProductRatingSummary

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
    
@router.get("/{product_id}/reviews", response_model=List[ReviewOut])
def list_reviews(
    product_id: UUID,
    db: Session = Depends(get_db),
):
    product = db.query(Product).filter(Product.id == product_id).first()
    if not product:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product not found")

    reviews = db.query(Review).filter(
        Review.product_id == product_id
    ).order_by(Review.created_at.desc()).all()

    result = []
    for r in reviews:
        item = ReviewOut(
            id=r.id,
            user_id=r.user_id,
            product_id=r.product_id,
            rating=r.rating,
            comment=r.comment,
            reviewer_name=r.user.full_name if r.user else None,
            created_at=r.created_at,
            updated_at=r.updated_at,
        )
        result.append(item)
    return result


@router.get("/{product_id}/reviews/summary", response_model=ProductRatingSummary)
def get_rating_summary(
    product_id: UUID,
    db: Session = Depends(get_db),
):
    product = db.query(Product).filter(Product.id == product_id).first()
    if not product:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product not found")

    result = db.query(
        func.avg(Review.rating).label("average_rating"),
        func.count(Review.id).label("review_count")
    ).filter(Review.product_id == product_id).first()

    return ProductRatingSummary(
        average_rating=round(float(result.average_rating), 1) if result.average_rating else 0.0,
        review_count=result.review_count or 0,
    )
    
@router.put("/{product_id}/reviews/{review_id}", response_model=ReviewOut)
def update_review(
    product_id: UUID,
    review_id: UUID,
    payload: ReviewUpdate,
    db: Session = Depends(get_db),
    user: CurrentUser = Depends(get_current_user),
):
    """Update your own review."""
    review = db.query(Review).filter(
        Review.id == review_id,
        Review.product_id == product_id,
        Review.user_id == user.user_id,
    ).first()
    if not review:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Review not found")

    if payload.rating is not None:
        review.rating = payload.rating
    if payload.comment is not None:
        review.comment = payload.comment

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