from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from uuid import UUID
from typing import List, Optional

from app.core.database import get_db
from app.core.dependencies import require_role, CurrentUser
from app.schemas.product import ProductCreate, ProductUpdate, ProductResponse, ProductListItem
from app.models.product import Product

router = APIRouter(prefix="/products", tags=["Products"])


@router.get("", response_model=List[ProductListItem])
def list_products(
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    active_only: bool = Query(True),
    category: Optional[str] = Query(None, pattern="^(pickle|spice|laddu|combo)$"),
    is_veg: Optional[bool] = Query(None),
    is_bestseller: Optional[bool] = Query(None),
    is_new_arrival: Optional[bool] = Query(None),
    db: Session = Depends(get_db),
):
    query = db.query(Product)

    if active_only:
        query = query.filter(Product.is_active == True)
    if category:
        query = query.filter(Product.category == category)
    if is_veg is not None:
        query = query.filter(Product.is_veg == is_veg)
    if is_bestseller is not None:
        query = query.filter(Product.is_bestseller == is_bestseller)
    if is_new_arrival is not None:
        query = query.filter(Product.is_new_arrival == is_new_arrival)

    products = query.order_by(Product.created_at.desc())\
        .offset(skip)\
        .limit(limit)\
        .all()

    return products


@router.get("/{product_id}", response_model=ProductResponse)
def get_product(
    product_id: UUID,
    db: Session = Depends(get_db),
):
    product = db.query(Product).filter(Product.id == product_id).first()

    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Product not found"
        )

    return product


@router.post("", response_model=ProductResponse, status_code=status.HTTP_201_CREATED)
def create_product(
    product_data: ProductCreate,
    db: Session = Depends(get_db),
    admin: CurrentUser = Depends(require_role("admin")),
):
    product = Product(
        name=product_data.name,
        description=product_data.description,
        price=product_data.price,
        stock_quantity=product_data.stock_quantity,
        image_url=product_data.image_url,
        category=product_data.category,
        is_veg=product_data.is_veg,
        is_bestseller=product_data.is_bestseller,
        is_new_arrival=product_data.is_new_arrival,
        is_active=product_data.is_active,
    )

    db.add(product)
    db.commit()
    db.refresh(product)

    return product


@router.put("/{product_id}", response_model=ProductResponse)
def update_product(
    product_id: UUID,
    product_update: ProductUpdate,
    db: Session = Depends(get_db),
    admin: CurrentUser = Depends(require_role("admin")),
):
    product = db.query(Product).filter(Product.id == product_id).first()

    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Product not found"
        )

    if product_update.name is not None:
        product.name = product_update.name
    if product_update.description is not None:
        product.description = product_update.description
    if product_update.price is not None:
        product.price = product_update.price
    if product_update.stock_quantity is not None:
        product.stock_quantity = product_update.stock_quantity
    if product_update.image_url is not None:
        product.image_url = product_update.image_url
    if product_update.category is not None:
        product.category = product_update.category
    if product_update.is_veg is not None:
        product.is_veg = product_update.is_veg
    if product_update.is_bestseller is not None:
        product.is_bestseller = product_update.is_bestseller
    if product_update.is_new_arrival is not None:
        product.is_new_arrival = product_update.is_new_arrival
    if product_update.is_active is not None:
        product.is_active = product_update.is_active

    db.commit()
    db.refresh(product)

    return product


@router.delete("/{product_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_product(
    product_id: UUID,
    db: Session = Depends(get_db),
    admin: CurrentUser = Depends(require_role("admin")),
):
    product = db.query(Product).filter(Product.id == product_id).first()

    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Product not found"
        )

    product.is_active = False
    db.commit()

    return None